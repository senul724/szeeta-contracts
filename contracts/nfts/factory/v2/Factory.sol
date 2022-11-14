// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./IRewardNFTV2.sol";

/**
 * @dev Contract manages event information throught out all supoorted network.
 *
 * Contract deploys a network admin didicated to each network adn stores the network
 * specific data on the network admin contracts.
 *
 * Contract also manages all the admin functions that mainly includes manipulating sensitive
 * data of an event such as the receiving address by the user. All admin interactions require
 * the event owner to sign required data and call the contract through the orgnaizations private
 * key to enable gassless transactions.
 *
 * Contract also records all the contributions received and realted fees.
 *
 * Last and the main functionality of the contract is handling NFT rewards that includes intiating
 * new instances, minting and managing ownership through out the lifetime of the event.
 *
 * All the mutations restricted for the Creator is done by the handler.
 */
contract Factory{
    /**
     * @dev Address of the administration contract.
     */
    address public administration;

    /**
     * @dev Base contract address of the custome NFT collection.
     */
    address private base;

    constructor(address admin, address base_){
        base = base_;
        administration = admin;
    }

    /**
     * @dev Function mints a new custom NFT collection for event rewards.
     */
    function mintCollection(
        address eventOwner,
        string memory name, 
        string memory symbol,
        string memory uri
    ) 
        external
        returns(address)
    {
        require(msg.sender == administration, "Unauthorized Call!");
        // deploying the new NFT collection
        address contractAddress = clone(base);
        IRewardNFTV2(contractAddress).initialize(eventOwner, administration, name, symbol, uri);
        return contractAddress;
    }

    /**
     * @dev EIP1167 minimal proxy code snippet from Openzeppalin Clones contract for cheap
     * deployement.
     */
    function clone(address base_) internal returns (address instance) {
        
        assembly {
            // Cleans the upper 96 bits of the `implementation` word, then packs the first 3 bytes
            // of the `implementation` address with the bytecode before the address.
            mstore(0x00, or(shr(0xe8, shl(0x60, base_)), 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000))
            // Packs the remaining 17 bytes of `implementation` with the bytecode after the address.
            mstore(0x20, or(shl(0x78, base_), 0x5af43d82803e903d91602b57fd5bf3))
            instance := create(0, 0x09, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }
}
