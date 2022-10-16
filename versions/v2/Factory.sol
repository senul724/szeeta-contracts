// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
import "./Examiner.sol";
import "./interfaces/IExaminer.sol";

contract Factory {
    address org;
    address forwarder;
    address base;
    uint256 public feeFactor;

    // modifiers
    modifier controlAccess(address authority) {
        require(msg.sender == authority);
        _;
    }

    // events
    event Created(address owner, address address_);

    constructor(
        uint256 fee_,
        address org_
    ) {
        org = org_;
        feeFactor = fee_;
    }

    //  Contract Minter
    function createContract(
        address admin_,
        address receiver_,
        /* bytes32 randomChar_, */
        bytes32 salt,
        address[] calldata list_
    ) external controlAccess(forwarder) returns (address contractAddress) {
        /* bytes32 salt = keccak256(abi.encode(randomChar_)); */
        contractAddress = clone(base, salt);
        IExaminer(contractAddress).initialize(
            org,
            admin_,
            receiver_,
            feeFactor,
            list_
        );
        emit Created(contractAddress, admin_);
    }

    // Only Org
    function reasignOrg(address newOrg) external controlAccess(org) {
        org = newOrg;
    }

    function asignForwarder(address newForwarder) external controlAccess(org) {
        forwarder = newForwarder;
    }

    function asignBase(address newBase) external controlAccess(org) {
        base = newBase;
    }

    function changeBase(address newBase) external controlAccess(org) {
        base = newBase;
    }

    // internal
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
        require(instance != address(0), "Cloning With create2 Failed");
    }
}

// changes

// * changed_ address[] to calldata
