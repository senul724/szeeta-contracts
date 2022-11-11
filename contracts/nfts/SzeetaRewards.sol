// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


/**
 * @dev Contract is used to reward Szeeta ccntributors for achieving certain milestones.
 * Every milestone has it's own URI mapped to it's unique id. And when minting the milestone
 * id is sent as and argument and the realted URI will be assigned to the token Id. 
 *
 *And the milestone URIs are modifiable till the stable realease cause we beleive we will get
 * some awesome ideas from our beta users and might have to change the milestone images
 * accordingly for the best outcome. 
 *
 * And also, no modifications are allowed after the stable release. Only adding new milestones
 * are allowed.
 */
contract SzeetaRewards is ERC721, Ownable{
    /**
     * @dev Numerical incrementer is used to assign token ids.
     */
    uint256 public tokenCounter;

    /**
     * @dev Keep the sate to avoid modifications after stable release.
     */
    bool public isStable;

    /**
     * @dev Token id to URI mapping(as metioned above).
     */
    mapping (uint256 => uint256) private URIs;

    /**
     * @dev Stores the milestone metdata URIs mapped to it's id.
     */
    mapping (uint256 => string) public metadata;

    constructor(address org)ERC721("Szeeta Rewards", "SZEETA"){
        /**
         * @dev Token counter is incremented after assigning id. Therefore initial value
         * is 1.
         */
        tokenCounter = 1;
        transferOwnership(org);
    }

    function mint(address contributor, uint256 milestoneId) external onlyOwner returns(uint256){
        /**
         * @dev Usable id is assigned to a local state variable to save gas.
         */
        uint256 currentUsableId = tokenCounter;
        _safeMint(contributor, currentUsableId);

        /**
         * @dev Assigning the URI as mentioned in the contract description.
         */
        URIs[currentUsableId] = milestoneId;
        tokenCounter ++;
        return currentUsableId;
    }

    /**
     * @dev Restricted function to assing milestone metadata URIs.
     */
    function assignMetadata(uint256 id, string memory value) external onlyOwner{
        /**
         * @dev Statement to avoid reassigning milestone URIs after stable release.
         */
        require(!isStable || bytes(metadata[id]).length == 0, "Invalid mutation!");
        metadata[id] = value;
    }

    /**
     * @dev Restricted function to relase stable version.
     * This state is only changable once.
     */
    function releaseStable() external onlyOwner{
      require(!isStable, "Already realeased!");
      isStable = true;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory){
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        return metadata[URIs[tokenId]];
    }
}
