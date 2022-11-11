// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

interface IRewardNFT{
    function close() external;
    function transferOwnership(address newOwner) external;
}
