// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract TestToken is ERC20{
    
    constructor(address owner) ERC20("TestToken", "TT") {
      mint(owner, 100000000000);
    }

    function mint(address to, uint256 amount) public {
        _mint(to, amount);
    }
}
