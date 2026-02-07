// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";

contract TollGate is Ownable {
    mapping(address => uint256) public pricePerCall;
    mapping(address => uint256) public earned;

    event PriceUpdated(address indexed service, uint256 price);
    event CallPaid(address indexed caller, address indexed service, uint256 amount);
    event Withdrawn(address indexed service, uint256 amount);

    constructor() Ownable(msg.sender) {}

    function register(uint256 _price) external {
        pricePerCall[msg.sender] = _price;
        emit PriceUpdated(msg.sender, _price);
    }

    function updatePrice(uint256 newPrice) external {
        require(pricePerCall[msg.sender] > 0, "Not registered");
        pricePerCall[msg.sender] = newPrice;
        emit PriceUpdated(msg.sender, newPrice);
    }

    function payToll(address service) external payable {
        require(pricePerCall[service] > 0, "Service not registered");
        require(msg.value >= pricePerCall[service], "Insufficient payment");
        earned[service] += msg.value;
        emit CallPaid(msg.sender, service, msg.value);
    }

    function withdraw() external {
        uint256 amount = earned[msg.sender];
        require(amount > 0, "Nothing to withdraw");
        earned[msg.sender] = 0;
        (bool sent, ) = msg.sender.call{value: amount}("");
        require(sent, "Transfer failed");
        emit Withdrawn(msg.sender, amount);
    }

    function toll(address service) external view returns (uint256) {
        return pricePerCall[service];
    }
}
