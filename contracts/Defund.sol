// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract DeeFund is ERC721{
    address public org;
    uint public tokenCounter;
    mapping (uint => string) URIs;

    constructor(address org_)
        ERC721("Deefund", "DEFNFT")
    {
        tokenCounter = 1;
        org = org_;
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
