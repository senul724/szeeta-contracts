// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.0;

import "./openzeppalin-utils/EIP712.sol";
import "./interfaces/IRewardNFT.sol";
import "./interfaces/ISzeetaEventRewards.sol";
import "./interfaces/IFactory.sol";

/**
 * @dev Contract manages event information throughout all supported networks.
 *
 * Contract also manages all the admin functions that mainly include manipulating sensitive
 * data of an event such as the receiving address by the user. All admin interactions require
 * the event owner to sign the required data and call the contract through the organization's private
 * key to enable gasless transactions.
 *
 * Last and the main functionality of the contract is handling NFT rewards that include initiating
 * new instances, minting and managing ownership throughout the lifetime of the event.
 *
 * All the mutations restricted for the Creator are done by the governor.
 */
contract SzeetaAdministratorV2 is EIP712{
    /**
     * @dev Address of the organization.
     */
    address public org;

    /** 
     * @dev Address of the Custom NFT Factory.
     */
    address public factory;

    /**
     * @dev Address of the governor.
     */
    address public governor;

    /**
     * @dev Event ids are assigned by an incremented state variable. 
     */
    uint256 public eventCounter;

    /**
     * @dev Method used to calculate the fee
     * When the amount is divided by the fee factor, the quotient will be the fee.
     * Example: If the fee is 1%, feeFactor will be 100.
     */
    uint256 public feeFactor;

    /**
     * @dev Address of the public NFT collection for event Rewards.
     */
    address public publicCollectionAddress;

    /**
     * @dev For getting network information required when creating an event.
     * Contains the chain id and the receiving address of the specific network.
     */
    struct ChainData{
        uint256 networkEventHash;
        address receiver;
    }

    /**
     * @dev used for validating data with EIP712 signature type when receiving
     * token contributions.
     */
    struct AdminCall{
        string cause;
        address caller;
        uint256 eventId;
        uint256 nonce;
    }

    /**
     *@dev Typehash of the structs to be used in the validation process mentioned above.
     */
    bytes32 private constant adminTypeHash =
        keccak256(
            'AdminCall(string cause,address caller,uint256 eventId,uint256 nonce)'
        );

/**
 * @dev receivers mapping keep track of the receiving addresses related to events
 * where network is mapped to event id that is mapped to receiving address.
 */
    mapping(uint256 => address) public receivers;

    /**
     * @dev Records the owners of the event.
     */
    mapping(uint256 => address) public owners;

    /**
     * @dev Keeps track of the closed and opened state of an event.
     */
    mapping(uint256 => bool) public closed;

    /**
     * @dev Keeps in-track of the custom NFT contracts created by the events
     * for rewards.
     */
    mapping(uint256 => address) public customCollections;

    /**
     * @dev Keeps track of the processed transactions.
     */
    mapping(uint256 => bool) private isExpired;

    // events
    event EventCreated(
        uint256 indexed eventId,
        address indexed owner,
        ChainData[] data
    );

    event EventTransfered(
        uint256 indexed eventId,
        address indexed newOwner,
        address exOwner
    );

    event EventClosed(
        address indexed owner,
        uint256 eventId,
        uint256 time
    );

    event ReceiverChanged(
        address indexed newReceiver,
        uint256 indexed networkEventHash
    );

    event NFTMinted(
        uint256 indexed eventId,
        address indexed contributor,
        address indexed collection
    );

    // modifiers
    modifier onlyOrg(){
      require(msg.sender == org, "Unauthorized call!");
      _;
    }

    modifier onlyGovernor(){
      require(msg.sender == governor, "Unauthorized call!");
      _;
    }

    constructor(uint feeFactor_, address org_, address governor_) EIP712('szeeta', '0.0.1'){
        feeFactor = feeFactor_;
        org = org_;
        governor = governor_;
        eventCounter = 1;
    }

    /**
     * @dev Events are created by assigning an event id.
     *
     * @param owner Address of the event owner. Only the owner can manipulate the event data by calling
     * the contract through the organization's private key.
     * @param chainData Array of ChainData. The creator must at least select one supported network to create an event.
     */
    function createEvent(address owner, ChainData[] memory chainData) external onlyOrg returns(uint){
        /**
         * @dev Assigning event id to a local variable to save gas
         */
        uint eventId = eventCounter;
        owners[eventId] = owner;
        for(uint i; i<chainData.length;){
            ChainData memory data = chainData[i];
            receivers[data.networkEventHash] = data.receiver;
            unchecked{
                i++;
            }
        }
        eventCounter ++;

        emit EventCreated(eventId, owner, chainData);
        return eventId;
    }

    // Functions of event administration

    /**
     * @dev Function to change the receiver of an event specific to the network.
     */
    function changeReceiver(
        address newReceiver,
        string memory cause,
        uint256 networkEventHash, 
        address caller, 
        uint256 eventId,
        uint nonce,
        bytes calldata signature
    ) 
        external 
        onlyOrg
    {
        authorizedAndOpen(cause, caller, eventId, nonce, signature);
        receivers[networkEventHash] = newReceiver;

        emit ReceiverChanged(newReceiver, networkEventHash);
    }

    /**
     * @dev Function close an event
     *
     * NOTE: ONCE CLOSED AN EVENT CAN NOT BE RE-OPENED
     */
    function close(
        string memory cause,
        address caller,
        uint256 eventId,
        uint256 nonce,
        bytes calldata signature,
        address nftContract
    )
        external
        onlyOrg
    {   
        require(!closed[eventId], "Event already closed!");
        authorizedAndOpen(cause, caller, eventId, nonce, signature);
        if(nftContract != address(0)){
            IRewardNFT(nftContract).close();
        }
        closed[eventId] = true;

        emit EventClosed(caller, eventId, block.timestamp);
    }

    /**
     * @dev Function to transfer ownership of an event
     */
    function transferAuthority(
        address newOwner,
        string memory cause,
        address caller,
        uint256 eventId,
        uint256 nonce,
        bytes calldata signature
    )
        external
        onlyOrg
    {
        authorizedAndOpen(cause, caller, eventId, nonce, signature);
        address nftContract = customCollections[eventId];
        if(nftContract != address(0)){
            IRewardNFT(nftContract).transferOwnership(newOwner);
        }
        owners[eventId] = newOwner;

        emit EventTransfered(eventId, newOwner, caller);
    }

    // NFT interaction

    /**
     * @dev Function to add the public NFT collection address after minting the contract.
     */
    function addPublicCollectionAddress(address collectionAddress) external onlyGovernor{
        publicCollectionAddress = collectionAddress;
    }

    /**
     * @dev Function to add the custom NFT factory address.
     */
    function addCollectionFactory(address factoryAddress) external onlyGovernor{
        factory = factoryAddress;
    }

    /**
     * @dev Function mints a new custom NFT collection for event rewards.
     */
    function createCustomCollection(
        address eventOwner,
        uint256 eventId,
        string memory name, 
        string memory symbol,
        string memory uri
    ) 
        external
        onlyOrg
        returns(address)
    {
        require(customCollections[eventId] == address(0), "Collection Already Created!");
        // deploying the new NFT collection
        address contractAddress =  IFactory(factory).mintCollection(eventOwner, name, symbol, uri);
        customCollections[eventId] = contractAddress;

        return contractAddress;
    }

    /**
     * @dev Function initiates event rewards in the public collection.
     */
    function joinPublicCollection(uint eventId, string memory metadataUri) external onlyOrg{
        ISzeetaEventRewards(publicCollectionAddress).addEventUri(eventId, metadataUri);
    }

    /**DeclarationError: Identifier already declared.
     * @dev Function to mint an NFT on behalf of the contributor from the dedicated collection
     * for the event.
     */
    function mintCustom(address contributor, uint256 eventId) external onlyOrg{
        address collectionAddress = customCollections[eventId];
        IRewardNFT(collectionAddress).mint(contributor);

        emit NFTMinted(eventId, contributor, collectionAddress);
    }

    /**
     * @dev Function to mint an NFT on behalf of the contributor from the public collection
     * for event rewards.
     */
    function mintPublic(address contributor, uint256 eventId) external onlyOrg{
        ISzeetaEventRewards(publicCollectionAddress).mint(contributor, eventId);

        emit NFTMinted(eventId, contributor, publicCollectionAddress);
    }

    /**
     * @dev Function to validate data sent for admin interactions for event data manipulation.
     */
    function authorizedAndOpen(string memory cause, address caller, uint eventId, uint256 nonce, bytes calldata signature) internal{
        require(owners[eventId] == caller,"Unauthorized Call!");
        require(!isExpired[nonce], "Transaction Expired!");
        bytes32 typedDataHash = _hashTypedDataV4(
            keccak256(
                abi.encode(
                    adminTypeHash,
                    keccak256(abi.encodePacked(cause)),
                    caller,
                    eventId,
                    nonce
                )
            )
        );
        address caller_ = ECDSA.recover(typedDataHash, signature);
        require(caller == caller_, "Fake Signature!");

        isExpired[nonce] = true;
    }

    // For organizational use

    /**
     * @dev restricted function to change organization address.
     */
    function changeOrg(address newOrg) external onlyGovernor{
        org = newOrg;
    }

    /**
     * @dev restricted function to change governor address.
     */
    function changeGovernor(address newGovernor) external onlyGovernor{
        governor = newGovernor;
    }

    /**
     * @dev Function for changing the fee factor.
     */
    function changeFeeFactor(uint newFeeFactor) external onlyGovernor{
        feeFactor = newFeeFactor;
    }
}
