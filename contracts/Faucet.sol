// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;
import "./IERC20.sol";
contract Faucet{
    uint256 public amountAllowed = 100;
    address public tokenContract;
    mapping(address=>bool) public requestAddress;
    event SendToken(address indexed Receiver, uint256 indexed Amount); 

    // 部署时设定ERC20代币合约
    constructor(address _tokenContract) {
        tokenContract = _tokenContract; // set token contract
    }
    function requestTokens() external {
        require(!requestAddress[msg.sender],"Can;t");
        IERC20 token = IERC20(tokenContract);
        token.transfer(msg.sender,amountAllowed);
        requestAddress[msg.sender]=true;
        emit SendToken(msg.sender, amountAllowed); // 释放SendToken事件
    }
}