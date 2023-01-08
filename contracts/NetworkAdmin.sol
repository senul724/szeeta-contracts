// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/IERC20.sol";

/**
 * @dev Network admins keeps intrack of the information related to events.
 * Each netwok admin represents a supported network and soters the information related
 * to that network.
 *
 * Network admins are deployed from the administration contracts and only the administration
 * contract can manipulate data inside the contract.
 */
contract NetworkAdmin{

    /**
     * @dev Network id of the network that the contract represents.
    */
    uint256 public immutable network;

    /**address 
     * @dev Address of the Administration contract.
     * Only Administration contract can manipulate data inside the contract.
     */
    address public immutable admin;

    /**
    * @dev Fees are recorded only for native contributions to reduce gas for the contributor.
    * Fees are manually withdrawn from the Examiner contract.
    */
    uint256 public fees;

    /**
     * @dev Stores the receiving addresses of the events.
     */
    mapping(uint256 => address) public receivers;

    /**
     * @dev Keeps in track of the native currency contributions received for an event from the
     * represented network.
     */
    mapping(uint256 => uint256) public contributionsReceived;

    /**
     * @dev Keeps in track of the ERC20 contributions received for an event from the represented
     * network.
     */
    mapping(uint256 => mapping(address=>uint256)) public tokenContributionsReceived;

    modifier onlyAdmin(){
        require(msg.sender == admin, "Unauthorized Caller!");
        _;
    }

    constructor(uint256 netId){
        network = netId;
        admin = msg.sender;
    }

    /**
     * @dev Creator of the event can change the receiving address for the represented
     * network by calling the contract through the Administration contract.
     * Event owners cannot call the network admin contract directly.
     */
    function changeReceiver(address newReceiver, uint256 eventId) external onlyAdmin{
        receivers[eventId] = newReceiver;
    }

    /**
     * @dev Records the native currency contributions received and fees.
     * Fee factor is sent as a argument from the administration contract 
     */
    function addNativeContributions(uint256 eventId, uint256 amount, uint256 feeFactor) external onlyAdmin{
        fees += amount/feeFactor;
        contributionsReceived[eventId] += amount;
    }

    /**
     * @dev Records the ERC20 contributions received.
     * Fees are not recorded in ERC20 contributions cause the fees are distriubted immediatly.
     */
    function addTokenContributions(uint256 eventId, uint256 amount, address token) external onlyAdmin{
        tokenContributionsReceived[eventId][token] += amount;
    }
}
