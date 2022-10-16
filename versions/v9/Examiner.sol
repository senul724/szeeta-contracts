// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "./interfaces/IOwner.sol";


contract Examiner is Initializable{
    // Address of the Owner contract
    address public org;
    // Address to which the funds are transfered
    address public receiver;
    // Address of teh forwarder contract
    address public forwarder;

    /** Method used to calculate the fee
    *
    * When the amount is devided by the fee factor, the quotient will be the fee
    * example:
    * If the fee is 1%, feeFactor will be 100
    */
    uint256 feeFactor;
    // Contributions received in native currency
    uint256 public nativeContributions;
    // Close state
    bool public closed;

    // mappings

    // Keeps in-track of the admins
    mapping(address => bool) public admin;
    // ERC20 token contribution received
    mapping(address => uint256) public tokenContributions;
    // ERC20 tokens allowed for contribution
    mapping(address => bool) public allowedTokens;

    // modifiers
    modifier controlAccess(address authority) {
        require(msg.sender == authority,"Unauthorized Caller!");
        _;
    }
    modifier notClosed(){
        require(!closed,"Event Closed!");
        _;
        }

    //events
    event nativeContribution(
        address _contract,
        address from,
        uint256 amount
    );
    event tokenContribution(
        address _contract,
        address from,
        uint256 amount,
        address token
    );

    // Acts as the contructor for clones
    function initialize(
        address forwarder_,
        address org_,
        address admin_,
        address receiver_,
        uint256 feeFactor_,
        address[] calldata allowedTokenList
    ) external initializer{
        for (uint256 i; i < allowedTokenList.length; i++) {
            allowedTokens[allowedTokenList[i]] = true;
        }
        admin[admin_] = true;
        receiver = receiver_;
        feeFactor = feeFactor_;
        forwarder = forwarder_;
        org = org_;
    }

    // public functions
    function receiveTokenFunds(uint256 amount, address token, address from) external payable notClosed{
        require(allowedTokens[token]);

        completeTokenTansfer_(amount, token, from);
    }

    function receiveNativeFunds() external payable notClosed{
        completeNativeTansfer_(msg.value);
    }

    function isAdmin(address address_) external view returns(bool){
        return admin[address_];
    }

    // restricted
    function changeReceiver(address newReceiver) external controlAccess(forwarder) notClosed{
        receiver = newReceiver;
    }

    function changeAdminStatus(address admin_) external controlAccess(forwarder) notClosed{
        bool prevState = admin[admin_];
        admin[admin_] = !prevState;
    }

    function allowToken(address token) external controlAccess(forwarder) notClosed{
        allowedTokens[token] = true;
    }

    function close() external controlAccess(forwarder){
        closed = true;
    }

    // internal

    // Simple functions to avoid code repetition to trnasfer native currency
    function transferNativeFunds_(uint256 amount, address payee) internal {
        (bool success, ) = payable(payee).call{value: amount}("");
        require(success, "Transfer Failed");
    }

    /** To distribute fee and receivable amount to organization and receiver
     * respectively after a currency contribution is received
    */
    function completeNativeTansfer_(uint256 amount) internal {
        uint256 fee = amount / feeFactor;
        uint256 recievableAmount = amount - fee;
        transferNativeFunds_(recievableAmount, receiver);
        transferNativeFunds_(fee, Org());
        nativeContributions += amount;

        emit nativeContribution(
            address(this),
            msg.sender,
            recievableAmount
        );
    }

    // Simple functions to avoid code repetition to transfer ERC20 tokens
    function transferToken_(
        uint256 amount,
        address from,
        address payee,
        address token
    ) internal {
        IERC20(token).transferFrom(from, payee, amount);
    }

    /** To distribute fee and receivable amount to organization and receiver
     * respectively after an ERC20 token contribution is received
    */
    function completeTokenTansfer_(uint256 amount, address token, address from) internal {
        uint256 fee = amount / feeFactor;
        uint256 recievableAmount = amount - fee;
        transferToken_(recievableAmount, from, receiver, token);
        transferToken_(fee, from, Org(), token);
        tokenContributions[token] += amount;

        emit tokenContribution(
            address(this),
            msg.sender,
            recievableAmount,
            token
        );
    }

    /** To get the organization address
     *
     * Organization address is requested from an external contract incase if and
     * address change is required and the process to be simpler other than
     * changing the address on all contracts.
    */
    function Org() internal view returns(address){
         return IOwner(org).getOrg();
     }
}

