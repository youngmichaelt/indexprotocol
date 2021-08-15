# Index Protocol

The Index Protocol is a stablecoin pegged to the NASDAQ indicator. 

It allows users from any part of the world to invest in a decentralized blockchain currency instead of the stock market and have similar returns.

The Index Protocol also gives crypto users the ability to invest in a more stable currency, while not having to move their money off chain to a centralized entity.

## Rebase Strategy

To keep the price pegged to the NASDAQ indicator, INDX token is restructured/rebased after a specific amount of time.

During this restructure/rebase, the INDX protocol will split or merge INDX tokens based on target price of the NASDAQ and market prices of INDX token.

This restructuring of the supply of INDX tokens will influence market movements to stablize the price to the NASDAQ indicator. 

Target Price = NASDAQ indicator (14123ish) / 10,000 = $1.41 

## Oracles

Prices are found using the Uniswap V2 contracts as well as Chainlink oracles and price feeds. We have to use the Uniswap V2 contracts as the V3 contracts do not support all the features of a rebasible token. 

## Rebase Calculation Example:

Mike has 100 INDX tokens.
Market Price(mP): $2
Target Price(tP): $1

Change Calculation: (mP - tP)/ tP || (2 - 1) / 1 = 1

We find that the change is 1. Now, we can update the total supply as well as the supply of token holders based on this. 

change(c) = 1
Total Supply(tS) = 1000
Calculation: tS + (tS * c) || 1000 + (1000 * 1) = 2000

Now every token will be worth the target price ($1), half of the original market price ($2).

This calculation is the same for users tokens. 

change(c) = 1
User Supply(uS) = 100
Calculation: uS + (uS * c) || 100 + (100 * 1) = 200

Mike's tokens are now worth $1 each instead of $2, notice how he still retains the same total value. 



## To do(Development):
1. Clean up code. 
2. Add more oracles. 
3. Add token to more dexes and integrate in contracts. 
4. Test.
5. Remove hardcoded values.
6. Test more. 
7. Audit. 
8. Test more. 

## To do(General):
1. Feedback.
2. Testing with users.
3. Test gas prices.
4. Create webpage for general information.

