// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.27;

import "../../src/libraries/BN254.sol";
import "forge-std/Test.sol";
import "forge-std/StdJson.sol";

contract ProofParsing is Test {
    string internal proofConfigJson;
    string prefix;

    bytes32[18] blockHeaderProof;
    bytes32[3] slotProof;
    bytes32[9] withdrawalProof;
    bytes32[46] validatorProof;
    bytes32[44] historicalSummaryProof;

    bytes32[7] executionPayloadProof;
    bytes32[4] timestampProofs;

    bytes32 slotRoot;
    bytes32 executionPayloadRoot;

    function setJSON(
        string memory path
    ) public {
        proofConfigJson = vm.readFile(path);
    }

    function getSlot() public view returns (uint256) {
        return stdJson.readUint(proofConfigJson, ".slot");
    }

    function getValidatorIndex() public view returns (uint256) {
        return stdJson.readUint(proofConfigJson, ".validatorIndex");
    }

    function getValidatorPubkeyHash() public view returns (bytes32) {
        return stdJson.readBytes32(proofConfigJson, ".ValidatorFields[0]");
    }

    function getWithdrawalIndex() public view returns (uint256) {
        return stdJson.readUint(proofConfigJson, ".withdrawalIndex");
    }

    function getBlockRootIndex() public view returns (uint256) {
        return stdJson.readUint(proofConfigJson, ".blockHeaderRootIndex");
    }

    function getHistoricalSummaryIndex() public view returns (uint256) {
        return stdJson.readUint(proofConfigJson, ".historicalSummaryIndex");
    }

    function getBeaconStateRoot() public view returns (bytes32) {
        return stdJson.readBytes32(proofConfigJson, ".beaconStateRoot");
    }

    function getBlockRoot() public view returns (bytes32) {
        return stdJson.readBytes32(proofConfigJson, ".blockHeaderRoot");
    }

    function getSlotRoot() public view returns (bytes32) {
        return stdJson.readBytes32(proofConfigJson, ".slotRoot");
    }

    function getBalanceRoot() public view returns (bytes32) {
        return stdJson.readBytes32(proofConfigJson, ".balanceRoot");
    }

    function getTimestampRoot() public view returns (bytes32) {
        return stdJson.readBytes32(proofConfigJson, ".timestampRoot");
    }

    function getExecutionPayloadRoot() public view returns (bytes32) {
        return stdJson.readBytes32(proofConfigJson, ".executionPayloadRoot");
    }

    function getLatestBlockRoot() public view returns (bytes32) {
        return stdJson.readBytes32(proofConfigJson, ".latestBlockHeaderRoot");
    }

    function getExecutionPayloadProof() public returns (bytes32[7] memory) {
        for (uint256 i = 0; i < 7; i++) {
            prefix = string.concat(".ExecutionPayloadProof[", string.concat(vm.toString(i), "]"));
            executionPayloadProof[i] = (stdJson.readBytes32(proofConfigJson, prefix));
        }
        return executionPayloadProof;
    }

    function getTimestampProof() public returns (bytes32[4] memory) {
        for (uint256 i = 0; i < 4; i++) {
            prefix = string.concat(".TimestampProof[", string.concat(vm.toString(i), "]"));
            timestampProofs[i] = (stdJson.readBytes32(proofConfigJson, prefix));
        }
        return timestampProofs;
    }

    function getBlockHeaderProof() public returns (bytes32[18] memory) {
        for (uint256 i = 0; i < 18; i++) {
            prefix = string.concat(".BlockHeaderProof[", string.concat(vm.toString(i), "]"));
            blockHeaderProof[i] = (stdJson.readBytes32(proofConfigJson, prefix));
        }
        return blockHeaderProof;
    }

    function getSlotProof() public returns (bytes32[3] memory) {
        for (uint256 i = 0; i < 3; i++) {
            prefix = string.concat(".SlotProof[", string.concat(vm.toString(i), "]"));
            slotProof[i] = (stdJson.readBytes32(proofConfigJson, prefix));
        }
        return slotProof;
    }

    function getStateRootProof() public returns (bytes32[] memory) {
        bytes32[] memory stateRootProof = new bytes32[](3);
        for (uint256 i = 0; i < 3; i++) {
            prefix = string.concat(
                ".StateRootAgainstLatestBlockHeaderProof[", string.concat(vm.toString(i), "]")
            );
            stateRootProof[i] = (stdJson.readBytes32(proofConfigJson, prefix));
        }
        return stateRootProof;
    }

    function getWithdrawalProof() public returns (bytes32[9] memory) {
        for (uint256 i = 0; i < 9; i++) {
            prefix = string.concat(".WithdrawalProof[", string.concat(vm.toString(i), "]"));
            withdrawalProof[i] = (stdJson.readBytes32(proofConfigJson, prefix));
        }
        return withdrawalProof;
    }

    function getValidatorProof() public returns (bytes32[46] memory) {
        for (uint256 i = 0; i < 46; i++) {
            prefix = string.concat(".ValidatorProof[", string.concat(vm.toString(i), "]"));
            validatorProof[i] = (stdJson.readBytes32(proofConfigJson, prefix));
        }
        return validatorProof;
    }

    function getHistoricalSummaryProof() public returns (bytes32[44] memory) {
        for (uint256 i = 0; i < 44; i++) {
            prefix = string.concat(".HistoricalSummaryProof[", string.concat(vm.toString(i), "]"));
            historicalSummaryProof[i] = (stdJson.readBytes32(proofConfigJson, prefix));
        }
        return historicalSummaryProof;
    }

    function getWithdrawalFields() public returns (bytes32[] memory) {
        bytes32[] memory withdrawalFields = new bytes32[](4);
        for (uint256 i = 0; i < 4; i++) {
            prefix = string.concat(".WithdrawalFields[", string.concat(vm.toString(i), "]"));
            withdrawalFields[i] = (stdJson.readBytes32(proofConfigJson, prefix));
        }
        return withdrawalFields;
    }

    function getValidatorFields() public returns (bytes32[] memory) {
        bytes32[] memory validatorFields = new bytes32[](8);
        for (uint256 i = 0; i < 8; i++) {
            prefix = string.concat(".ValidatorFields[", string.concat(vm.toString(i), "]"));
            validatorFields[i] = (stdJson.readBytes32(proofConfigJson, prefix));
        }
        return validatorFields;
    }

    function getValidatorBalanceProof() public returns (bytes32[] memory) {
        bytes32[] memory validatorBalanceProof = new bytes32[](44);
        for (uint256 i = 0; i < 44; i++) {
            prefix = string.concat(".ValidatorBalanceProof[", string.concat(vm.toString(i), "]"));
            validatorBalanceProof[i] = (stdJson.readBytes32(proofConfigJson, prefix));
        }
        return validatorBalanceProof;
    }

    function getBalanceUpdateSlotProof() public returns (bytes32[] memory) {
        bytes32[] memory balanceUpdateSlotProof = new bytes32[](5);
        for (uint256 i = 0; i < 5; i++) {
            prefix = string.concat(".slotProof[", string.concat(vm.toString(i), "]"));
            balanceUpdateSlotProof[i] = (stdJson.readBytes32(proofConfigJson, prefix));
        }
        return balanceUpdateSlotProof;
    }

    function getWithdrawalCredentialProof() public returns (bytes32[] memory) {
        bytes32[] memory withdrawalCredenitalProof = new bytes32[](46);
        for (uint256 i = 0; i < 46; i++) {
            prefix =
                string.concat(".WithdrawalCredentialProof[", string.concat(vm.toString(i), "]"));
            withdrawalCredenitalProof[i] = (stdJson.readBytes32(proofConfigJson, prefix));
        }
        return withdrawalCredenitalProof;
    }

    function getValidatorFieldsProof() public returns (bytes32[] memory) {
        bytes32[] memory validatorFieldsProof = new bytes32[](46);
        for (uint256 i = 0; i < 46; i++) {
            prefix = string.concat(".ValidatorFieldsProof[", string.concat(vm.toString(i), "]"));
            validatorFieldsProof[i] = (stdJson.readBytes32(proofConfigJson, prefix));
        }
        return validatorFieldsProof;
    }
}
