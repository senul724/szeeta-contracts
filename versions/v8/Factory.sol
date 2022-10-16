// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
import "./Examiner.sol";
import "./interfaces/IExaminer.sol";
import "./interfaces/IOwner.sol";

contract Factory {
    address org;
    address forwarder;
    address base;
    uint256 public feeFactor;

    // modifiers
    modifier onlyOrg() {
        require(msg.sender == Org(),"Caller Not Org!");
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
        address admin,
        address receiver,
        bytes32 salt,
        address[] calldata list
    ) external returns (address contractAddress) {
        require(msg.sender == forwarder,"Caller Not Forwarder!");
        contractAddress = clone(base, salt);
        IExaminer(contractAddress).initialize(
            forwarder,
            org,
            admin,
            receiver,
            feeFactor,
            list
        );

        emit Created(contractAddress, admin);
    }

    // Only Org
    function asignOrg(address newOrg) external onlyOrg {
        org = newOrg;
    }

    function asignForwarder(address newForwarder) external onlyOrg {
        forwarder = newForwarder;
    }

    function asignBase(address newBase) external onlyOrg {
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
        require(instance != address(0), "Cloning With Create2 Failed");
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
