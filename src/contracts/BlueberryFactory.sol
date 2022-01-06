//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import './BlueberryExchange.sol';

contract BlueberryFactory is IFactory{
    address public override feeTo;
    address public feeToSetter;
  
    mapping(address => mapping(address => address)) public override getPair;
    address[] public allPairs;
    
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    constructor() {
        feeTo = msg.sender;
        feeToSetter = msg.sender;
    }

    function allPairsLength() external view returns (uint) {
        return allPairs.length;
    }
    
    function createPair(address _tokenA, address _tokenB) public override returns (address pair) {
        require(_tokenA != _tokenB, "createPair: IDENTICAL_ADDRESSES");
        (address token0, address token1) = _tokenA < _tokenB ? (_tokenA, _tokenB) : (_tokenB, _tokenA);
        require(token0 != address(0), 'createPair: ZERO_ADDRESS');
        require(
            getPair[token0][token1] == address(0),
            "PAIR already exists!"
        );

        bytes memory bytecode = type(BlueberryExchange).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(token0, token1));
        assembly {
            pair := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
        IExchange(pair).initialize(token0, token1);
        getPair[token0][token1] = address(pair);
        getPair[token1][token0] = address(pair);
        allPairs.push(pair);
        emit PairCreated(token0, token1, pair, allPairs.length);

    }

    function setFeeTo(address _feeTo) external override {
        require(msg.sender == feeToSetter, 'setFeeTo: FORBIDDEN');
        feeTo = _feeTo;
    }

    function setFeeToSetter(address _feeToSetter) external override {
        require(msg.sender == feeToSetter, 'setFeeToSetter: FORBIDDEN');
        feeToSetter = _feeToSetter;
    }

}

