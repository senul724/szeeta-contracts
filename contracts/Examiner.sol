// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./interfaces/IERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract Examiner is EIP712{
    using ECDSA for bytes32;
    // Address of the organization
    address org;
    // factor when calculating fees
    uint256 public feeFactor;

    // Structs
    struct Token{
        uint256 eventId;
        uint256 amount;
        address token;
        address receiver;
        uint256 time;
    }

    struct Native{
        uint256 eventId;
        address receiver;
        uint256 time;
    }

    // Typehash of the structs
    bytes32 private constant tokenTypeHash =
        keccak256(
            'Token(uint256 eventId,uint256 amount,address token,address receiver,uint256 time)'
        );

    bytes32 private constant nativeTypeHash =
        keccak256(
            'Native(uint256 eventId,address receiver,uint256 time)'
        );  

    //events
    event nativeContribution(
        uint256 indexed eventId,
        address indexed from,
        uint256 amount,
        uint256 fee
    );
    event tokenContribution(
        uint256 indexed eventId,
        address indexed from,
        address indexed token,
        uint256 amount,
        uint256 fee
    );

    constructor(uint fee, address org_) EIP712('szeeta', '0.0.1'){
        org = org_;
        feeFactor = fee;
    }

    // public functions
    function receiveTokenFunds(
        uint256 eventId,
        uint256 amount, 
        address token,
        address receiver,
        uint256 time,
        bytes calldata signature
    )
        external
        payable
    {
        require(validateToken(eventId, amount, token, receiver, time, signature));
        uint256 fee = amount / feeFactor;
        transferTokenFunds(amount - fee, msg.sender, receiver, token);
        transferTokenFunds(fee, msg.sender, org, token);
        emit tokenContribution(
            eventId,
            msg.sender,
            token,
            amount,
            fee
        );
    }

    function receiveNativeFunds(uint256 eventId, address receiver, uint256 time, bytes calldata signature) external payable{
        require(validateNative(eventId, receiver, time, signature));
        uint amount = msg.value;
        uint256 fee = amount / feeFactor;
        transferNativeFunds(amount - fee, receiver);
        emit nativeContribution(
            eventId,
            msg.sender,
            amount,
            fee
        );
    }

    // internal

    // Simple functions to avoid code repetition to transfer native currency
    function transferNativeFunds(uint256 amount, address payee) internal {
        (bool success, ) = payable(payee).call{value: amount}("");
        require(success, "Transfer Failed");
    }

    // Simple functions to avoid code repetition to transfer ERC20 tokens
    function transferTokenFunds(
        uint256 amount,
        address from,
        address payee,
        address token
    )
        internal
    {
        IERC20(token).transferFrom(from, payee, amount);
    }

    function validateToken(
        uint256 eventId, 
        uint256 amount, 
        address token,
        address receiver,
        uint256 time,
        bytes calldata signature
    )
        internal 
        view 
        returns(bool)
    {
        require(block.timestamp < time, "Transaction expired");
        return org == _hashTypedDataV4(
            keccak256(
                abi.encode(tokenTypeHash, eventId, amount, token, receiver, time)
            )
        ).recover(signature);
    }

    function validateNative(
        uint256 eventId, 
        address receiver,
        uint256 time,
        bytes calldata signature
    )
        internal 
        view 
        returns(bool)
    {
        require(block.timestamp < time, "Transaction expired");
        return org == _hashTypedDataV4(
            keccak256(
                abi.encode(nativeTypeHash, eventId, receiver, time)
            )
        ).recover(signature);
    }

    // All contributions are sent out of the contract instantly so that only the fee is collected in the contracts.
    // Value to withdraw is passed as and argument and not setting the amount to be contract balance is to avoid
    // any error due to order of execution 
    function withdraw(uint amount, address receiver) external{
        require(msg.sender == org);
        transferNativeFunds(amount, receiver);
    }

    function changeOrg(address newOrg) external {
        require(msg.sender == org);
        org = newOrg;
    }

    // utils
    function getTime() external view returns(uint256){
        return block.timestamp;
    }
}
