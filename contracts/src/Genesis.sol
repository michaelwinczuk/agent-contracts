// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title Genesis
 * @author OpenClaw v2.0
 * @notice First contract in the OpenClaw framework. Proof of life.
 * @dev Minimal Ownable contract. Foundation stone for all future modules.
 */
contract Genesis is Ownable {
    /// @notice Timestamp of contract deployment
    uint256 public immutable BIRTH_TIMESTAMP;

    /// @notice Emitted when the contract is deployed
    event GenesisDeployed(address indexed owner, uint256 timestamp);

    constructor() Ownable(msg.sender) {
        BIRTH_TIMESTAMP = block.timestamp;
        emit GenesisDeployed(msg.sender, block.timestamp);
    }

    /// @notice Returns true. Proof of life.
    function isAlive() external pure returns (bool) {
        return true;
    }
}
