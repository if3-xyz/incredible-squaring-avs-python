// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.27;

import {BLSSignatureChecker} from "../../src/BLSSignatureChecker.sol";
import {MockAVSDeployer} from "../utils/MockAVSDeployer.sol";
import {BN254} from "../../src/libraries/BN254.sol";
import {OperatorStateRetriever} from "../../src/OperatorStateRetriever.sol";
import {BitmapUtils} from "../../src/libraries/BitmapUtils.sol";

contract BLSMockAVSDeployer is MockAVSDeployer {
    using BN254 for BN254.G1Point;

    bytes32 msgHash = keccak256(abi.encodePacked("hello world"));
    uint256 aggSignerPrivKey = 69;
    BN254.G2Point aggSignerApkG2;
    BN254.G2Point oneHundredQuorumApkG2;
    BN254.G1Point sigma;

    function _setUpBLSMockAVSDeployer() public virtual {
        _deployMockEigenLayerAndAVS();
        _setAggregatePublicKeysAndSignature();
    }

    function _setUpBLSMockAVSDeployer(
        uint8 numQuorumsToAdd
    ) public virtual {
        _deployMockEigenLayerAndAVS(numQuorumsToAdd);
        _setAggregatePublicKeysAndSignature();
    }

    function _setAggregatePublicKeysAndSignature() internal {
        // aggSignerPrivKey*g2
        aggSignerApkG2.X[1] =
            19101821850089705274637533855249918363070101489527618151493230256975900223847;
        aggSignerApkG2.X[0] =
            5334410886741819556325359147377682006012228123419628681352847439302316235957;
        aggSignerApkG2.Y[1] =
            354176189041917478648604979334478067325821134838555150300539079146482658331;
        aggSignerApkG2.Y[0] =
            4185483097059047421902184823581361466320657066600218863748375739772335928910;

        // 100*aggSignerPrivKey*g2
        oneHundredQuorumApkG2.X[1] =
            6187649255575786743153792867265230878737103598736372524337965086852090105771;
        oneHundredQuorumApkG2.X[0] =
            5334877400925935887383922877430837542135722474116902175395820705628447222839;
        oneHundredQuorumApkG2.Y[1] =
            4668116328019846503695710811760363536142902258271850958815598072072236299223;
        oneHundredQuorumApkG2.Y[0] =
            21446056442597180561077194011672151329458819211586246807143487001691968661015;

        sigma = BN254.hashToG1(msgHash).scalar_mul(aggSignerPrivKey);
    }

    function _generateSignerAndNonSignerPrivateKeys(
        uint256 pseudoRandomNumber,
        uint256 numSigners,
        uint256 numNonSigners
    ) internal view returns (uint256[] memory, uint256[] memory) {
        uint256[] memory signerPrivateKeys = new uint256[](numSigners);
        // generate numSigners numbers that add up to aggSignerPrivKey mod BN254.FR_MODULUS
        uint256 sum = 0;
        for (uint256 i = 0; i < numSigners - 1; i++) {
            signerPrivateKeys[i] = uint256(
                keccak256(abi.encodePacked("signerPrivateKey", pseudoRandomNumber, i))
            ) % BN254.FR_MODULUS;
            sum = addmod(sum, signerPrivateKeys[i], BN254.FR_MODULUS);
        }
        // signer private keys need to add to aggSignerPrivKey
        signerPrivateKeys[numSigners - 1] =
            addmod(aggSignerPrivKey, BN254.FR_MODULUS - sum % BN254.FR_MODULUS, BN254.FR_MODULUS);

        uint256[] memory nonSignerPrivateKeys = new uint256[](numNonSigners);
        for (uint256 i = 0; i < numNonSigners; i++) {
            nonSignerPrivateKeys[i] = uint256(
                keccak256(abi.encodePacked("nonSignerPrivateKey", pseudoRandomNumber, i))
            ) % BN254.FR_MODULUS;
        }

        // Sort nonSignerPrivateKeys in order of ascending pubkeyHash
        // Uses insertion sort to sort array in place
        for (uint256 i = 1; i < nonSignerPrivateKeys.length; i++) {
            uint256 privateKey = nonSignerPrivateKeys[i];
            bytes32 pubkeyHash = _toPubkeyHash(privateKey);
            uint256 j = i;

            // Move elements of nonSignerPrivateKeys[0..i-1] that are greater than the current key
            // to one position ahead of their current position
            while (j > 0 && _toPubkeyHash(nonSignerPrivateKeys[j - 1]) > pubkeyHash) {
                nonSignerPrivateKeys[j] = nonSignerPrivateKeys[j - 1];
                j--;
            }
            nonSignerPrivateKeys[j] = privateKey;
        }

        return (signerPrivateKeys, nonSignerPrivateKeys);
    }

    function _registerSignatoriesAndGetNonSignerStakeAndSignatureRandom(
        uint256 pseudoRandomNumber,
        uint256 numNonSigners,
        uint256 quorumBitmap
    ) internal returns (uint32, BLSSignatureChecker.NonSignerStakesAndSignature memory) {
        (uint256[] memory signerPrivateKeys, uint256[] memory nonSignerPrivateKeys) =
        _generateSignerAndNonSignerPrivateKeys(
            pseudoRandomNumber, maxOperatorsToRegister - numNonSigners, numNonSigners
        );
        bytes memory quorumNumbers = BitmapUtils.bitmapToBytesArray(quorumBitmap);

        // randomly combine signer and non-signer private keys
        uint256[] memory privateKeys = new uint256[](maxOperatorsToRegister);
        // generate addresses and public keys
        address[] memory operators = new address[](maxOperatorsToRegister);
        BN254.G1Point[] memory pubkeys = new BN254.G1Point[](maxOperatorsToRegister);
        BLSSignatureChecker.NonSignerStakesAndSignature memory nonSignerStakesAndSignature;
        nonSignerStakesAndSignature.quorumApks = new BN254.G1Point[](quorumNumbers.length);
        nonSignerStakesAndSignature.nonSignerPubkeys = new BN254.G1Point[](numNonSigners);
        bytes32[] memory nonSignerOperatorIds = new bytes32[](numNonSigners);
        {
            uint256 signerIndex = 0;
            uint256 nonSignerIndex = 0;
            for (uint256 i = 0; i < maxOperatorsToRegister; i++) {
                uint256 randomSeed = uint256(keccak256(abi.encodePacked("privKeyCombination", i)));
                if (randomSeed % 2 == 0 && signerIndex < signerPrivateKeys.length) {
                    privateKeys[i] = signerPrivateKeys[signerIndex];
                    signerIndex++;
                } else if (nonSignerIndex < nonSignerPrivateKeys.length) {
                    privateKeys[i] = nonSignerPrivateKeys[nonSignerIndex];
                    nonSignerStakesAndSignature.nonSignerPubkeys[nonSignerIndex] =
                        BN254.generatorG1().scalar_mul(privateKeys[i]);
                    nonSignerOperatorIds[nonSignerIndex] =
                        nonSignerStakesAndSignature.nonSignerPubkeys[nonSignerIndex].hashG1Point();
                    nonSignerIndex++;
                } else {
                    privateKeys[i] = signerPrivateKeys[signerIndex];
                    signerIndex++;
                }

                operators[i] = _incrementAddress(defaultOperator, i);
                pubkeys[i] = BN254.generatorG1().scalar_mul(privateKeys[i]);

                // add the public key to each quorum
                for (uint256 j = 0; j < nonSignerStakesAndSignature.quorumApks.length; j++) {
                    nonSignerStakesAndSignature.quorumApks[j] =
                        nonSignerStakesAndSignature.quorumApks[j].plus(pubkeys[i]);
                }
            }
        }

        // register all operators for the first quorum
        for (uint256 i = 0; i < maxOperatorsToRegister; i++) {
            cheats.roll(registrationBlockNumber + blocksBetweenRegistrations * i);
            _registerOperatorWithCoordinator(operators[i], quorumBitmap, pubkeys[i], defaultStake);
        }

        uint32 referenceBlockNumber = registrationBlockNumber
            + blocksBetweenRegistrations * uint32(maxOperatorsToRegister) + 1;
        cheats.roll(referenceBlockNumber + 100);

        OperatorStateRetriever.CheckSignaturesIndices memory checkSignaturesIndices =
        operatorStateRetriever.getCheckSignaturesIndices(
            registryCoordinator, referenceBlockNumber, quorumNumbers, nonSignerOperatorIds
        );

        nonSignerStakesAndSignature.nonSignerQuorumBitmapIndices =
            checkSignaturesIndices.nonSignerQuorumBitmapIndices;
        nonSignerStakesAndSignature.apkG2 = aggSignerApkG2;
        nonSignerStakesAndSignature.sigma = sigma;
        nonSignerStakesAndSignature.quorumApkIndices = checkSignaturesIndices.quorumApkIndices;
        nonSignerStakesAndSignature.totalStakeIndices = checkSignaturesIndices.totalStakeIndices;
        nonSignerStakesAndSignature.nonSignerStakeIndices =
            checkSignaturesIndices.nonSignerStakeIndices;

        return (referenceBlockNumber, nonSignerStakesAndSignature);
    }

    function _toPubkeyHash(
        uint256 privKey
    ) internal view returns (bytes32) {
        return BN254.generatorG1().scalar_mul(privKey).hashG1Point();
    }
}
