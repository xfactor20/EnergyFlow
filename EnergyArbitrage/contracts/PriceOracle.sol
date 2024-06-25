// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract PriceOracle {
    AggregatorV3Interface internal priceFeedUniswap;
    AggregatorV3Interface internal priceFeedSushiswap;

    constructor(address _priceFeedUniswap, address _priceFeedSushiswap) {
        priceFeedUniswap = AggregatorV3Interface(_priceFeedUniswap);
        priceFeedSushiswap = AggregatorV3Interface(_priceFeedSushiswap);
    }

    function getLatestPriceUniswap() public view returns (int) {
        (
            , 
            int price,
            ,
            ,
        ) = priceFeedUniswap.latestRoundData();
        return price;
    }

    function getLatestPriceSushiswap() public view returns (int) {
        (
            , 
            int price,
            ,
            ,
        ) = priceFeedSushiswap.latestRoundData();
        return price;
    }
}
