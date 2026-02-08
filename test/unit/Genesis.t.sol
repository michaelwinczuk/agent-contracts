// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {Genesis} from "../../contracts/src/Genesis.sol";

/**
 * @title GenesisTest
 * @author OpenClaw v2.0 — Test Engineer Cartridge
 * @notice Unit tests for Genesis.sol
 */
contract GenesisTest is Test {
    Genesis public genesis;
    address public deployer;

    /// @notice Emitted when Genesis is deployed — must match contract event
    event GenesisDeployed(address indexed owner, uint256 timestamp);

    function setUp() public {
        deployer = address(this);
        genesis = new Genesis();
    }

    function test_IsAlive() public view {
        assertTrue(genesis.isAlive(), "Genesis should be alive");
    }

    function test_OwnerSetCorrectly() public view {
        assertEq(genesis.owner(), deployer, "Owner should be deployer");
    }

    function test_BirthTimestampSet() public view {
        assertGt(genesis.BIRTH_TIMESTAMP(), 0, "Birth timestamp should be greater than zero");
    }

    function test_GenesisDeployedEvent() public {
        vm.expectEmit(true, false, false, true);
        emit GenesisDeployed(address(this), block.timestamp);
        new Genesis();
    }

    function test_NonOwnerCannotTransferOwnership() public {
        address attacker = makeAddr("attacker");
        vm.prank(attacker);
        vm.expectRevert();
        genesis.transferOwnership(attacker);
    }
}
