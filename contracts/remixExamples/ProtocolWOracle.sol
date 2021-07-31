pragma solidity ^0.6.7;
import "@chainlink/contracts/src/v0.6/ChainlinkClient.sol";

import "./lib/SafeMathInt.sol";
import "./lib/UInt256Lib.sol";




contract IndexProtocol is ChainlinkClient{
    // using SafeMath for uint256;
    using SafeMathInt for int256;
    using UInt256Lib for uint256;
    
    mapping(address => uint) public balances;
    
    mapping(address => mapping(address => uint)) public allowance;
    
    address[] public holders;
    mapping (address => uint) index;
    
    uint public decimals = 18;
    uint public totalSupply = 100000 * 10 ** decimals;
    string public name = "IndexProtocol";
    string public symbol = "INDX";
    
    //oracle stuff
    uint256 public volume;
    uint256 public oracleMarket;
    uint256 public oracleTarget;
    
    address private oracle;
    bytes32 private jobId;
    uint256 private fee;
    
    
    uint public totalShares;
    uint public sharesPer;
    
    event Transfer(address indexed from, address indexed to, uint value);
    
    event Approval(address indexed owner, address indexed spender, uint value);
    
    constructor() public {
        balances[msg.sender] = totalSupply;
        holders.push(msg.sender);
        index[msg.sender] = holders.length;
        
        //oracle stuff 
        setPublicChainlinkToken();
        oracle = 0x3A56aE4a2831C3d3514b5D7Af5578E45eBDb7a40;
        jobId = "3b7ca0d48c7a4b2da9268456665d11ae";
        fee = 0.1 * 10 ** 18; // 0.1 LINK
        
        
        
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
        uint256 targetPrice = 10;
        uint256 marketPrice = 9;
        int256 change;
        bool neg = false;
        
        
        uint timesAmount = 10**15;
        oracleTarget = oracleTarget / timesAmount;
        oracleMarket = oracleMarket / timesAmount;
        
        
        change = deltaChange(oracleTarget, oracleMarket);
        
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
    
    //oracle stuff
    function startRebase() public returns (bytes32 requestId) 
    {
        Chainlink.Request memory request = buildChainlinkRequest(jobId, address(this), this.fulfill.selector);
        
        
        request.add("get", "https://api.pancakeswap.info/api/v2/tokens/0x09ad270120d873a2b2fab0b01dff00c679880919");
        
        
        request.add("path", "data.price");
        
        // Multiply the result by 1000000000000000000 to remove decimals
        int timesAmount = 10**18;
        request.addInt("times", timesAmount);
        
        // Sends the request
        return sendChainlinkRequestTo(oracle, request, fee);
    }
    function fulfill(bytes32 _requestId, uint256 _volume) public recordChainlinkFulfillment(_requestId)
    {
        oracleTarget = _volume;
        volume = _volume;
        if (oracleTarget != 0){
            oracleMarketPrice();
        }
        
    }
    function oracleMarketPrice() public returns (bytes32 requestId) 
    {
        Chainlink.Request memory request = buildChainlinkRequest(jobId, address(this), this.fulfillMarket.selector);
        
        
        request.add("get", "https://api.pancakeswap.info/api/v2/tokens/0x7130d2A12B9BCbFAe4f2634d864A1Ee1Ce3Ead9c");
        
        
        request.add("path", "data.price");
        
        // Multiply the result by 1000000000000000000 to remove decimals
        int timesAmount = 10**18;
        request.addInt("times", timesAmount);
        
        // Sends the request
        return sendChainlinkRequestTo(oracle, request, fee);
    }
    function fulfillMarket(bytes32 _requestId, uint256 _volume) public recordChainlinkFulfillment(_requestId)
    {
        oracleMarket = _volume;
        volume = _volume;
        if (oracleMarket != 0){
            rebase();
        }
        
    }
    
    
    
}