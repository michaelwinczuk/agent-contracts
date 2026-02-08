// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {ClawTokenERC20} from "../src/ClawTokenERC20.sol";

contract ClawTokenERC20Test is Test {
    ClawTokenERC20 public token;

    address public owner = address(this);
    address public agent1 = makeAddr("agent1");
    address public agent2 = makeAddr("agent2");
    address public recipient = makeAddr("recipient");
    address public nobody = makeAddr("nobody");

    uint256 public constant TOTAL_SUPPLY = 1_000_000 ether;
    uint256 public constant SESSION_LIMIT = 1_000 ether;
    uint256 public constant SESSION_DURATION = 1 hours;

    event OperatorAdded(address indexed agent);

    function setUp() public {
        token = new ClawTokenERC20("OpenClaw", "CLAW", TOTAL_SUPPLY);
    }

    /*//////////////////////////////////////////////////////////////
                          DEPLOYMENT TESTS
    //////////////////////////////////////////////////////////////*/

    function test_deployment_name() public view {
        assertEq(token.name(), "OpenClaw");
    }

    function test_deployment_symbol() public view {
        assertEq(token.symbol(), "CLAW");
    }

    function test_deployment_totalSupply() public view {
        assertEq(token.totalSupply(), TOTAL_SUPPLY);
    }

    function test_deployment_ownerBalance() public view {
        assertEq(token.balanceOf(owner), TOTAL_SUPPLY);
    }

    function test_deployment_ownerSet() public view {
        assertEq(token.owner(), owner);
    }

    function test_deployment_revert_zeroSupply() public {
        vm.expectRevert(ClawTokenERC20.InvalidAmount.selector);
        new ClawTokenERC20("OpenClaw", "CLAW", 0);
    }

    /*//////////////////////////////////////////////////////////////
                        OPERATOR MANAGEMENT TESTS
    //////////////////////////////////////////////////////////////*/

    function test_addOperator() public {
        token.addOperator(agent1);
        assertTrue(token.isOperator(agent1));
    }

    function test_addOperator_emitsEvent() public {
        vm.expectEmit(true, false, false, false);
        emit OperatorAdded(agent1);
        token.addOperator(agent1);
    }

    function test_addOperator_revert_notOwner() public {
        vm.prank(nobody);
        vm.expectRevert(ClawTokenERC20.Unauthorized.selector);
        token.addOperator(agent1);
    }

    function test_addOperator_revert_zeroAddress() public {
        vm.expectRevert(ClawTokenERC20.InvalidAddress.selector);
        token.addOperator(address(0));
    }

    function test_removeOperator() public {
        token.addOperator(agent1);
        token.removeOperator(agent1);
        assertFalse(token.isOperator(agent1));
    }

    function test_removeOperator_revokesSession() public {
        token.addOperator(agent1);
        token.grantSession(agent1, SESSION_LIMIT, SESSION_DURATION);
        token.removeOperator(agent1);
        assertFalse(token.isSessionValid(agent1));
    }

    /*//////////////////////////////////////////////////////////////
                        SESSION MANAGEMENT TESTS
    //////////////////////////////////////////////////////////////*/

    function test_grantSession() public {
        token.addOperator(agent1);
        token.grantSession(agent1, SESSION_LIMIT, SESSION_DURATION);
        assertTrue(token.isSessionValid(agent1));
        assertEq(token.sessionRemaining(agent1), SESSION_LIMIT);
    }

    function test_grantSession_revert_notOperator() public {
        vm.expectRevert(ClawTokenERC20.Unauthorized.selector);
        token.grantSession(nobody, SESSION_LIMIT, SESSION_DURATION);
    }

    function test_grantSession_revert_zeroLimit() public {
        token.addOperator(agent1);
        vm.expectRevert(ClawTokenERC20.InvalidAmount.selector);
        token.grantSession(agent1, 0, SESSION_DURATION);
    }

    function test_grantSession_revert_alreadyActive() public {
        token.addOperator(agent1);
        token.grantSession(agent1, SESSION_LIMIT, SESSION_DURATION);
        vm.expectRevert(ClawTokenERC20.SessionAlreadyActive.selector);
        token.grantSession(agent1, SESSION_LIMIT, SESSION_DURATION);
    }

    function test_revokeSession() public {
        token.addOperator(agent1);
        token.grantSession(agent1, SESSION_LIMIT, SESSION_DURATION);
        token.revokeSession(agent1);
        assertFalse(token.isSessionValid(agent1));
    }

    /*//////////////////////////////////////////////////////////////
                         AGENT TRANSFER TESTS
    //////////////////////////////////////////////////////////////*/

    function test_agentTransfer() public {
        token.addOperator(agent1);
        token.grantSession(agent1, SESSION_LIMIT, SESSION_DURATION);

        vm.prank(agent1);
        token.agentTransfer(recipient, 100 ether);

        assertEq(token.balanceOf(recipient), 100 ether);
        assertEq(token.sessionRemaining(agent1), SESSION_LIMIT - 100 ether);
    }

    function test_agentTransfer_fullLimit() public {
        token.addOperator(agent1);
        token.grantSession(agent1, SESSION_LIMIT, SESSION_DURATION);

        vm.prank(agent1);
        token.agentTransfer(recipient, SESSION_LIMIT);

        assertEq(token.balanceOf(recipient), SESSION_LIMIT);
        assertEq(token.sessionRemaining(agent1), 0);
    }

    function test_agentTransfer_revert_noSession() public {
        vm.prank(nobody);
        vm.expectRevert(ClawTokenERC20.NoActiveSession.selector);
        token.agentTransfer(recipient, 100 ether);
    }

    function test_agentTransfer_revert_expired() public {
        token.addOperator(agent1);
        token.grantSession(agent1, SESSION_LIMIT, SESSION_DURATION);

        vm.warp(block.timestamp + SESSION_DURATION + 1);

        vm.prank(agent1);
        vm.expectRevert(ClawTokenERC20.SessionExpired.selector);
        token.agentTransfer(recipient, 100 ether);
    }

    function test_agentTransfer_revert_exceedsLimit() public {
        token.addOperator(agent1);
        token.grantSession(agent1, SESSION_LIMIT, SESSION_DURATION);

        vm.prank(agent1);
        vm.expectRevert(ClawTokenERC20.SessionLimitExceeded.selector);
        token.agentTransfer(recipient, SESSION_LIMIT + 1);
    }

    function test_agentTransfer_revert_frozen() public {
        token.addOperator(agent1);
        token.grantSession(agent1, SESSION_LIMIT, SESSION_DURATION);
        token.setAgentFrozen(agent1, true);

        vm.prank(agent1);
        vm.expectRevert(ClawTokenERC20.AgentFrozen.selector);
        token.agentTransfer(recipient, 100 ether);
    }

    function test_agentTransfer_revert_paused() public {
        token.addOperator(agent1);
        token.grantSession(agent1, SESSION_LIMIT, SESSION_DURATION);
        token.togglePause();

        vm.prank(agent1);
        vm.expectRevert(ClawTokenERC20.ContractPaused.selector);
        token.agentTransfer(recipient, 100 ether);
    }

    /*//////////////////////////////////////////////////////////////
                          SAFETY RAIL TESTS
    //////////////////////////////////////////////////////////////*/

    function test_freezeAgent() public {
        token.setAgentFrozen(agent1, true);
        assertTrue(token.frozenAgents(agent1));
    }

    function test_unfreezeAgent() public {
        token.setAgentFrozen(agent1, true);
        token.setAgentFrozen(agent1, false);
        assertFalse(token.frozenAgents(agent1));
    }

    function test_togglePause() public {
        token.togglePause();
        assertTrue(token.paused());
        token.togglePause();
        assertFalse(token.paused());
    }

    function test_freeze_revert_notOwner() public {
        vm.prank(nobody);
        vm.expectRevert(ClawTokenERC20.Unauthorized.selector);
        token.setAgentFrozen(agent1, true);
    }

    function test_pause_revert_notOwner() public {
        vm.prank(nobody);
        vm.expectRevert(ClawTokenERC20.Unauthorized.selector);
        token.togglePause();
    }

    /*//////////////////////////////////////////////////////////////
                           VIEW FUNCTION TESTS
    //////////////////////////////////////////////////////////////*/

    function test_sessionRemaining_noSession() public view {
        assertEq(token.sessionRemaining(nobody), 0);
    }

    function test_sessionRemaining_expired() public {
        token.addOperator(agent1);
        token.grantSession(agent1, SESSION_LIMIT, SESSION_DURATION);
        vm.warp(block.timestamp + SESSION_DURATION + 1);
        assertEq(token.sessionRemaining(agent1), 0);
    }

    function test_isSessionValid_expired() public {
        token.addOperator(agent1);
        token.grantSession(agent1, SESSION_LIMIT, SESSION_DURATION);
        vm.warp(block.timestamp + SESSION_DURATION + 1);
        assertFalse(token.isSessionValid(agent1));
    }

    /*//////////////////////////////////////////////////////////////
                        STANDARD ERC20 TESTS
    //////////////////////////////////////////////////////////////*/

    function test_transfer() public {
        token.transfer(recipient, 500 ether);
        assertEq(token.balanceOf(recipient), 500 ether);
    }

    function test_approve_and_transferFrom() public {
        token.approve(agent1, 500 ether);

        vm.prank(agent1);
        token.transferFrom(owner, recipient, 500 ether);

        assertEq(token.balanceOf(recipient), 500 ether);
    }
}
