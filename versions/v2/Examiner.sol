// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";

contract Examiner is Initializable{
    address org;
    address receiver;
    address admin;
    address factory;

    uint256 feeFactor;
    uint256 immutable netId;

    // mappings
    mapping(address => bool) public allowedTokens;
    mapping(address => mapping(address => uint256)) public Tokencontributions;
    mapping(address => uint256) public nativeContributions;

    // modifiers
    modifier controlAccess(address authority) {
        require(msg.sender == authority);
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
        uint256 feeFactor_,
        address[] calldata allowedTokenList
    ) external initializer{
        for (uint256 i; i < allowedTokenList.length; i++) {
            allowedTokens[allowedTokenList[i]] = true;
        }
        org = org_;
        admin = admin_;
        receiver = receiver_;
        feeFactor = feeFactor_;
    }

    // public functions
    function receiveTokenFunds(uint256 amount, address token) external payable {
        require(IERC20(token).balanceOf(msg.sender) > 0);
        completeTokenTansfer_(amount, token);
    }

    // restricted
    function changeAdmin(address newAdmin) external controlAccess(admin) {
        admin = newAdmin;
    }

    function changeReceiver(address newReceiver) external controlAccess(admin) {
        receiver = newReceiver;
    }

    function allowToken(address token) external controlAccess(admin) {
        require(!allowedTokens[token]);
        allowedTokens[token] = true;
    }

    function disallowToken(address token) external controlAccess(admin) {
        require(
            allowedTokens[token] && IERC20(token).balanceOf(address(this)) <= 0
        );
        allowedTokens[token] = false;
    }

    function withdrawExternalTokenTransfers(address[] memory tokenList)
        external
        controlAccess(admin)
    {
        uint256 length = tokenList.length;
        for (uint256 i = 0; i < length; i++) {

            // adding local variable to save gas
            address tokenAddress = tokenList[i];
            address contractAddress = address(this);
            IERC20 token = IERC20(tokenAddress);

            if (token.balanceOf(contractAddress) > 0) {
                completeTokenTansfer_(
                    token.balanceOf(contractAddress),
                    tokenAddress
                );
            }
        }
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
        transferNativeFunds_(fee, org);
        nativeContributions[msg.sender] += amount;

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
        transferToken_(fee, org, token);
        Tokencontributions[token][msg.sender] += amount;

        emit tokenContribution(
            address(this),
            msg.sender,
            recievableAmount,
            token,
            netId
        );
    }

    /* //fallback and receive
    fallback() external payable {
        completeNativeTansfer_(address(this).balance);
    }

    receive() external payable {
        completeNativeTansfer_(address(this).balance);
    } */
}


// change

// * allowed tokens changed_ to calldata
// * factory variable added
// * controlled access of initialize funtion to factory only to avoid front running
