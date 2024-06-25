// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "https://github.com/Uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol";
import "https://github.com/Uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import "https://github.com/Uniswap/v3-core/contracts/interfaces/callback/IUniswapV3FlashCallback.sol";
import "https://github.com/Uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";
import "https://github.com/Uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/ReentrancyGuard.sol";
// import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/security/ReentrancyGuard.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol";
import "./PriceOracle.sol";

interface ISushiSwapRouter {
    function getAmountsOut(uint256 amountIn, address[] calldata path) external view returns (uint256[] memory amounts);
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);
}

contract EnergyArbitrage is IUniswapV3FlashCallback, ReentrancyGuard, Ownable {
    IUniswapV3Factory public factory;
    ISwapRouter public uniswapRouter;
    ISushiSwapRouter public sushiswapRouter;
    PriceOracle public priceOracle;
    address public WETH;
    address public DAI;
    uint24 public poolFee;
    uint256 public slippageTolerance; // slippage tolerance in basis points (e.g., 50 = 0.5%)

    event ArbitrageExecuted(address indexed sender, uint256 profit);

    constructor(
        address _factory,
        address _uniswapRouter,
        address _sushiswapRouter,
        address _priceOracle,
        address _WETH,
        address _DAI,
        uint24 _poolFee,
        uint256 _slippageTolerance
    ) {
        factory = IUniswapV3Factory(_factory);
        uniswapRouter = ISwapRouter(_uniswapRouter);
        sushiswapRouter = ISushiSwapRouter(_sushiswapRouter);
        priceOracle = PriceOracle(_priceOracle);
        WETH = _WETH;
        DAI = _DAI;
        poolFee = _poolFee;
        slippageTolerance = _slippageTolerance;
    }

    function uniswapV3FlashCallback(
        uint256 fee0,
        uint256 fee1,
        bytes calldata data
    ) external override nonReentrant {
        // Ensure this function is called only by Uniswap V3 pool
        address pool = abi.decode(data, (address));
        require(msg.sender == pool, "Unauthorized");

        // Execute the arbitrage logic
        uint256 profit = executeArbitrageLogic();

        // Repay the flash loan
        if (fee0 > 0) {
            TransferHelper.safeTransfer(WETH, msg.sender, fee0);
        }
        if (fee1 > 0) {
            TransferHelper.safeTransfer(WETH, msg.sender, fee1);
        }

        // Emit event with profit details
        emit ArbitrageExecuted(msg.sender, profit);
    }

    function executeArbitrage(
        uint256 amount0,
        uint256 amount1
    ) external onlyOwner {
        address pool = factory.getPool(WETH, DAI, poolFee);
        require(pool != address(0), "Pool does not exist");

        IUniswapV3Pool(pool).flash(address(this), amount0, amount1, abi.encode(pool));
    }

    function executeArbitrageLogic() internal returns (uint256) {
        // Calculate the optimal amount for arbitrage
        uint256 amountIn = calculateArbitrageAmount();

        // Get dynamic prices from Chainlink Oracles
        int priceUniswap = priceOracle.getLatestPriceUniswap();
        int priceSushiswap = priceOracle.getLatestPriceSushiswap();

        // Ensure prices are valid
        require(priceUniswap > 0 && priceSushiswap > 0, "Invalid prices from oracles");

        // Determine slippage limits
        uint256 minAmountOut = (amountIn * (10000 - slippageTolerance)) / 10000;

        // Determine which way to perform the arbitrage
        uint256 profit;
        if (uint256(priceUniswap) > uint256(priceSushiswap)) {
            // Perform arbitrage from Sushiswap to Uniswap
            uint256 amountOut1 = swapExactTokensForTokens(amountIn, WETH, DAI, sushiswapRouter, minAmountOut);
            uint256 amountOut2 = swapExactInputSingle(DAI, WETH, amountOut1, uniswapRouter, minAmountOut);
            profit = amountOut2 - amountIn;
        } else if (uint256(priceSushiswap) > uint256(priceUniswap)) {
            // Perform arbitrage from Uniswap to Sushiswap
            uint256 amountOut1 = swapExactInputSingle(WETH, DAI, amountIn, uniswapRouter, minAmountOut);
            uint256 amountOut2 = swapExactTokensForTokens(amountOut1, DAI, WETH, sushiswapRouter, minAmountOut);
            profit = amountOut2 - amountIn;
        } else {
            // No profitable arbitrage opportunity
            profit = 0;
        }
        return profit;
    }

    function calculateArbitrageAmount() internal view returns (uint256) {
        // Example logic: use 50% of the available WETH balance in the contract
        uint256 balanceWETH = IERC20(WETH).balanceOf(address(this));
        uint256 amountIn = balanceWETH / 2;
        return amountIn;
    }

    function swapExactInputSingle(
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        ISwapRouter router,
        uint256 amountOutMinimum
    ) internal returns (uint256 amountOut) {
        TransferHelper.safeApprove(tokenIn, address(router), amountIn);

        ISwapRouter.ExactInputSingleParams memory params =
            ISwapRouter.ExactInputSingleParams({
                tokenIn: tokenIn,
                tokenOut: tokenOut,
                fee: poolFee,
                recipient: address(this),
                deadline: block.timestamp + 15,
                amountIn: amountIn,
                amountOutMinimum: amountOutMinimum, // Minimum amountOut for slippage protection
                sqrtPriceLimitX96: 0
            });

        amountOut = router.exactInputSingle(params);
    }

    function swapExactTokensForTokens(
        uint256 amountIn,
        address tokenIn,
        address tokenOut,
        ISushiSwapRouter router,
        uint256 amountOutMinimum
    ) internal returns (uint256 amountOut) {
        address[] memory path = new address[](2);
        path[0] = tokenIn;
        path[1] = tokenOut;

        TransferHelper.safeApprove(tokenIn, address(router), amountIn);

        uint256[] memory amounts = router.swapExactTokensForTokens(
            amountIn,
            amountOutMinimum, // Minimum amountOut for slippage protection
            path,
            address(this),
            block.timestamp + 15
        );

        amountOut = amounts[amounts.length - 1];
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(owner()).transfer(balance);
    }

    receive() external payable {}
}
