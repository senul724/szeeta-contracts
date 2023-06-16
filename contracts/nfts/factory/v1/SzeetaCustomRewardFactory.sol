// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.0;

import "./SzeetaCustomRewardNFT.sol";

/**
 * @dev Factory contract of Szeeta to mints custom collections.
 * This contract is only callable by the Administrator.
 */
contract SzeetaCustomRewardFactory{
    /**
     * @dev Address of the organization.
     */
    address public org;

    /**
     * @dev Address of the administration contract.
     */
    address public administration;

    constructor(address admin, address org_){
      administration = admin;
      org = org_;
    }

    /**
     * @dev Function mints a new custom NFT collection for Szeeta event rewards.
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
        SzeetaCustomRewardNFT instance = new SzeetaCustomRewardNFT(eventOwner, administration, name, symbol, uri);
        return address(instance);
    }

    /**
     * @dev Function to change administration contract
     */
    function changeAdministration(address newAdmin) external {
      require(msg.sender == org, "Unauthorized Call!");
      administration = newAdmin;
    }
}
