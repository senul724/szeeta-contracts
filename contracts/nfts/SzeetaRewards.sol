// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

/**
 * @dev Contract is used to reward Szeeta contributors for achieving certain milestones.
 * Every milestone has its own URI mapped to its unique id. And when minting the milestone
 * id is sent as an argument and the related URI will be assigned to the token Id. 
 *
 * And the milestone URIs are modifiable till the stable release cause we believe we will get
 * some awesome ideas from our beta users and might have to change the milestone images
 * accordingly for the best outcome. 
 *
 * And also, no modifications are allowed after the stable release. Only adding new milestones
 * are allowed.
 *
 * About authority, the org can mint and the governor can modify state variables. Authority is split for
 * security reasons.
 */
contract SzeetaRewards is ERC721{
    /**
     * @dev Address of the organization.
     */
    address public org;

    /**
     * @dev Address of the governor.
     */
    address public governor;

    /**
     * @dev Numerical incrementer is used to assign token ids.
     */
    uint256 public tokenCounter;

    /**
     * @dev Keep the state to avoid modifications after the stable release.
     */
    bool public isStable;

    /**
     * @dev Token id to URI mapping(as metioned above).
     */
    mapping (uint256 => uint256) private URIs;

    /**
     * @dev Stores the milestone metadata URIs mapped to its id.
     */
    mapping (uint256 => string) public metadata;

    constructor(address org_, address governor_)ERC721("Szeeta Rewards", "SZEETA"){
        /**
         * @dev Token counter is incremented after assigning id. Therefore initial value
         * is 1.
         */
        tokenCounter = 1;
        org = org_;
        governor = governor_;
    }

    function mint(address contributor, uint256 milestoneId) external returns(uint256){
        require(msg.sender == org, "Unauthorized Call!");

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
     * @dev Restricted function to assign milestone metadata URIs.
     */
    function assignMetadata(uint256 id, string memory value) external{
        require(msg.sender == governor, "Unauthorized Call!");

        /**
         * @dev Statement to avoid reassigning milestone URIs after stable release.
         */
        require(!isStable || bytes(metadata[id]).length == 0, "Invalid mutation!");
        metadata[id] = value;
    }

    /**
     * @dev Restricted function to release the stable version.
     * This state is only changeable once.
     */
    function releaseStable() external{
        require(!isStable && msg.sender == governor, "Invalid Call!");
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
