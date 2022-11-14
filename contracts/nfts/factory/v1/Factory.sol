// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./RewardNFT.sol";

/**
 * @dev Contract mints custom collections and only callable by the Administrator.
 */
contract Factory{
    /**
     * @dev Address of the administration contract.
     */
    address public administration;

    constructor(address admin){
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
        RewardNFT instance = new RewardNFT(eventOwner, administration, name, symbol, uri);
        return address(instance);
    }
}
