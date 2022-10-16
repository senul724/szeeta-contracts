// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import '@openzeppelin/contracts/utils/cryptography/ECDSA.sol';
import '@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol';
import './interfaces/IOwner.sol';
import './interfaces/IExaminer.sol';

contract Forwarder is EIP712 {
    using ECDSA for bytes32;
    /// @dev Address of the Owner contract which the will be called for the address of
    ///     the organization.
    address org;
    // Address of the base examiner contract
    address base;
    /// @dev Method used to calculate the fee
    ///     When the amount is devided by the fee factor, the quotient will be the fee.
    ///     example: If the fee is 1%, feeFactor will be 100
    uint feeFactor;
    // Acts as a nonce counter for fundraiser creation
    mapping(address=>mapping(uint=>bool)) processed;
    // Acts as a nonce counter for admin calls
    mapping(address=>mapping(uint=>bool)) adminCalled;

    struct ForwardData {
        address from;
        address receiver;
        bytes32 randomChar;
        uint256 nonce;
    }

    // Typehash of the struct ForwardData
    bytes32 private constant typeHash =
        keccak256(
            'ForwardData(address from,address receiver,bytes32 randomChar,uint256 nonce)'
        );

    // events
    event Created(address owner, address address_);

    // modifiers
    modifier onlyOrg() {
        require(msg.sender == Org(),"Caller Not Admin!");
        _;
    }

    constructor(address org_, address base_, uint256 fee) EIP712('FundRaiser', '0.0.1') {
        org = org_;
        base = base_;
        feeFactor = fee;
    }

    /// @dev Function that verifies the sender and data(EIP712 standard) and calls
    ///     the factory for contract creation.
    function execute(
        ForwardData calldata data,
        bytes calldata signature,
        address[] calldata tokenList
    )
        external
        onlyOrg
        returns (address contractAddress)
    {
        require(verify(data, signature), 'Verification Failed!');
        // Keeps in-track of the processed transactions
        processed[data.receiver][data.nonce] = true;
        // Calls the factory contracts and creates the contract instance
        contractAddress = createContract(
            data.from,
            data.receiver,
            data.randomChar,
            tokenList
        );
    }

    /// @dev As fundraisers are deployed in multiple networks we'll allow
    ///     admins of the fundraisers to interact with the contracts only
    ///     through the forwarder to avoid any conflicts.

    // To add or remove admins of the fundraiser
    function changeAdminStatus(
        address adminToChange,
        address caller,
        address examiner,
        uint256 nonce,
        bytes calldata signature
    )
        external
        onlyOrg
    {
        bytes32 messageHash = keccak256(abi.encodePacked(adminToChange, caller, examiner, nonce));
        // Keeps in-track of processed admin interactions
        adminCalled[examiner][nonce] = true;
        // Calling the examiner and changing the admin
        examinerInstance(examiner, nonce, messageHash, signature).changeAdminStatus(adminToChange);
    }

    // To change the address that receives the funds collected
    function changeReceiver(
        address newReceiver,
        address caller,
        address examiner,
        uint256 nonce,
        bytes calldata signature
    )
        external
        onlyOrg
    {
        bytes32 messageHash = keccak256(abi.encodePacked(newReceiver, caller, examiner, nonce));
        // Keeps in-track of processed admin interactions
        adminCalled[examiner][nonce] = true;
        // Calling the examiner to change the receiving address
        examinerInstance(examiner, nonce, messageHash, signature).changeReceiver(newReceiver);
    }

    // To allow new ERC20 tokens to receive funds
    function allowToken(
        address token,
        address caller,
        address examiner,
        uint256 nonce,
        bytes calldata signature
    )
        external
        onlyOrg
    {
        bytes32 messageHash = keccak256(abi.encodePacked(token, caller, examiner, nonce));
        // Keeps in-track of processed admin interactions
        adminCalled[examiner][nonce] = true;
        // Calling the examiner to change allow an ERC20 token
        examinerInstance(examiner, nonce, messageHash, signature).allowToken(token);
    }

    // To close a fundraising event
    function close(
        address caller,
        address examiner,
        uint256 nonce,
        bytes calldata signature
    )
        external
        onlyOrg
    {
        bytes32 messageHash = keccak256(abi.encodePacked(caller, examiner, nonce));
        // Keeps in-track of processed admin interactions
        adminCalled[examiner][nonce] = true;
        // Calling the examiner to close the instance
        examinerInstance(examiner, nonce, messageHash, signature).close();
    }

    // restricted
    function changeOrg(address newOrg) external onlyOrg{
        org = newOrg;
    }

     // Internal Functions

     // To verify the sender and data sent for fundraiser contract creation
     function verify(ForwardData calldata data, bytes calldata signature)
        internal
        view
        returns (bool)
    {
        address signer = _hashTypedDataV4(
            keccak256(
                abi.encode(typeHash, data.from, data.receiver, data.randomChar, data.nonce)
            )
        ).recover(signature);
        return signer == Org() && !processed[data.receiver][data.nonce];
    }

    // To Verify the admin and return a contract instance
    function examinerInstance(address examiner, uint256 nonce, bytes32 messageHash, bytes memory signature)
        internal
        view
        returns(IExaminer)
    {
        bytes32 ethSignedMessageHash = ECDSA.toEthSignedMessageHash(messageHash);
        address truCaller = ECDSA.recover(ethSignedMessageHash, signature);
        IExaminer instance = IExaminer(examiner);
        // Checking if the caller is a valid admin
        require(instance.isAdmin(truCaller) && !adminCalled[examiner][nonce], "Not Event Admin!");
        return instance;
    }

    /// @dev Organization address is requested from an external contract incase if and
    ///     address change is required and the process to be simpler other than
    ///     changing the address on all contracts.
     function Org() internal view returns(address){
        return IOwner(org).getOrg();
     }

     // Factory functions

     //  Contract Minter
    function createContract(
        address admin,
        address receiver,
        bytes32 salt,
        address[] calldata list
    )
        internal
        returns (address contractAddress)
    {
        contractAddress = clone(base, salt);
        IExaminer(contractAddress).initialize(
            address(this),
            org,
            admin,
            receiver,
            feeFactor,
            list
        );
        emit Created(contractAddress, admin);
    }

     // Function to clone the examiner instance (EIP1167)
    function clone(address base_, bytes32 salt)
        internal
        returns (address instance)
    {
        assembly {
            let ptr := mload(0x40)
            mstore(
                ptr,
                0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000
            )
            mstore(add(ptr, 0x14), shl(0x60, base_))
            mstore(
                add(ptr, 0x28),
                0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000
            )
            instance := create2(0, ptr, 0x37, salt)
        }
        require(instance != address(0), "Cloning With Create2 Failed");
    }
}
