// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface ITollGate {
    function payToll(bytes32 serviceId) external payable;
    function toll(bytes32 serviceId) external view returns (uint256);
    function owner() external view returns (address);
}
