// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";



/**
 * @dev Contract is for Szeeta event creators to reward their contributors for
 * acheiving certain milestones and who does not want to create a seperate collection
 * for the event.
 *
 * Since the contract is only callable by the administration contract, the
 * milestone is not stored in the contract to be more flexible. When the milestone
 * is achieved, the contributor can mint the token without paying gas requesting
 * the organization which will validate at mint it for them.
 *
 * In this case the owner will use a publicly available collection for all creator
 * to reward their contributors and owner will have no separate ownership rights
 * for the collection.
 *
 * And the event owner initiate the reward system by calling the contract through
 * the administration contract and assiging the token URI.
 */
contract SzeetaEventRewards is ERC721, Ownable{
    /**
     * @dev Numerical incrementer is used to assign token ids.
     */
    uint public tokenCounter;

    /**
     * @dev Stores the token URI of the specific event mapped to the id.
     */
    mapping (uint => string) public eventURI;

    /**
     * @dev Stores the assigned URI for the token id.
     */
    mapping (uint => string) private URIs;

    constructor(address admin)ERC721("Szeeta Events Rewards", "ZEVENT"){
        /**
         * @dev Token counter is incremented after assigning id. Therefore initial value
         * is 1.
         */
        tokenCounter = 1;
        transferOwnership(admin);
    }

    function mint(address contributor, uint eventId) external onlyOwner returns(uint256){
        uint currentUsableId = tokenCounter;
        _safeMint(contributor, currentUsableId);
        URIs[tokenCounter] = eventURI[eventId];
        tokenCounter ++;
        return currentUsableId;
    }

    /**
     * @dev restricted function for an event to initiate rewards by assigning the token
     * URI which is non modifiable.
     */
    function addEventUri(uint eventId, string memory metadataUri) external onlyOwner{
        require(bytes(eventURI[eventId]).length == 0, "Already Assigned!");
        eventURI[eventId] = metadataUri;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory){
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        return URIs[tokenId];
    }
}
