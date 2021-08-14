pragma solidity ^0.5.16;

import "@chainlink/contracts/src/v0.5/ChainlinkClient.sol";
// import 'https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2Pair.sol';
import "@uniswap/v2-core/contracts/UniswapV2Pair.sol";


import "./IndexProtocol.sol";
import "./lib/SafeMathInt.sol";
import "./lib/UInt256Lib.sol";
//import "./Rebase.sol";

// import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";

// import '@uniswap/v3-core/contracts/libraries/TickMath.sol';

// import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol";

interface ISync {
    function sync() external;
}

contract Oracle is ChainlinkClient, IndexProtocol {

    using Chainlink for Chainlink.Request;
    // using SafeMathInt for int256;
    // using UInt256Lib for uint256;

    address private oracle;
    bytes32 private jobId;
    uint256 private fee;
 
    uint256 public price;
    uint256 public oracleMarket;
    uint256 public oracleTarget;
    uint256 public volume;

    address public uniswapV3PoolAddress;

    address public poolAddress;

    address public constant FACTORY = 0x1F98431c8aD98523631AE4a59f267346ea31F984;

    event Rebase(address indexed caller, uint targetPrice, uint marketPrice, uint change);

    constructor() public {

        setPublicChainlinkToken();
        oracle = 0x3A56aE4a2831C3d3514b5D7Af5578E45eBDb7a40;
        jobId = "3b7ca0d48c7a4b2da9268456665d11ae";
        fee = 0.1 * 10 ** 18; // 0.1 LINK

        uniswapV3PoolAddress = address(0xeeCac0f984c6b69888c63D681a1731c4aC79bDC9);

    }

    function query() public returns (bytes32 requestId) 
    {
        Chainlink.Request memory request = buildChainlinkRequest(jobId, address(this), this.fulfill.selector);
        
        request.add("get", "https://financialmodelingprep.com/api/v3/quote/%5ENDX?apikey=7680f981a245e422d16e1622b4bac07e");
        //request.add("get", "https://api.pancakeswap.info/api/v2/tokens/0x09ad270120d873a2b2fab0b01dff00c679880919");
        
        
        request.add("path", "0.price");
        
        
        
        // Multiply the result by 1000000000000000000 to remove decimals
        int timesAmount = 10**14;
        request.addInt("times", timesAmount);
        
        // Sends the request
        return sendChainlinkRequestTo(oracle, request, fee);
    }
    function fulfill(bytes32 _requestId, uint256 _price) public recordChainlinkFulfillment(_requestId)
    {
        oracleTarget = _price;
        price = _price;

        if (oracleTarget != 0){
            //oracleMarketPrice();
            //marketOracle(1,0,uniswapV3PoolAddress);
            callRebase();
        }

        
        
    }

    function callRebase() public {

        rebase(oracleTarget, oracleMarket);
    }


    function getTokenPrice(address pairAddress, uint amount, uint switchToken) public returns (bool)
       {
        IUniswapV2Pair pair = IUniswapV2Pair(pairAddress);

        poolAddress = pairAddress;
        //IERC20 token1 = IERC20(pair.token1);

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
        
        query();
        
        return true;
        //return((amount*res0)/Res1); // return amount of token0 needed to buy token1
       }
       
    function poolSync(address pool) public returns (bool){
        ISync(pool).sync();
        return true;
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
        //oracleTarget = oracleTarget / timesAmount;
        //oracleMarket = oracleMarket / timesAmount;
        //oracleTarget = 10 * timesAmount;
        //oracleMarket = 5 * timesAmount;

        // uint256 oracleTarget = query();
        // uint256 oracleMarket;

        //eth price 3000 
        oracleMarket *= 3000;
        //oracleMarket = oracleMarket * 10**10;
        
        
        change = deltaChange(oracleTarget, oracleMarket);
        
        // oracleTarget = oracleTarget / timesAmount;
        // // oracleMarket = oracleMarket / 10**14;
        // oracleMarket = oracleMarket / 10**11;

        
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
        //supplyDelta /= timesAmount;
        
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
            //userDelta /= timesAmount;
       
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