// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./interfaces/IERC20.sol";
import "./openzeppalin-utils/SafeERC20.sol";
import "./openzeppalin-utils/EIP712.sol";

/**
 * @dev Examiner is a contract which facilitate effective contribution collection
 * with blockchain tech.
 *
 * Functionality of the contract is to recieve contributions, validate the transactions,
 * deduct the fee and transfer the funds to the specific reciever.
 *
 * The contributions are sent to an event's receiving address where the event id and the 
 * receiving address are sent as arguments. Also the transaction data is sucured and 
 * validated using EIP712 and replaying is avoided with time expiration.
 *
 * Contributions are accepted through native currency of the network and ERC20 tokens
 * allowed by the organization.
 *
 * Governer address is responsible for changing sensitive information realted to the organization
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
    address private governer;

    /**
     * @dev Method used to calculate the fee
     *
     * When the amount is devided by the fee factor, the quotient will be the fee.
     * example: If the fee is 1%, feeFactor will be 100.
     */
    uint256 public feeFactor;

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
        uint256 time;
    }

    /**
     * @dev Used for validating data with EIP712 signature type when receiving
     * native currency contributions. 
     */
    struct Native{
        uint256 eventId;
        uint256 usdAmount;
        address receiver;
        uint256 time;
    }

    /**
     *@dev Typehash of the structs to be used in the validation process mentioned above.
     */
    bytes32 private constant tokenTypeHash =
        keccak256(
            'Token(uint256 eventId,uint256 amount,uint256 usdAmount,address token,address receiver,uint256 time)'
        );

    bytes32 private constant nativeTypeHash =
        keccak256(
            'Native(uint256 eventId,uint256 usdAmount,address receiver,uint256 time)'
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
    modifier onlyGoverner(){
        require(msg.sender == governer, "Unauthorized Call!");
        _;
    }

    constructor(uint fee, address org_, address governer_) EIP712('szeeta', '0.0.1'){
        feeFactor = fee;
        org = org_;
        governer = governer_;
    }

    // public functions

    /**
     * @dev About the recieve funcitions
     *
     * The receive functions are main functional components of the contract.
     * 
     * These functions receive contributions, validates the transaction(process is metioned below)
     * and split the amount sending the amount to the receiver deducting the fee. 
     *
     * For native currency contributions, the fee is collected in contract for organization to
     * withdraw and for ERC20 contributions the fee is transferd to the organization immediatly.
     *
     * About ERC20 tokens, a list of popular tokena are seleceted by the organization and allowed.
     * Also we allow users to suggest token to allow.
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
        uint256 time,
        bytes calldata signature
    )
        external
        payable
    {
        require(validataSignatureForTokens(eventId, amount, amountInUsd, token, receiver, time, signature));
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
        uint256 amountInUsd,
        address receiver,
        uint256 time,
        bytes calldata signature
    )
         external
         payable
    {
        require(validateSignature(eventId, amountInUsd, receiver, time, signature));
        uint amount = msg.value;
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
     * @dev Simple function for transfering native contributions.
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
     * We use time to expire transactions other than managing a nonce.
     * The main reason for this is the lower the gas fee of the user because it takes about
     * 20k gas to update a bolean state of a nonce.
     * Since are main goal is to compete with normal gas fee for a transactions (approximately 21k gas)
     * we are using time for validation.
     *
     * How we do that is we take the block timestamp when the user sends out the transaction and add a
     * reasonable time considering the average mining time of a block of the specific network and set it
     * as the expiration time.
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
        uint256 time,
        bytes calldata signature
    )
        internal 
        view 
        returns(bool)
    {
        require(block.timestamp < time, "Transaction expired");
        bytes32 typedDataHash = _hashTypedDataV4(
            keccak256(
                abi.encode(tokenTypeHash, eventId, amount, amountInUsd, token, receiver, time)
            )
        );
        return org == ECDSA.recover(typedDataHash, signature);
    }

    /**
     * @dev Functions to validate native currency contributions.
     */
    function validateSignature(
        uint256 eventId, 
        uint256 amountInUsd, 
        address receiver,
        uint256 time,
        bytes calldata signature
    )
        internal 
        view 
        returns(bool)
    {
        require(block.timestamp < time, "Transaction expired");
        bytes32 typedDataHash = _hashTypedDataV4(
            keccak256(
                abi.encode(nativeTypeHash, eventId, amountInUsd, receiver, time)
            )
        );
        return org == ECDSA.recover(typedDataHash, signature);
    }

    // For organizational use

    /**
     * @dev All contributions are sent out of the contract immediatly so that only the fee
     * is collected in the contracts.
     *
     * Value to withdraw is passed as and argument and not setting the amount to be contract balance is to avoid
     * any errors due to order of execution 
     */
    function drain(uint amount) external onlyGoverner{
        transferNativeFunds(amount, governer);
    }

    /**
     * @dev restricted function to change organization address
     */
    function changeOrg(address newOrg) external onlyGoverner{
        org = newOrg;
    }

    /**
     * @dev restricted function to change governer address
     */
    function changeGoverner(address newGoverner) external onlyGoverner{
        governer = newGoverner;
    }

    // utils

    /**
     * @dev simple function to get block timestamp.
     * Timestamps are used to validate transactions as mentioned above 
     */
    function getTime() external view returns(uint256){
        return block.timestamp;
    }
}
