pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/ChainlinkClient.sol";

import "./IndexProtocol.sol";
import "./lib/SafeMathInt.sol";
import "./lib/UInt256Lib.sol";
//import "./Rebase.sol";

import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";

import '@uniswap/v3-core/contracts/libraries/TickMath.sol';

import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol";

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
        int timesAmount = 10**16;
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
            marketOracle(1,0,uniswapV3PoolAddress);
        }

        
        
    }

    function oracleMarketPrice() public returns (bytes32 requestId) 
    {
        Chainlink.Request memory request = buildChainlinkRequest(jobId, address(this), this.fulfillMarket.selector);
        
        //https://financialmodelingprep.com/api/v3/quote/%5ENDX?apikey=7680f981a245e422d16e1622b4bac07e
        //request.add("get", "https://api.pancakeswap.info/api/v2/tokens/0x7130d2A12B9BCbFAe4f2634d864A1Ee1Ce3Ead9c");
        
        
        request.add("get", "https://api.pancakeswap.info/api/v2/tokens/0x09ad270120d873a2b2fab0b01dff00c679880919");
        
        
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

        // rebasefunction(oracleTarget, oracleMarket);
        if (oracleMarket != 0){
            rebasefunction(oracleTarget, oracleMarket);
        }
        
    }

    

    function marketOracle(uint32 s0, uint32 s1, address pool) public returns(uint160){

        if (pool == address(0x0)){
            pool = 0xeeCac0f984c6b69888c63D681a1731c4aC79bDC9;
        } 

        IUniswapV3Pool uniswapv3Pool = IUniswapV3Pool(pool);
        
        uint32[] memory secondAgos = new uint32[](2);
        secondAgos[0] = s0;
        secondAgos[1] = s1;
        
        //return secondAgos[0];
        
        (int56[] memory tickCumulatives, uint160[] memory test) = uniswapv3Pool.observe(secondAgos);
        
        int56 tickCumulativesDiff = tickCumulatives[1] - tickCumulatives[0];
        uint56 period = uint56(secondAgos[0]-secondAgos[1]);

        int56 timeWeightedAverageTick = (tickCumulativesDiff / -int56(period));

        //price = 1.0001 ** timeWeightedAverageTick;
        uint160 sqrtRatioX96 = TickMath.getSqrtRatioAtTick(int24(timeWeightedAverageTick));
        //uint160 sqrtRatioX96 = TickMath.getSqrtRatioAtTick(int24(-46087));
        
        uint160 temp = sqrtRatioX96 * 100000;
        
        uint160 ex = (2 ** 96);
        
        uint160 next = temp / ex;
        
        uint160 last = next ** 2;
        
        
        oracleMarket = last * 100;
        callRebase();
        // uint256 ratioX192 = uint256(sqrtRatioX96) * sqrtRatioX96;
        // price = uint32((ratioX192 * 1e18) >> (96 * 2));

        return last;

    }

    function callRebase() public {

        rebasefunction(oracleTarget, oracleMarket);
    }

    

    function getPool(address token1, address token2) external view returns (address) {
      address pair = IUniswapV3Factory(FACTORY).getPool(token1,token2,3000);
      return pair;

}

    

}