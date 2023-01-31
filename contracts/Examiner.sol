// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.0;

import "./interfaces/IERC20.sol";
import "./openzeppalin-utils/SafeERC20.sol";
import "./openzeppalin-utils/EIP712.sol";

/**
 * @dev Examiner is a contract that facilitates effective contribution collection
 * with blockchain tech.
 *
 * Functionality of the contract is to receive contributions, validate the transactions,
 * deduct the fee and transfer the funds to the specific receiver.
 *
 * The contributions are sent to an event's receiving address where the event id and the 
 * receiving addresses are sent as arguments. Also, the transaction data is secured and 
 * validated using EIP712 and used nonces to avoid replaying and re-entrance.
 *
 * Contributions are accepted through the native currency of the network and ERC20 tokens
 * allowed by the organization.
 *
 * Governor address is responsible for changing sensitive information related to the organization
 * and withdrawing fees.
 */
contract Examiner is EIP712{
    /**
     *@dev SafeERC20 wrapper is used for ERC20 transactions.
     */
    using SafeERC20 for IERC20;

    /**
     * @dev Address of the organization.
     */
    address public org;

    /**
     * @dev Address of the organization.
     */
    address public governor;

    /**
     * @dev Method used to calculate the fee
     *
     * When the amount is divided by the fee factor, the quotient will be the fee.
     * Example: If the fee is 1%, feeFactor will be 100.
     */
    uint256 public feeFactor;

    // Keeps track of the processed transaction count
    uint256 private transactionCount;

    // Structs

    /**
     * @dev Used for validating data with EIP712 signature type when receiving
     * token contributions. 
     */
    struct Token{
        uint256 eventId;
        uint256 amount;
        uint256 usdAmount;
        address token;
        address receiver;
        uint256 nonce;
    }

    /**
     * @dev Used for validating data with EIP712 signature type when receiving
     * native currency contributions. 
     */
    struct Native{
        uint256 eventId;
        uint256 amount;
        uint256 usdAmount;
        address receiver;
        uint256 nonce;
    }

    /**
     *@dev Typehash of the structs to be used in the validation process mentioned above.
     */
    bytes32 private constant tokenTypeHash =
        keccak256(
            'Token(uint256 eventId,uint256 amount,uint256 usdAmount,address token,address receiver,uint256 nonce)'
        );

    bytes32 private constant nativeTypeHash =
        keccak256(
            'Native(uint256 eventId,uint256 amount,uint256 usdAmount,address receiver,uint256 nonce)'
        );  

    //events
    event NativeContribution(
        uint256 indexed eventId,
        address indexed from,
        uint256 amount,
        uint256 amountInUsd,
        uint256 fee
    );
    event TokenContribution(
        uint256 indexed eventId,
        address indexed from,
        address indexed token,
        uint256 amount,
        uint256 amountInUsd,
        uint256 fee
    );

    // modifiers
    modifier onlyGovernor(){
        require(msg.sender == governor, "Unauthorized Call!");
        _;
    }

    constructor(uint fee, address org_, address governor_) EIP712('szeeta', '0.0.1'){
        feeFactor = fee;
        org = org_;
        governor = governor_;
        transactionCount = 1;
    }

    // public functions

    /**
     * @dev About the receive functions
     *
     * The receive functions are the main functional components of the contract.
     * 
     * These functions receive contributions, validates the transaction(process is mentioned below)
     * and split the amount sending the amount to the receiver and deducting the fee. 
     *
     * For native currency contributions, the fee is collected in the contract for the organization to
     * withdraw and for ERC20 contributions the fee is transferred to the organization immediately.
     *
     * About ERC20 tokens, a list of popular tokens are selected by the organization and allowed.
     * Also we allow users to suggest tokens to allow.
     */
    
    /**
     * @dev Functions to validate ERC20 contributions.
     */
    function contributeToken(
        uint256 eventId,
        uint256 amount, 
        uint256 amountInUsd, 
        address token,
        address receiver,
        uint256 nonce,
        bytes calldata signature
    )
        external
        payable
    {
        require(
            validataSignatureForTokens(eventId, amount, amountInUsd, token, receiver, nonce, signature)
        );
        //incrementing the transaction count to mark it as processed
        transactionCount = nonce + 1;
        // calculating the fee
        uint256 fee = amount / feeFactor;
        transferTokenFunds(amount - fee, msg.sender, receiver, token);
        transferTokenFunds(fee, msg.sender, org, token);
        emit TokenContribution(
            eventId,
            msg.sender,
            token,
            amount,
            amountInUsd,
            fee
        );
    }

    /**
     * @dev Functions to receive native currency contributions.
     */
    function contribute(
        uint256 eventId,
        uint256 amount,
        uint256 amountInUsd,
        address receiver,
        uint256 nonce,
        bytes calldata signature
    )
         external
         payable
    {
        require(
            msg.value == amount &&
            validateSignature(eventId, amount, amountInUsd, receiver, nonce, signature)
        );
        //incrementing the transaction count to mark it as processed
        transactionCount = nonce + 1;
        uint256 fee = amount / feeFactor;
        transferNativeFunds(amount - fee, receiver);
        emit NativeContribution(
            eventId,
            msg.sender,
            amount,
            amountInUsd,
            fee
        );
    }

    // internal

    /**
     * @dev Simple function for transferring native contributions.
     * Mainly done to avoid code repetition.
     */
    function transferNativeFunds(uint256 amount, address payee) internal {
        (bool success, ) = payable(payee).call{value: amount}("");
        require(success, "Transfer Failed");
    }

    /**
     * @dev Simple function for transfering ERC20 contributions.
     * Mainly done to avoid code repetition.
     */
    function transferTokenFunds(
        uint256 amount,
        address from,
        address payee,
        address token
    )
        internal
    {
        IERC20(token).safeTransferFrom(from, payee, amount);
    }

    /**
     * @dev About the transactions validations
     *
     * We use transaction count as a nonce to avoid re-entrance or replaying.
     * And organizational signed EIP712 signature is used to avoid third-party method calls.
     */

    /**
     * @dev Functions to validate ERC20 contributions.
     */
    function validataSignatureForTokens(
        uint256 eventId, 
        uint256 amount, 
        uint256 amountInUsd, 
        address token,
        address receiver,
        uint256 nonce,
        bytes calldata signature
    )
        internal 
        view 
        returns(bool)
    {
        require(nonce >= transactionCount, "Transaction expired");
        bytes32 typedDataHash = _hashTypedDataV4(
            keccak256(
                abi.encode(tokenTypeHash, eventId, amount, amountInUsd, token, receiver, nonce)
            )
        );
        return org == ECDSA.recover(typedDataHash, signature);
    }

    /**
     * @dev Functions to validate native currency contributions.
     */
    function validateSignature(
        uint256 eventId, 
        uint256 amount,
        uint256 amountInUsd, 
        address receiver,
        uint256 nonce,
        bytes calldata signature
    )
        internal 
        view 
        returns(bool)
    {
        require(nonce >= transactionCount, "Transaction expired");
        bytes32 typedDataHash = _hashTypedDataV4(
            keccak256(
                abi.encode(nativeTypeHash, eventId, amount, amountInUsd, receiver, nonce)
            )
        );
        return org == ECDSA.recover(typedDataHash, signature);
    }

    // For organizational use

    /**
     * @dev All contributions are sent out of the contract immediately so that only the fee
     * is collected in the contracts.
     *
     * Value to withdraw is passed as an argument and not setting the amount to contract balance is to avoid
     * any errors due to order of execution 
     */
    function drain(uint amount) external onlyGovernor{
        transferNativeFunds(amount, governor);
    }

    /**
     * @dev restricted function to change organization address
     */
    function changeOrg(address newOrg) external onlyGovernor{
        org = newOrg;
    }

    /**
     * @dev restricted function to change governor address
     */
    function changeGovernor(address newGovernor) external onlyGovernor{
        governor = newGovernor;
    }
}
