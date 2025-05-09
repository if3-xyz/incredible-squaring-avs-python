// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.12;

import "../src/IncredibleSquaringServiceManager.sol" as incsqsm;
import {IncredibleSquaringTaskManager} from "../src/IncredibleSquaringTaskManager.sol";
import "@eigenlayer/contracts/permissions/PauserRegistry.sol";
import "@eigenlayer/contracts/interfaces/IPauserRegistry.sol";
import {BLSMockAVSDeployer} from "@eigenlayer-middleware/test/utils/BLSMockAVSDeployer.sol";
import {TransparentUpgradeableProxy} from
    "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

contract IncredibleSquaringTaskManagerTest is BLSMockAVSDeployer {
    incsqsm.IncredibleSquaringServiceManager sm;
    incsqsm.IncredibleSquaringServiceManager smImplementation;
    IncredibleSquaringTaskManager tm;
    IncredibleSquaringTaskManager tmImplementation;

    uint32 public constant TASK_RESPONSE_WINDOW_BLOCK = 30;
    address aggregator = address(uint160(uint256(keccak256(abi.encodePacked("aggregator")))));
    address generator = address(uint160(uint256(keccak256(abi.encodePacked("generator")))));
    address initialOwner = makeAddr("initialOwner");
    address slasher = makeAddr("slasher");

    function setUp() public {
        _setUpBLSMockAVSDeployer();
        address[] memory _pausers = new address[](1);
        _pausers[0] = pauser;
        address pauserRegistry = address(new PauserRegistry(_pausers, unpauser));
        tmImplementation = new IncredibleSquaringTaskManager(
            incsqsm.ISlashingRegistryCoordinator(address(registryCoordinator)),
            IPauserRegistry(pauserRegistry),
            TASK_RESPONSE_WINDOW_BLOCK
        );

        // Third, upgrade the proxy contracts to use the correct implementation contracts and initialize them.
        tm = IncredibleSquaringTaskManager(
            address(
                new TransparentUpgradeableProxy(
                    address(tmImplementation),
                    address(proxyAdmin),
                    abi.encodeWithSelector(
                        tm.initialize.selector,
                        initialOwner,
                        aggregator,
                        generator,
                        allocationManager,
                        slasher,
                        address(serviceManager)
                    )
                )
            )
        );
    }

    function testCreateNewTask() public {
        bytes memory quorumNumbers = new bytes(0);
        cheats.prank(generator, generator);
        tm.createNewTask(2, 100, quorumNumbers);
        assertEq(tm.latestTaskNum(), 1);
    }
}
