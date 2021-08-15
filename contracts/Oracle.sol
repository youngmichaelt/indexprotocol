pragma solidity ^0.5.16;

import "@chainlink/contracts/src/v0.5/ChainlinkClient.sol";
import "@uniswap/v2-core/contracts/UniswapV2Pair.sol";
import "@chainlink/contracts/src/v0.5/interfaces/AggregatorV3Interface.sol";

import "./IndexProtocol.sol";
import "./lib/SafeMathInt.sol";
import "./lib/UInt256Lib.sol";


interface ISync {
    function sync() external;
}

contract Oracle is ChainlinkClient, IndexProtocol {

    using Chainlink for Chainlink.Request;
    using SafeMathInt for int256;
    using UInt256Lib for uint256;

    address private oracle;
    bytes32 private jobId;
    uint256 private fee;
 
    uint256 public price;
    uint256 public oracleMarket;
    uint256 public oracleTarget;
    uint256 public volume;

    address public uniswapV3PoolAddress;

    address public poolAddress;

    event Rebase(address indexed caller, uint targetPrice, uint marketPrice, uint change);

    AggregatorV3Interface internal priceFeed;

    constructor() public {

        setPublicChainlinkToken();

        //For testing
        oracle = 0x3A56aE4a2831C3d3514b5D7Af5578E45eBDb7a40;
        jobId = "3b7ca0d48c7a4b2da9268456665d11ae";
        fee = 0.1 * 10 ** 18; // 0.1 LINK

        //price feed
        priceFeed = AggregatorV3Interface(0x8A753747A1Fa494EC906cE90E9f37563A8AF630e);

    }

    function startRebase(address pairAddress, uint amount, uint switchToken) public {
        getMarketPrice(pairAddress, amount, switchToken);
    }

    function getMarketPrice(address pairAddress, uint amount, uint switchToken) public returns (bool)
       {
        IUniswapV2Pair pair = IUniswapV2Pair(pairAddress);

        poolAddress = pairAddress;

        uint Res1;
        uint Res0;

        if (switchToken == 0){
            (Res0, Res1,) = pair.getReserves();
        } else {
            (Res1, Res0,) = pair.getReserves();
        }

        // decimals
        uint res0 = Res0*(10**18);
        
        oracleMarket = ((amount*res0)/Res1);

        addAddress(pairAddress);
        
        getTargetPrice();
        
        return true;
       }

    function getTargetPrice() public returns (bytes32 requestId) 
    {
        Chainlink.Request memory request = buildChainlinkRequest(jobId, address(this), this.fulfill.selector);
        
        request.add("get", "https://financialmodelingprep.com/api/v3/quote/%5ENDX?apikey=7680f981a245e422d16e1622b4bac07e");        
        
        request.add("path", "0.price");
        
        // Multiply the result by 1000000000000000000 to remove decimals
        int timesAmount = 10**14;
        request.addInt("times", timesAmount);
        
        // Sends the request
        return sendChainlinkRequestTo(oracle, request, fee);
    }
    function fulfill(bytes32 _requestId, uint256 _targetPrice) public recordChainlinkFulfillment(_requestId)
    {
        oracleTarget = _targetPrice;
        //price = _price;

        if (oracleTarget != 0){
            
            callRebase();
        }

        
        
    }

    function callRebase() public {

        rebase(oracleTarget, oracleMarket);
    }

    function poolSync(address pool) public returns (bool){
        ISync(pool).sync();
        return true;
    }

    function getEthPrice() public view returns(int){
        (
            uint80 roundID, 
            int price,
            uint startedAt,
            uint timeStamp,
            uint80 answeredInRound
        ) = priceFeed.latestRoundData();
        return price;
    }

    function deltaChange(uint targetPrice, uint marketPrice) public returns (int){
        
        int change = (int(marketPrice) - int(targetPrice)) * 1000;
        change = (change / int(targetPrice));
        return change;
        
        // return (int(x) / 1000) * -500;
    }
    
    
    
    function rebase(uint256 oracleTarget, uint256 oracleMarket) public returns (bool){
        
        

        // uint256 change = 1;
        uint256 supplyDelta;
        uint256 userDelta;
        uint256 targetPrice = 10;
        uint256 marketPrice = 9;
        int256 change;
        bool neg = false;
        
        
        uint timesAmount = 10**18;
        

        //eth price 3000 
        //oracleMarket *= 3000;

        //get eth price
        int price = getEthPrice();
        price /= 10**8;
        oracleMarket *= uint256(price);
        
        
        change = deltaChange(oracleTarget, oracleMarket);

        
        if (change == 0){
            //No rebase needed
            return true;
        }
        
        if (change < 0) {
            change = change * -1;
            neg = true;
            }
        
        //emit Rebase(msg.sender, oracleTarget, oracleMarket, uint256(change.abs()));
            
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

        ISync(poolAddress).sync();
        
        return true;
    }

    

}