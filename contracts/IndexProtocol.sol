pragma solidity ^0.8.6;

import "./lib/SafeMathInt.sol";
import "./lib/UInt256Lib.sol";


contract IndexProtocol {
    // using SafeMath for uint256;
    using SafeMathInt for int256;
    using UInt256Lib for uint256;
    
    mapping(address => uint) public balances;
    
    mapping(address => mapping(address => uint)) public allowance;
    
    address[] public holders;
    mapping (address => uint) index;
    
    uint public totalSupply = 100000 * 10 ** 18;
    string public name = "IndexProtocol";
    string public symbol = "INDX";
    uint public decimals = 18;
    
    uint public totalShares;
    uint public sharesPer;
    
    event Transfer(address indexed from, address indexed to, uint value);
    
    event Approval(address indexed owner, address indexed spender, uint value);
    
    constructor(){
        balances[msg.sender] = totalSupply;
        holders.push(msg.sender);
        index[msg.sender] = holders.length;
        // totalShares = totalSupply;
        // sharesPer = totalShares/totalSupply;
        // shareBalances[msg.sender] = totalShares;
        
        // balances[0xfC2782122A7870811bd5864Ea9C5c67F1d48e863] = 1000;
        // holders.push(0xfC2782122A7870811bd5864Ea9C5c67F1d48e863);
        // index[0xfC2782122A7870811bd5864Ea9C5c67F1d48e863] = holders.length;
    }
    
    function balanceOf(address owner) public view returns(uint){
        
        return balances[owner];
        
    }
    
    function transfer(address to, uint value) public returns(bool){
        
        require(balanceOf(msg.sender)>=value, 'balance too low');
        balances[to] += value;
        balances[msg.sender] -= value;
        
        // uint shareValue = value * sharesPer;
        // shareBalances[msg.sender] = shareBalances[msg.sender] - shareValue;
        // shareBalances[to] = shareBalances[to] + shareValue;
        
        if (!inArray(to)) {
            // Append
            index[to] = holders.length;
            holders.push(to);
        }
        
        
        
        emit Transfer(msg.sender, to, value);
        return true;
        
    }
    
    
    function transferFrom(address from, address to, uint value) public returns(bool){
        require(balanceOf(from) >= value, 'balance too low');
        require(allowance[from][msg.sender] >= value, 'allowance too low');
        balances[to] += value;
        balances[from] -= value;
        
        
        emit Transfer(from, to, value);
        return true;
    }
    
    function approve(address spender, uint value) public returns(bool){
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }
    
    
    
    function addAddress(address who) public returns (bool){
        
        if (!inArray(who)) {
            // Append
            index[who] = holders.length;
            holders.push(who);
        }
        
        return true;
    }
    
    function countAddress() public view returns (uint){
        return holders.length;
    }
    
   
    
    function inArray(address who) public view returns (bool) {
        // address 0x0 is not valid if pos is 0 is not in the array
        if (index[who] > 0) {
            return true;
        }
        return false;
    }
    
    function deltaChange(uint targetPrice, uint marketPrice) public returns (int){
        
        int change = (int(marketPrice) - int(targetPrice)) * 1000;
        change = (change / int(targetPrice));
        return change;
        
        // return (int(x) / 1000) * -500;
    }
    
    
    
    function rebase() public returns (bool){
        
        // uint256 change = 1;
        uint256 supplyDelta;
        uint256 userDelta;
        uint256 targetPrice = 20;
        uint256 marketPrice = 4;
        int256 change;
        bool neg = false;
        
        change = deltaChange(targetPrice, marketPrice);
        
        if (change == 0){
            //No rebase needed
            return true;
        }
        
        if (change < 0) {
            change = change * -1;
            neg = true;
            }
            
        supplyDelta = uint256(change.abs());
        supplyDelta *= totalSupply;
        supplyDelta /= 1000;
        
        //Split or merge token supply
        if (neg == true){
            totalSupply = totalSupply - supplyDelta;
        } else{
            totalSupply = totalSupply + supplyDelta;
        }
        
        
        //Split or merge user balance
        for (uint i = 0; i < holders.length; i++) {
            
            userDelta = uint256(change.abs());
            userDelta *= balances[holders[i]];
            userDelta /= 1000;
       
            //rebase user supply
            if (neg == true){
                balances[holders[i]] = balances[holders[i]] - userDelta;
            } else{
                balances[holders[i]] = balances[holders[i]] + userDelta;
            }
            
        }
        return true;
    }
    
    
    
}