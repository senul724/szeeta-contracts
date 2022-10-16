// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "./interfaces/IOwner.sol";

contract Defund is ERC721{

    IOwner org;

    uint public tokenCounter;

    bool public ended;

    mapping (uint => string) URIs;

    // modifiers
    modifier notEnded(){
        require(!ended);
        _;
    }

    constructor(address org_)
        ERC721("Defund", "DFNFT") {

        tokenCounter = 1;
        org = IOwner(org_);
    }

    function mint(address donor, string calldata uri) external notEnded{
        require(msg.sender == org.getOrg());

        _safeMint(donor, tokenCounter);
        URIs[tokenCounter] = uri;

    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory){

        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        return URIs[tokenId];
    }
}
