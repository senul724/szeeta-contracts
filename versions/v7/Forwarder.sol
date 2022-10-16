// SPDX-License-Identifier: MIT
// This is a customized OpenZeppelin Forwarder Contract according to a custom relayer

pragma solidity ^0.8.7;

import '@openzeppelin/contracts/utils/cryptography/ECDSA.sol';
import '@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol';
import './interfaces/IFactory.sol';
import './interfaces/IOwner.sol';
import './interfaces/IExaminer.sol';

contract Forwarder is EIP712 {
    using ECDSA for bytes32;

    /**Address of the Owner contract which the will be called for the address of
     * the organization
    */
    address org;
    // Address of the factory contract
    address factory;

    // Acts as a nonce counter for fundraiser creation
    mapping(address=>mapping(uint=>bool)) processed;

    // Acts as a nonce counter for admin calls
    mapping(address=>mapping(uint=>bool)) adminCalled;

    struct forwardData {
        address from;
        address receiver;
        bytes32 randomChar;
        uint256 nonce;
    }

    struct AdminCall {
        bytes32 message;
        address caller;
        uint256 callNonce;
    }

    bytes32 private constant typeHash =
        keccak256(
            'forwardData(address from,address receiver,bytes32 randomChar,uint256 nonce)'
        );

    bytes32 private constant adminTypeHash =
        keccak256(
            'AdminCall(bytes32 message,address caller,uint256 callNonce)'
        );

    modifier onlyOrg() {
        require(msg.sender == Org());
        _;
    }

    constructor(address org_, address factory_) EIP712('FundRaiser', '0.0.1') {
        org = org_;
        factory = factory_;
    }

    /** Function that verifies the sender and data(EIP712 standard) and calls
     * the factory for contract creation
    */
    function execute(
        forwardData calldata data,
        bytes calldata signature,
        address[] calldata tokenList
    ) external onlyOrg returns (address contractAddress) {
        require(verify(data, signature), 'Verification Failed!');

        contractAddress = IFactory(factory).createContract(
            data.from,
            data.receiver,
            data.randomChar,
            tokenList
        );

        // Keeps in-track of the processed transactions
        processed[data.receiver][data.nonce] = true;
    }

    /** As fundraisers are deployed in multiple networks we'll
     * allow admins of the fundraisers to interact with the contracts only
     * through the forwarder to avoid any conflicts
    */

    // To add or remove admins of the fundraiser
    function changeAdminStatus(
        address adminToChange,
        address examiner,
        AdminCall calldata data,
        bytes calldata signature
    ) external onlyOrg{

        examinerInstance(examiner, data, signature).changeAdminStatus(adminToChange);

        // Keeps in-track of processed admin interactions
        adminCalled[examiner][data.callNonce] = true;
    }

    // To change the address that receives the funds collected
    function changeReceiver(
        address newReceiver,
        address examiner,
        AdminCall calldata data,
        bytes calldata signature
    ) external onlyOrg{

        examinerInstance(examiner, data, signature).changeReceiver(newReceiver);
        adminCalled[examiner][data.callNonce] = true;

    }

    // To allow new ERC20 tokens to receive funds from
    function allowToken(
        address token,
        address examiner,
        AdminCall calldata data,
        bytes calldata signature
    ) external onlyOrg{

        examinerInstance(examiner, data, signature).allowToken(token);
        adminCalled[examiner][data.callNonce] = true;

    }

    // To close a fundraising event
    function close(
        address examiner,
        AdminCall calldata data,
        bytes calldata signature
    ) external onlyOrg{

        examinerInstance(examiner, data, signature).close();
        adminCalled[examiner][data.callNonce] = true;
    }

    // restricted
    function changeOrg(address newOrg) external onlyOrg{
            org = newOrg;
    }

    function changeFactory(address newFactory) external onlyOrg{
            factory = newFactory;
     }

     // Internal Functions

     // To verify the sender and data sent for fundraiser contract creation
     function verify(forwardData calldata data, bytes calldata signature)
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

    // To verify sender and data for admins to interact with contracts
    function verifyAdmin(AdminCall calldata data, bytes calldata signature)
        internal
        view
        returns(address)
    {
        address admin = _hashTypedDataV4(
            keccak256(
                abi.encode(adminTypeHash, data.message, data.caller, data.callNonce)
            )
        ).recover(signature);
        return admin;
    }

    // To Verify the admin and return a contract instance
    function examinerInstance(address examiner, AdminCall calldata data,bytes calldata signature) internal view returns(IExaminer){
        address callingAdmin = verifyAdmin(data, signature);
        IExaminer instance = IExaminer(examiner);
        require(instance.isAdmin(callingAdmin) && !adminCalled[examiner][data.callNonce]);

        return instance;
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
