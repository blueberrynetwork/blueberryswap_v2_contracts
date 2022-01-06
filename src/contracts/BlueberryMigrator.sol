// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import './interfaces/IExchange.sol';
import './interfaces/IFactory.sol';


contract BlueberryMigrator {
    address public chef;
    address public oldFactory;
    IFactory public factory;
    uint256 public notBeforeBlock;
    uint256 public desiredLiquidity = type(uint128).max;

    constructor(
        address _chef
    )  {
        chef = _chef;
    }

    function setFactoryProperties(uint256 _notBeforeBlock, address _oldFactory, IFactory _factory) public returns(IFactory) {
        require(msg.sender == chef, "not from master chef");
        oldFactory = _oldFactory;
        factory = _factory;
        notBeforeBlock = _notBeforeBlock;
        return factory;
    }

    function migrate(IExchange orig) public returns (IExchange) {
        require(msg.sender == chef, "not from master chef");
        require(block.number >= notBeforeBlock, "too early to migrate");
        require(orig.factory() == oldFactory, "not from old factory");
        address token0 = orig.token0();
        address token1 = orig.token1();
        IExchange pair = IExchange(factory.getPair(token0, token1));
        if (pair == IExchange(address(0))) {
            pair = IExchange(factory.createPair(token0, token1));
        }
        uint256 lp = orig.balanceOf(msg.sender);
        if (lp == 0) return pair;
        desiredLiquidity = lp;
        orig.transferFrom(msg.sender, address(orig), lp);
        orig.burn(address(pair));
        pair.mint(msg.sender);
        desiredLiquidity = type(uint128).max;
        return pair;
    }
}