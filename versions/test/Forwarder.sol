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

    address org;
    address factory;

    mapping(address=>mapping(uint=>bool)) processed;
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

    function execute(
       address from,
       address receiver,
       bytes32 randomChar,
       address[] calldata tokenList
    ) external onlyOrg returns (address contractAddress) {
        /* require(verify(data, signature), 'Verification Failed!'); */

        contractAddress = IFactory(factory).createContract(
            from,
            receiver,
            randomChar,
            tokenList
        );
        /* processed[data.receiver][data.nonce] = true; */
    }
    /* function execute(
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
        processed[data.receiver][data.nonce] = true;
    } */

    // admin functions
    function changeAdminStatus(
        address adminToChange,
        address examiner,
        AdminCall calldata data,
        bytes calldata signature
    ) external onlyOrg{

        examinerInstance(examiner, data, signature).changeAdminStatus(adminToChange);
        adminCalled[examiner][data.callNonce] = true;
    }

    function changeReceiver(
        address newReceiver,
        address examiner,
        AdminCall calldata data,
        bytes calldata signature
    ) external onlyOrg{

        examinerInstance(examiner, data, signature).changeReceiver(newReceiver);
        adminCalled[examiner][data.callNonce] = true;

    }

    function allowToken(
        address token,
        address examiner,
        AdminCall calldata data,
        bytes calldata signature
    ) external onlyOrg{

        examinerInstance(examiner, data, signature).allowToken(token);
        adminCalled[examiner][data.callNonce] = true;

    }

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

     // Internal
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

    function examinerInstance(address examiner, AdminCall calldata data,bytes calldata signature) internal view returns(IExaminer){
        address callingAdmin = verifyAdmin(data, signature);
        IExaminer instance = IExaminer(examiner);
        require(instance.isAdmin(callingAdmin) && !adminCalled[examiner][data.callNonce]);

        return instance;
    }

     function Org() internal view returns(address){
         return IOwner(org).getOrg();
     }
}
