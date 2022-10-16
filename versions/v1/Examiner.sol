// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

contract Examiner {
    address org;
    address receiver;
    address admin;

    uint256 feeFactor;
    uint256 immutable netId;

    bool immutable isBase;
    bool initialized;

    // mappings
    mapping(address => bool) public allowedTokens;
    mapping(address => mapping(address => uint256)) public Tokencontributions;
    mapping(address => uint256) public nativeContributions;

    // modifiers
    modifier adminOnly() {
        require(msg.sender == admin);
        _;
    }

    modifier notBase() {
        require(!isBase);
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

    constructor() {
        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        netId = chainId;
        isBase = true;
    }

    function initialize(
        address org_,
        address receiver_,
        uint256 feeFactor_,
        address[] memory allowedTokenList
    ) external notBase {
        require(!initialized);
        for (uint256 i; i < allowedTokenList.length; i++) {
            allowToken(allowedTokenList[i]);
        }
        org = org_;
        receiver = receiver_;
        feeFactor = feeFactor_;
        initialized = true;
    }

    // public functions
    function receiveNativeFunds(uint256 amount) external payable notBase {
        require(msg.value == amount);
        completeNativeTansfer_(amount);
    }

    function receiveTokenFunds(uint256 amount, address token)
        external
        payable
        notBase
    {
        require(IERC20(token).balanceOf(msg.sender) > 0);
        completeTokenTansfer_(amount, token);
    }

    // restricted
    function changeAdmin(address newAdmin) external adminOnly notBase {
        admin = newAdmin;
    }

    function allowToken(address token) public adminOnly notBase {
        require(!allowedTokens[token]);
        allowedTokens[token] = true;
    }

    function disallowToken(address token) external adminOnly notBase {
        require(
            allowedTokens[token] && IERC20(token).balanceOf(address(this)) <= 0
        );
        allowedTokens[token] = false;
    }

    function withdrawExternalTokenTransfers(address[] memory tokenList)
        external
        adminOnly
        notBase
    {
        uint256 length = tokenList.length;
        for (uint256 i = 0; i < length; i++) {
            IERC20 token = IERC20(tokenList[i]);
            if (token.balanceOf(address(this)) > 0) {
                completeTokenTansfer_(
                    token.balanceOf(address(this)),
                    tokenList[i]
                );
            }
        }
    }

    // internal
    function transferNativeFunds_(uint256 amount, address payee) internal {
        (bool success, ) = payable(payee).call{value: amount}('');
        require(success, 'Transfer Failed');
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

    //fallback and receive
    fallback() external payable {
        completeNativeTansfer_(address(this).balance);
    }

    receive() external payable {
        completeNativeTansfer_(address(this).balance);
    }
}
