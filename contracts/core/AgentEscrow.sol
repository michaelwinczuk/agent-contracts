// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";

contract AgentEscrow is Ownable {
    enum Status { Active, Delivered, Refunded }

    struct Deal {
        address buyer;
        address provider;
        uint256 amount;
        bytes32 taskHash;
        uint256 deadline;
        Status status;
    }

    Deal[] public deals;

    event DealCreated(uint256 indexed dealId, address indexed buyer, address indexed provider, uint256 amount);
    event DealConfirmed(uint256 indexed dealId);
    event DealRefunded(uint256 indexed dealId);

    constructor() Ownable(msg.sender) {}

    function createDeal(
        address _provider,
        bytes32 _taskHash,
        uint256 _duration
    ) external payable {
        require(msg.value > 0, "Must send ETH");
        require(_provider != address(0), "Invalid provider");

        deals.push(Deal({
            buyer: msg.sender,
            provider: _provider,
            amount: msg.value,
            taskHash: _taskHash,
            deadline: block.timestamp + _duration,
            status: Status.Active
        }));

        emit DealCreated(deals.length - 1, msg.sender, _provider, msg.value);
    }

    function confirmDelivery(uint256 dealId) external {
        Deal storage deal = deals[dealId];
        require(msg.sender == deal.buyer, "Only buyer");
        require(deal.status == Status.Active, "Not active");

        deal.status = Status.Delivered;
        (bool sent, ) = deal.provider.call{value: deal.amount}("");
        require(sent, "Transfer failed");

        emit DealConfirmed(dealId);
    }

    function disputeDeal(uint256 dealId) external {
        Deal storage deal = deals[dealId];
        require(msg.sender == deal.buyer, "Only buyer");
        require(deal.status == Status.Active, "Not active");
        require(block.timestamp > deal.deadline, "Deadline not passed");

        deal.status = Status.Refunded;
        (bool sent, ) = deal.buyer.call{value: deal.amount}("");
        require(sent, "Transfer failed");

        emit DealRefunded(dealId);
    }

    function getDealCount() external view returns (uint256) {
        return deals.length;
    }
}
