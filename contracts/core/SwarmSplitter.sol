// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";

contract SwarmSplitter is Ownable {
    address[] public members;
    mapping(address => uint256) public shares;
    uint256 public totalShares;

    event Distributed(uint256 amount);
    event MemberAdded(address indexed member, uint256 share);

    constructor(address[] memory _members, uint256[] memory _shares) Ownable(msg.sender) {
        require(_members.length == _shares.length, "Length mismatch");
        require(_members.length > 0, "No members");

        for (uint256 i = 0; i < _members.length; i++) {
            require(_members[i] != address(0), "Invalid address");
            require(_shares[i] > 0, "Zero share");
            members.push(_members[i]);
            shares[_members[i]] = _shares[i];
            totalShares += _shares[i];
            emit MemberAdded(_members[i], _shares[i]);
        }
    }

    receive() external payable {}

    function distribute() external {
        uint256 balance = address(this).balance;
        require(balance > 0, "Nothing to distribute");

        for (uint256 i = 0; i < members.length; i++) {
            uint256 payment = (balance * shares[members[i]]) / totalShares;
            (bool sent, ) = members[i].call{value: payment}("");
            require(sent, "Transfer failed");
        }

        emit Distributed(balance);
    }

    function getMemberCount() external view returns (uint256) {
        return members.length;
    }
}
