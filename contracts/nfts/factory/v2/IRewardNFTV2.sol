// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.0;

interface IRewardNFTV2{
    function initialize( address eventOwner, address admin, string memory name, string memory symbol, string memory uri) external;
}
