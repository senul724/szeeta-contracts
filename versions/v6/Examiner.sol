// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "./interfaces/IOwner.sol";


contract Examiner is Initializable{
    address public org;
    address public receiver;
    address public factory;
    address public forwarder;

    uint256 public netId;
    uint256 feeFactor;
    uint256 public nativeContributions;

    bool public closed;

    // mappings
    mapping(address => bool) public admin;
    mapping(address => uint256) public tokenContributions;
    mapping(address => bool) public allowedTokens;

    // modifiers
    modifier controlAccess(address authority) {
        require(msg.sender == authority);
        _;
    }
    modifier notClosed(){
        require(!closed);
        _;
        }

    //events
    event nativeContribution(
        address _contract,
        address from,
        uint256 amount,
        uint256 netID_
    );
    event tokenContribution(
        address _contract,
        address from,
        uint256 amount,
        address token,
        uint256 netId_
    );

    // Acts as the contructor for clones
    function initialize(
        address factory_,
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
        factory = factory_;
        forwarder = forwarder_;
        org = org_;
    }

    // public functions
    function receiveTokenFunds(uint256 amount, address token) external payable notClosed{
        completeTokenTansfer_(amount, token);
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
    function transferNativeFunds_(uint256 amount, address payee) internal {
        (bool success, ) = payable(payee).call{value: amount}("");
        require(success, "Transfer Failed");
    }

    function completeNativeTansfer_(uint256 amount) internal {
        uint256 fee = amount / feeFactor;
        uint256 recievableAmount = amount - fee;
        transferNativeFunds_(recievableAmount, receiver);
        transferNativeFunds_(fee, Org());
        nativeContributions += amount;

        emit nativeContribution(
            address(this),
            msg.sender,
            recievableAmount,
            netId
        );
    }

    function transferToken_(
        uint256 amount,
        address payee,
        address token
    ) internal {
        require(allowedTokens[token]);
        IERC20(token).transfer(payee, amount);
    }

    function completeTokenTansfer_(uint256 amount, address token) internal {
        uint256 fee = amount / feeFactor;
        uint256 recievableAmount = amount - fee;
        transferToken_(amount, receiver, token);
        transferToken_(fee, Org(), token);
        tokenContributions[token] += amount;

        emit tokenContribution(
            address(this),
            msg.sender,
            recievableAmount,
            token,
            netId
        );
    }

    function Org() internal view returns(address){
         return IOwner(org).getOrg();
     }
}
