// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

/**
 * @dev Contract is for Szeeta event creators to reward their contributors for
 * acheiving certain milestones.
 *
 * Since the contract is only callable by the administration contract, the
 * milestone is not stored in the contract to be more flexible. When the milestone
 * is achieved, the contributor can mint the token without paying gas requesting
 * the organization which will validate at mint it for them.
 *
 * Although the owners cannot mint any token upoun their will, ownership of the contract
 * is transfered to the owner using the Openzeppelin Ownable utility contract is to give
 * them right to edit their collection settings and add royalties in application like
 * Opensea to edit cause Ownable access rights are trusted by many appications to prove
 * ownership.
 *
 * Transfering and renouncing ownership is not possible for the owner while the event is active.
 * And ownership of the contract is transfered when the event is transfered through the administration
 * contract. After the event is closed, authority for transfering and renouncing ownership is given back
 * to the owner.
 */
contract RewardNFT is Initializable, ERC721Upgradeable{
    /**
     * @dev Address of the event creator.
     */
     address private _owner;

    /**
     * @dev Address of the administration contract. Only administration contract can manage
     * ownership and mint nfts on behalf of the eligible contributors. Manipulating sensitive
     * information can only be done by the calling the administration contract from the 
     * organization with the signed message of the owner to ensure security.
     */
    address public administration;

    /**
     * @dev Numerical incrementer is used to assign token ids.
     */
    uint public tokenCounter;

    /**
     * @dev Keeps the ative state of the event to manage the ownership transfering rights
     * between organization and owner.
     */
    bool public isClosed;

    /**
     * @dev All tokens have a fixed URI which is assinged through the constructor.
     */
    string private metadataURI;

    modifier onlyAdmin(){
        require(administration == msg.sender && !isClosed, "Invalid Caller!");
        _;
    }

    modifier onlyOwner(){
        require(_owner == msg.sender, "Invalid Caller!");
        _;
    }

    function initialize(
       address eventOwner,
       address admin,
       string memory name, 
       string memory symbol, 
       string memory uri
    )
       public
       initializer
    {
        administration = admin;
        metadataURI = uri;

        /**
         * @dev Ownership is transfered eventhough their are no access point for owner is to
         * prove the ownership.
         */
        _owner = eventOwner;
        
        /**
         * @dev Initiate the NFT instance.
         */
         __ERC721_init(name, symbol);

        /**
         * @dev First toke will be transfered to the owner of the event.
         */
        _safeMint(eventOwner, 1);

        /**
         * @dev Token counter is incremented after assigning id. Therefore after the owner gets the
         * first mint, the initial value will be 2.
         */
        tokenCounter = 2;
        
    }

    /**
     * @dev Function to mint the nfts that is only callable by the organization.
     *
     * @return The token id of the minted token. 
     */
    function mint(address contributor) external onlyAdmin returns(uint256){
        uint currentUsableId = tokenCounter;
        _safeMint(contributor, currentUsableId);
        tokenCounter ++;
        return currentUsableId;
    }

    function close() external onlyAdmin{
        isClosed = true;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory){
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        return metadataURI;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Event creators will not get to transfer ownership while the page is ative.
     * The organization will get to transfer ownership to the new owner when the current
     * user transfer ownership of the event.
     */
    function transferOwnership(address newOwner) public {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        require( (isClosed && msg.sender == owner()) || (!isClosed && msg.sender == administration) , "Unathourized Caller!");
        _owner = newOwner;
    }

    /**
     * @dev Event creators will not get to renounce their ownership while the page is ative
     */
    function renounceOwnership() public onlyOwner {
        require(isClosed, "Cannot Renounce Ownership, Event Still Open!");
        _owner = address(0);
    }
}
