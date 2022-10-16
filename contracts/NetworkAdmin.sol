// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./interfaces/IERC20.sol";

contract NetworkAdmin{
    // Network Id
    uint256 public immutable network;
    // Address of the Administration contract
    address public immutable admin;
    /** fees are recorded only for native contributions cause to reduce gas for the conrtibutor,
    * we manually withdraw the fees from the contract
    */
    // Oranizational fees
    uint256 public fees;

    // Keeps in-track of the network information
    // (eventId => receiver)
    mapping(uint256 => address) public receivers;
    // Keep in track of the contributions received for an event specific to network
    // (eventId => contribution)
    mapping(uint256 => uint256) public contributionsReceived;
    // (eventId => token => amount)
    mapping(uint256 => mapping(address=>uint256)) public tokenContributionsReceived;

    modifier onlyAdmin(){
        require(msg.sender == admin, "Unauthorized Caller!");
        _;
    }

    constructor(uint256 netId){
        network = netId;
        admin = msg.sender;
    }

    // To change the receiving address of an event
    function changeReceiver(address newReceiver, uint256 eventId) external onlyAdmin{
        receivers[eventId] = newReceiver;
    }

    // Adding contributions received and fees of organizations
    function addNativeContributions(uint256 eventId, uint256 amount, uint256 feeFactor) external onlyAdmin{
        fees += amount/feeFactor;
        contributionsReceived[eventId] += amount;
    }

    // Adding native contributions received and fees of organizations
    function addTokenContributions(uint256 eventId, uint256 amount, address token) external onlyAdmin{
        tokenContributionsReceived[eventId][token] += amount;
    }
}
