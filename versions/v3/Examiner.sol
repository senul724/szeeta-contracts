// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "./interfaces/IOwner.sol";

contract Examiner is Initializable{
    address org;
    address receiver;
    address admin;
    address factory;

    uint256 immutable netId;
    uint256 feeFactor;
    uint256 public nativeContributions;
    uint256 public target; // This will in the usd value of the target
    uint256 public filledAmount; // This will in the usd value of the target

    bool public closed;

    // mappings
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

    constructor(address factory_) {
        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        netId = chainId;
        factory = factory_;
    }

    function initialize(
        address org_,
        address admin_,
        address receiver_,
        uint256 target_,
        uint256 feeFactor_,
        address[] calldata allowedTokenList
    ) external initializer{
        for (uint256 i; i < allowedTokenList.length; i++) {
            allowedTokens[allowedTokenList[i]] = true;
        }
        org = org_;
        admin = admin_;
        receiver = receiver_;
        target = target_;
        feeFactor = feeFactor_;
    }

    // public functions
    function receiveTokenFunds(uint256 amount, uint256 value,  address token) external payable notClosed{
        require(IERC20(token).balanceOf(msg.sender) >= amount);
        completeTokenTansfer_(amount, token);
        targetCheck_(value);
    }

    function receiveNativeFunds(uint256 value) external payable notClosed{
            completeNativeTansfer_(msg.value);
            targetCheck_(value);
      }

    // restricted
    function changeAdmin(address newAdmin) external controlAccess(admin) notClosed{
        admin = newAdmin;
    }

    function changeReceiver(address newReceiver) external controlAccess(admin) notClosed{
        receiver = newReceiver;
    }

    function allowToken(address token) external controlAccess(admin) notClosed{
        require(!allowedTokens[token]);
        allowedTokens[token] = true;
    }

    function disallowToken(address token) external controlAccess(admin) notClosed{
        require(allowedTokens[token] && tokenContributions[token] == 0);
        allowedTokens[token] = false;
    }

    function close() external notClosed controlAccess(admin){
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

    function targetCheck_(uint256 amount) internal{
        if(amount+filledAmount >= target){
            filledAmount = target;
            closed = true;
        }else{
            filledAmount += amount;
        }
    }

    function Org() internal view returns(address){
         return IOwner(org).getOrg();
     }
}
