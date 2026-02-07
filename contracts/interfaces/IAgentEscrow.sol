// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IAgentEscrow {
    function createDeal(
        address provider,
        bytes32 taskHash,
        uint256 deadline
    ) external payable returns (uint256 dealId);
    
    function confirmDelivery(uint256 dealId) external;
    function disputeDeal(uint256 dealId) external;
}
