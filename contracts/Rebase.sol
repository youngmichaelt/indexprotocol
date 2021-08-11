pragma solidity ^0.8.0;

import "./lib/SafeMathInt.sol";
import "./lib/UInt256Lib.sol";

import "./IndexProtocol.sol";

import "./Oracle.sol";


contract Rebase is IndexProtocol {
    uint test;
    // uint256 public oracleMarket;
    // uint256 public oracleTarget;
    // using SafeMathInt for int256;
    // using UInt256Lib for uint256;

    // //event Rebase(address indexed caller, uint targetPrice, uint marketPrice, uint change);

    // function deltaChange(uint targetPrice, uint marketPrice) public returns (int){
        
    //     int change = (int(marketPrice) - int(targetPrice)) * 1000;
    //     change = (change / int(targetPrice));
    //     return change;
        
    //     // return (int(x) / 1000) * -500;
    // }
    
    
    
    // function rebasefunc(uint256 oracleMarket, uint256 oracleTarget) public returns (bool){
        
    //     // uint256 change = 1;
    //     uint256 supplyDelta;
    //     uint256 userDelta;
    //     uint256 targetPrice = 10;
    //     uint256 marketPrice = 9;
    //     int256 change;
    //     bool neg = false;
        
        
    //     uint timesAmount = 10**16;
    //     //oracleTarget = oracleTarget / timesAmount;
    //     //oracleMarket = oracleMarket / timesAmount;
    //     //oracleTarget = 10 * timesAmount;
    //     //oracleMarket = 5 * timesAmount;

    //     // uint256 oracleTarget = query();
    //     // uint256 oracleMarket;
        
        
    //     change = deltaChange(oracleTarget, oracleMarket);
        
    //     oracleTarget = oracleTarget / timesAmount;
    //     oracleMarket = oracleMarket / 10**14;
        
    //     if (change == 0){
    //         //No rebase needed
    //         return true;
    //     }
        
    //     if (change < 0) {
    //         change = change * -1;
    //         neg = true;
    //         }
        
    //     //emit Rebase(msg.sender, oracleTarget, oracleMarket, uint256(change.abs()));
            
    //     supplyDelta = uint256(change.abs());
    //     supplyDelta *= totalSupply;
    //     supplyDelta /= 1000;
    //     //supplyDelta /= timesAmount;
        
    //     //Split or merge token supply
    //     if (neg == true){
    //         totalSupply = totalSupply - supplyDelta;
    //     } else{
    //         totalSupply = totalSupply + supplyDelta;
    //     }
        
        
    //     //Split or merge user balance
    //     for (uint i = 0; i < holders.length; i++) {
            
    //         userDelta = uint256(change.abs());
    //         userDelta *= balances[holders[i]];
    //         userDelta /= 1000;
    //         //userDelta /= timesAmount;
       
    //         //rebase user supply
    //         if (neg == true){
    //             balances[holders[i]] = balances[holders[i]] - userDelta;
    //         } else{
    //             balances[holders[i]] = balances[holders[i]] + userDelta;
    //         }
            
    //     }
        
    //     return true;
    // }



}