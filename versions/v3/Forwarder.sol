// SPDX-License-Identifier: MIT
// This is a customized OpenZeppelin Forwarder Contract according to a custom relayer

pragma solidity ^0.8.7;

import '@openzeppelin/contracts/utils/cryptography/ECDSA.sol';
import '@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol';
import './interfaces/IFactory.sol';
import './interfaces/IOwner.sol';

contract Forwarder is EIP712 {
    using ECDSA for bytes32;

    address org;
    address factory;

    mapping(address=>mapping(uint=>bool)) processed;

    struct forwardData {
        address from;
        address receiver;
        bytes32 randomChar;
        uint256 target;
        uint256 nonce;
    }

    bytes32 private constant typeHash =
        keccak256(
            'forwardData(address from,address receiver,bytes32 randomChar,uint256 target,uint256 nonce)'
        );

    modifier onlyOrg() {
        require(msg.sender == Org());
        _;
    }

    constructor(address org_, address factory_) EIP712('FundRaiser', '0.0.1') {
        org = org_;
        factory = factory_;
    }

    function verify(forwardData calldata data, bytes calldata signature)
        internal
        view
        returns (bool)
    {
        address signer = _hashTypedDataV4(
            keccak256(
                abi.encode(typeHash, data.from, data.receiver, data.randomChar, data.target, data.nonce)
            )
        ).recover(signature);
        return signer == Org() && !processed[data.receiver][data.nonce];
    }

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
            data.target,
            tokenList
        );
        processed[data.receiver][data.nonce] = true;
    }

    function changeOrg(address newOrg) external onlyOrg{
            org = newOrg;
    }

    function changeFactory(address newFactory) external onlyOrg{
            factory = newFactory;
     }

     // Internal
     function Org() internal view returns(address){
         return IOwner(org).getOrg();
     }
}
