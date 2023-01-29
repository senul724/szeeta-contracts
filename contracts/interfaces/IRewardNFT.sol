// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.0;

interface IRewardNFT{
    function close() external;
    function mint(address contributor) external returns(uint256);
    function transferOwnership(address newOwner) external;
}
