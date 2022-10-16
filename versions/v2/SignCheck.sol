// SPDX-License-Identifier: MIT
// This is a customized OpenZeppelin Forwarder Contract according to a custom relayer

pragma solidity ^0.8.7;

import '@openzeppelin/contracts/utils/cryptography/ECDSA.sol';
import '@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol';

contract SignCheck is EIP712 {
    using ECDSA for bytes32;
    address org;
    struct forwardData {
        address from;
        address receiver;
        bytes32  randomChar;  //here
        uint256 nonce;
    }

    bytes32 private constant typeHash =
        keccak256(
            'forwardData(address from,address receiver,bytes32 randomChar,uint256 nonce)' //here
        );

    constructor(address org_) EIP712('FundRaiser', '0.0.1') {
        org = org_;
    }

    function verify(forwardData calldata data, bytes calldata signature)
        internal
        view
        returns (address signer)
    {
        signer = _hashTypedDataV4(
            keccak256(
                abi.encode(typeHash, data.from, data.receiver, data.randomChar, data.nonce)
            )
        ).recover(signature);
    }

    function check(
        forwardData calldata data,
        bytes calldata signature,
        bytes calldata addresses
    ) external view returns (address signer, uint256 id, address orgy, address[] memory list) {
        signer = verify(data, signature);
        id  = block.chainid;
        orgy = org;
        list =  abi.decode(addresses, (address[]));
    }
}
