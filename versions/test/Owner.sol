// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract Owner {

    address org;

    // modifiers
    modifier onlyOrg() {
        require(msg.sender == org);
        _;
    }

    constructor(address org_) {
        org = org_;
    }

    //  Functions
    function getOrg() external view returns(address){
        return org;
     }

    function reasignOrg(address newOrg) external onlyOrg {
        org = newOrg;
    }
}
