// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./NetworkAdmin.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Administration is EIP712, Ownable{
    using ECDSA for bytes32;
    // Event count
    uint256 public eventCounter;
    // Fee factor
    uint256 public feeFactor;

    // Structs
    struct ChainData{
        uint256 netId;
        address receiver;
    }

    struct AdminCall{
        address caller;
        uint256 eventId;
        uint256 nonce;
    }

    // Typehash of the sigatuere structs
    bytes32 private constant adminTypeHash =
        keccak256(
            'AdminCall(address caller,uint256 eventId,uint256 nonce)'
        );

    // Owners of an event
    // (eventId => Owner address)
    mapping(uint256 => address) public owners;
    // Keeps the state of an event
    // (eventId => state)
    mapping(uint256 => bool) public closed;
    // Keeps in-track of the network admins
    // (chainId => NetworkAdmin address)
    mapping(uint256 => address) public networkAdmins;
    // keep intrack of the proccesed transactions
    mapping(uint256 => bool) isExpired;

    constructor(uint feeFactor_) EIP712('szeeta', '0.0.1'){
        feeFactor = feeFactor_;
        eventCounter = 1;
    }

    // Event creation
    function createEvent(address owner, ChainData[] calldata chainData) external onlyOwner returns(uint){
        // Asigning event id to a local varible to save gas
        require(chainData.length != 0, "Chain Data Empty!");
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

    // To change the receiving address of an event
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

    // To close an event
    // * ONCE CLOSED AN EVENT CANNOT BE RE-OPENED
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

    //function to transfer ownership
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

    // Changing the fee factor
    function changeFeeFactor(uint newFeeFactor) external onlyOwner{
        feeFactor = newFeeFactor;
    }

    // Adding new network support
    function addNetwork(uint netId) external onlyOwner{
        require(networkAdmins[netId] == address(0), "Network already initialized!");
        NetworkAdmin newNetwork = new NetworkAdmin(netId);
        networkAdmins[netId] = address(newNetwork);
    }

    // Recording received native contributions
    function recordNativeContribution(uint eventId, uint amount, uint netId) external onlyOwner{
        NetworkAdmin instance = NetworkAdmin(networkAdmins[netId]);
        require(instance.receivers(eventId) != address(0));
        instance.addNativeContributions(eventId, amount, feeFactor);
    }

    // Recording received native contributions
    function recordTokenContribution(uint eventId, uint amount, uint netId, address token) external onlyOwner{
        NetworkAdmin instance = NetworkAdmin(networkAdmins[netId]);
        require(instance.receivers(eventId) != address(0));
        instance.addTokenContributions(eventId, amount, token);
    }

    // internal
    function authorizedAndOpen(address caller, uint eventId, uint256 nonce, bytes calldata signature) internal{
        require(!closed[eventId] ,"Event closed!");
        require(owners[eventId] == caller,"Unauthorized Call!");
        require(!isExpired[nonce], "Transaction Expired!");
        address caller_ = _hashTypedDataV4(
            keccak256(
                abi.encode(adminTypeHash, caller, eventId, nonce)
            )
        ).recover(signature);
        require(caller == caller_, "Fake Signature!");

        isExpired[nonce] = true;
    }
}
