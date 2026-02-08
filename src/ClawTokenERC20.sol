// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC20} from "solady/tokens/ERC20.sol";

/// @title ClawTokenERC20
/// @notice Agent-optimized ERC-20 token for the OpenClaw protocol
/// @dev Built on Solady ERC20 for gas optimization
/// @author OpenClaw v2.0
contract ClawTokenERC20 is ERC20 {
    /*//////////////////////////////////////////////////////////////
                                ERRORS
    //////////////////////////////////////////////////////////////*/

    error Unauthorized();
    error InvalidAddress();
    error InvalidAmount();
    error SessionExpired();
    error SessionLimitExceeded();
    error AgentFrozen();
    error ContractPaused();
    error SessionAlreadyActive();
    error NoActiveSession();

    /*//////////////////////////////////////////////////////////////
                                EVENTS
    //////////////////////////////////////////////////////////////*/

    event OperatorAdded(address indexed agent);
    event OperatorRemoved(address indexed agent);
    event SessionGranted(address indexed agent, uint256 spendLimit, uint256 expiry);
    event SessionRevoked(address indexed agent);
    event SessionSpent(address indexed agent, uint256 amount, uint256 remaining);
    event AgentFreezeToggled(address indexed agent, bool frozen);
    event PauseToggled(bool paused);

    /*//////////////////////////////////////////////////////////////
                                STRUCTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Defines a time-bounded, spend-capped session for an agent
    struct Session {
        uint256 spendLimit; // Max tokens agent can transfer in this session
        uint256 spent; // Tokens already spent in this session
        uint256 expiry; // Unix timestamp when session expires
        bool active; // Whether session is currently active
    }

    /*//////////////////////////////////////////////////////////////
                                STATE
    //////////////////////////////////////////////////////////////*/

    address public immutable owner;
    string private _name;
    string private _symbol;

    mapping(address => bool) public isOperator;
    mapping(address => Session) public sessions;
    mapping(address => bool) public frozenAgents;
    bool public paused;

    /*//////////////////////////////////////////////////////////////
                              MODIFIERS
    //////////////////////////////////////////////////////////////*/

    modifier onlyOwner() {
        if (msg.sender != owner) revert Unauthorized();
        _;
    }

    modifier whenNotPaused() {
        if (paused) revert ContractPaused();
        _;
    }

    /*//////////////////////////////////////////////////////////////
                             CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    /// @notice Deploys the token with fixed supply minted to owner
    /// @param name_ Token name
    /// @param symbol_ Token symbol
    /// @param totalSupply_ Total supply (in wei, 18 decimals)
    constructor(string memory name_, string memory symbol_, uint256 totalSupply_) {
        if (totalSupply_ == 0) revert InvalidAmount();
        owner = msg.sender;
        _name = name_;
        _symbol = symbol_;
        _mint(msg.sender, totalSupply_);
    }

    /*//////////////////////////////////////////////////////////////
                           ERC20 OVERRIDES
    //////////////////////////////////////////////////////////////*/

    function name() public view override returns (string memory) {
        return _name;
    }

    function symbol() public view override returns (string memory) {
        return _symbol;
    }

    /*//////////////////////////////////////////////////////////////
                         OPERATOR MANAGEMENT
    //////////////////////////////////////////////////////////////*/

    /// @notice Register an address as a trusted agent operator
    /// @param agent Address to register
    function addOperator(address agent) external onlyOwner {
        if (agent == address(0)) revert InvalidAddress();
        isOperator[agent] = true;
        emit OperatorAdded(agent);
    }

    /// @notice Remove an address from trusted operators
    /// @param agent Address to remove
    function removeOperator(address agent) external onlyOwner {
        isOperator[agent] = false;
        _revokeSession(agent);
        emit OperatorRemoved(agent);
    }

    /*//////////////////////////////////////////////////////////////
                          SESSION MANAGEMENT
    //////////////////////////////////////////////////////////////*/

    /// @notice Grant a spend-limited, time-bounded session to an agent
    /// @param agent Agent address (must be registered operator)
    /// @param spendLimit Max tokens the agent can spend during session
    /// @param duration Session duration in seconds
    function grantSession(address agent, uint256 spendLimit, uint256 duration) external onlyOwner {
        if (!isOperator[agent]) revert Unauthorized();
        if (spendLimit == 0) revert InvalidAmount();
        if (sessions[agent].active) revert SessionAlreadyActive();

        sessions[agent] = Session({spendLimit: spendLimit, spent: 0, expiry: block.timestamp + duration, active: true});

        emit SessionGranted(agent, spendLimit, block.timestamp + duration);
    }

    /// @notice Revoke an agent's active session
    /// @param agent Agent address
    function revokeSession(address agent) external onlyOwner {
        _revokeSession(agent);
    }

    /// @notice Internal session revocation
    function _revokeSession(address agent) internal {
        if (sessions[agent].active) {
            sessions[agent].active = false;
            emit SessionRevoked(agent);
        }
    }

    /*//////////////////////////////////////////////////////////////
                          AGENT TRANSFERS
    //////////////////////////////////////////////////////////////*/

    /// @notice Agent spends tokens from owner's balance within session limits
    /// @param to Recipient address
    /// @param amount Amount to transfer
    function agentTransfer(address to, uint256 amount) external whenNotPaused {
        if (frozenAgents[msg.sender]) revert AgentFrozen();

        Session storage session = sessions[msg.sender];
        if (!session.active) revert NoActiveSession();
        if (block.timestamp > session.expiry) revert SessionExpired();
        if (session.spent + amount > session.spendLimit) revert SessionLimitExceeded();

        session.spent += amount;
        uint256 remaining = session.spendLimit - session.spent;

        _transfer(owner, to, amount);

        emit SessionSpent(msg.sender, amount, remaining);
    }

    /*//////////////////////////////////////////////////////////////
                           SAFETY RAILS
    //////////////////////////////////////////////////////////////*/

    /// @notice Freeze or unfreeze a specific agent
    /// @param agent Agent address
    /// @param frozen Whether to freeze
    function setAgentFrozen(address agent, bool frozen) external onlyOwner {
        frozenAgents[agent] = frozen;
        emit AgentFreezeToggled(agent, frozen);
    }

    /// @notice Toggle global pause
    function togglePause() external onlyOwner {
        paused = !paused;
        emit PauseToggled(paused);
    }

    /*//////////////////////////////////////////////////////////////
                              VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice Get remaining spend for an agent's session
    /// @param agent Agent address
    /// @return remaining Tokens remaining in session budget
    function sessionRemaining(address agent) external view returns (uint256 remaining) {
        Session memory session = sessions[agent];
        if (!session.active || block.timestamp > session.expiry) return 0;
        return session.spendLimit - session.spent;
    }

    /// @notice Check if an agent's session is currently valid
    /// @param agent Agent address
    /// @return valid Whether session is active and not expired
    function isSessionValid(address agent) external view returns (bool valid) {
        Session memory session = sessions[agent];
        return session.active && block.timestamp <= session.expiry;
    }
}
