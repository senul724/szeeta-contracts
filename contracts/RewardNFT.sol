// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract RewardNFT is ERC721, Ownable{
    address public org;
    uint public tokenCounter;
    mapping (uint => string) URIs;

    constructor(address owner, address org_, string memory name, string memory symbol)
        ERC721(name, symbol)
    {
        tokenCounter = 1;
        org = org_;
        /**
          Ownership is transfered eventhough their are no access point for owner is to prove the Ownership
          to opensea so the creator can edit the event.
        */
        transferOwnership(owner);
    }

    function mint(address donor, string calldata uri) external returns(uint256){
        require(msg.sender == org);
        uint currentUsableId = tokenCounter;
        _safeMint(donor, currentUsableId);
        URIs[tokenCounter] = uri;
        tokenCounter ++;
        return currentUsableId;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory){
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        return URIs[tokenId];
    }
}
