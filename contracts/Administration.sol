// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./NetworkAdmin.sol";
import "./openzeppalin-utils/EIP712.sol";
import "./openzeppalin-utils/Ownable.sol";

/**
 * @dev Contract manages event information throught out all supoorted network.
 *
 * Contract deploys a network admin didicated to each network adn stores the network
 * specific data on the network admin contracts.
 *
 * Contract also manages all the admin functions that mainly includes manipulating sensitive
 * data of an event such as the receiing address by the user. All admin interactions require
 * the event owner to sign required data and call the contract through the orgnaizations private
 * key to enable gassless transactions.
 *
 * Contract also records all the contributions received and realted fees.
 */
contract Administration is EIP712, Ownable{
    /**
     * @dev Event ids are assigned by a incremented state variable. 
     */
    uint256 public eventCounter;

    /**
     * @dev Method used to calculate the fee
     * When the amount is devided by the fee factor, the quotient will be the fee.
     * example: If the fee is 1%, feeFactor will be 100.
     */
    uint256 public feeFactor;

    /**
     * @dev For getting network information required when creating an event.
     * Contains the chain id adn the receiving address of the specific network.
     */
    struct ChainData{
        uint256 netId;
        address receiver;
    }

    /**
     * @dev used for validating data with EIP712 signature type when receiving
     * token contributions.
     */
    struct AdminCall{
        address caller;
        uint256 eventId;
        uint256 nonce;
    }

    /**
     *@dev Typehash of the structs to be used in the validation process mentioned above.
     */
    bytes32 private constant adminTypeHash =
        keccak256(
            'AdminCall(address caller,uint256 eventId,uint256 nonce)'
        );

    /**
     * @dev Records the owners of the event.
     */
    mapping(uint256 => address) public owners;

    /**
     * @dev Keeps in track of the closed and opened state of an event.
     */
    mapping(uint256 => bool) public closed;

    /**
     * @dev Keeps in-track of the network admins.
     * Description available in the networkAdmin contract description.
     */
    mapping(uint256 => address) public networkAdmins;

    /**
     * @dev Keeps intrack of the processed transactions.
     */
    mapping(uint256 => bool) isExpired;

    constructor(uint feeFactor_) EIP712('szeeta', '0.0.1'){
        feeFactor = feeFactor_;
        eventCounter = 1;
    }

    /**
     * @dev Events are created by assigning an event id.
     *
     * @param owner Address of the event owner. Only owner can manipulate the event data by calling
     * the contract through the organization private key.
     * @param chainData Array of ChainData. Creator must atleast select one supported network to create an event.
     */
    function createEvent(address owner, ChainData[] calldata chainData) external onlyOwner returns(uint){
        require(chainData.length != 0, "Chain Data Empty!");

        /**
         * @dev Asigning event id to a local varible to save gas
         */
        uint eventId = eventCounter;
        owners[eventId] = owner;
        for(uint i; i<chainData.length;){
            ChainData calldata data = chainData[i];
            NetworkAdmin(networkAdmins[data.netId]).changeReceiver( data.receiver, eventId);
            unchecked{
                i++;
            }
        }
        eventCounter ++;
        return eventId;
    }

    // Functions of event administration

    /**
     * @dev Funtion to change the receiver of an event specific to the network.
     */
    function changeReceiver(
        address newReceiver, 
        uint256 chainId, 
        address caller, 
        uint256 eventId,
        uint nonce,
        bytes calldata signature
    ) 
        external 
        onlyOwner
    {
        authorizedAndOpen(caller, eventId, nonce, signature);
        NetworkAdmin(networkAdmins[chainId]).changeReceiver(newReceiver, eventId);
    }

    /**
     * @dev Function close an event
     *
     * NOTE: ONCE CLOSED AN EVENT CANNOT BE RE-OPENED
     */
    function close(
        address caller,
        uint256 eventId,
        uint256 nonce,
        bytes calldata signature
    )
        external
        onlyOwner
    {   
        authorizedAndOpen(caller, eventId, nonce, signature);
        closed[eventId] = true;
    }

    /**
     * @dev Function to transfer ownership of an event
     */
    function transferAuthority(
        address newOwner,
        address caller,
        uint256 eventId,
        uint256 nonce,
        bytes calldata signature
    )
        external
        onlyOwner
    {
        authorizedAndOpen(caller, eventId, nonce, signature);
        owners[eventId] = newOwner;
    }

    // For organizational use

    /**
     * @dev Funtion for changing the fee factor
     */
    function changeFeeFactor(uint newFeeFactor) external onlyOwner{
        feeFactor = newFeeFactor;
    }

    /**
     * @dev Adding new network support by deploying a network admin specific to the 
     * new network intended to supoort.
     */
    function addNetwork(uint netId) external onlyOwner{
        require(networkAdmins[netId] == address(0), "Network already initialized!");
        NetworkAdmin newNetwork = new NetworkAdmin(netId);
        networkAdmins[netId] = address(newNetwork);
    }

    /**
     * @dev Recording received native contributions.
     */
    function recordNativeContribution(uint eventId, uint amount, uint netId) external onlyOwner{
        NetworkAdmin instance = NetworkAdmin(networkAdmins[netId]);
        require(instance.receivers(eventId) != address(0));
        instance.addNativeContributions(eventId, amount, feeFactor);
    }

    /**
     * @dev Recording received native contributions.
     */
    function recordTokenContribution(uint eventId, uint amount, uint netId, address token) external onlyOwner{
        NetworkAdmin instance = NetworkAdmin(networkAdmins[netId]);
        require(instance.receivers(eventId) != address(0));
        instance.addTokenContributions(eventId, amount, token);
    }

    // internal

    /**
     * @dev Function to validate data sent for admin iteractions for event data manipulation.
     */
    function authorizedAndOpen(address caller, uint eventId, uint256 nonce, bytes calldata signature) internal{
        require(!closed[eventId] ,"Event closed!");
        require(owners[eventId] == caller,"Unauthorized Call!");
        require(!isExpired[nonce], "Transaction Expired!");
        bytes32 typedDataHash = _hashTypedDataV4(
            keccak256(
                abi.encode(adminTypeHash, caller, eventId, nonce)
            )
        );
        address caller_ = ECDSA.recover(typedDataHash, signature);
        require(caller == caller_, "Fake Signature!");

        isExpired[nonce] = true;
    }
}
