pragma solidity ^0.5.16;

import "./lib/SafeMathInt.sol";
import "./lib/UInt256Lib.sol";




contract IndexProtocol {

    using SafeMathInt for int256;
    using UInt256Lib for uint256;

    mapping(address => uint) public balances;

    mapping(address => mapping(address => uint)) public allowance;

    //Holders of token
    address[] public holders;
    mapping (address => uint) index;
    
    uint public decimals = 18;
    uint public totalSupply = 100000 * 10 ** decimals;
    string public name = "IndexProtocol";
    string public symbol = "INDX";

    event Transfer(address indexed from, address indexed to, uint value);
    
    event Approval(address indexed owner, address indexed spender, uint value);

    constructor() public {

        balances[msg.sender] = totalSupply;
        holders.push(msg.sender);
        index[msg.sender] = holders.length;

    }

    function balanceOf(address owner) public view returns(uint){
        
        return balances[owner];
        
    }

    function transfer(address to, uint value) public returns(bool){
        
        require(balanceOf(msg.sender)>=value, 'balance too low');
        balances[to] += value;
        balances[msg.sender] -= value;
        
        //Used to track holders of token
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

    

}