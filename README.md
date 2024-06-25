# EnergyFlow
Management, Monitoring and Mastering of Energy


# PROJECTS

## 1. EnergyArbitrage

## Overview

**EnergyArbitrage** is a smart contract project designed for performing arbitrage trading between Uniswap and Sushiswap decentralized exchanges (DEXs). This project leverages Chainlink Oracles to fetch real-time prices for the WETH/DAI trading pair, ensuring accurate and dynamic pricing information. The contract aims to exploit price differences between the two DEXs to generate profit through flash loans provided by Uniswap V3.

## Purpose
The primary purpose of this project is to demonstrate an automated arbitrage trading strategy using Ethereum smart contracts. By integrating Chainlink Oracles, the contract ensures that price information is reliable and up-to-date, enhancing the accuracy and profitability of the arbitrage trades.

## Features

- **Arbitrage Trading**: Executes arbitrage opportunities between Uniswap and Sushiswap by comparing prices for the WETH/DAI pair.
- **Chainlink Oracles**: Utilizes Chainlink Oracles to fetch real-time prices from both Uniswap and Sushiswap, ensuring dynamic and accurate pricing.
- **Flash Loans**: Uses Uniswap V3 flash loans to perform arbitrage trades without requiring initial capital.
- **Slippage Protection**: Incorporates slippage tolerance to safeguard against front-running, MEV, and sandwich attacks.
- **Reentrancy Guard**: Implements OpenZeppelin's `ReentrancyGuard` to prevent reentrancy attacks.

## Contracts

### PriceOracle.sol
This contract fetches the latest WETH/DAI prices from Chainlink Oracles for both Uniswap and Sushiswap. It includes two main functions:

- `getLatestPriceUniswap()`: Returns the latest price from the Uniswap Chainlink Oracle.
- `getLatestPriceSushiswap()`: Returns the latest price from the Sushiswap Chainlink Oracle.

### EnergyArbitrage.sol
This contract performs the arbitrage trading using the prices obtained from the `PriceOracle` contract. Key functionalities include:

- **Constructor**: Initializes the contract with addresses for Uniswap V3 Factory, Uniswap Router, Sushiswap Router, PriceOracle, WETH, DAI, pool fee, and slippage tolerance.
- **Arbitrage Execution**: Contains the logic to execute arbitrage trades based on price comparisons between Uniswap and Sushiswap.
- **Flash Loan Callback**: Implements the `uniswapV3FlashCallback` to handle flash loan repayments.

## How It Works

1. **Price Fetching**: The `PriceOracle` contract fetches the latest prices for WETH/DAI from both Uniswap and Sushiswap using Chainlink Oracles.
2. **Arbitrage Decision**: The `EnergyArbitrage` contract compares the prices and decides the direction of the arbitrage trade (Uniswap to Sushiswap or vice versa).
3. **Flash Loan Execution**: The contract takes a flash loan from Uniswap V3, executes the arbitrage trade, and repays the loan within the same transaction.
4. **Profit Calculation**: If the trade is profitable, the contract retains the profit; otherwise, it reverts the transaction to avoid losses.

## Deployment and Testing

### Prerequisites

- **MetaMask Wallet**: Ensure you have MetaMask installed and configured for the Sepolia testnet.
- **Sepolia Testnet ETH**: Obtain some Sepolia ETH from a faucet to cover gas fees.

### Deployment Steps

1. **Clone the Repository**:
   ```sh
   git clone https://github.com/your-username/EnergyArbitrage.git
   cd EnergyArbitrage
   ```

2. **Deploy the `PriceOracle` Contract**:
   - Open `PriceOracle.sol` in Remix IDE.
   - Compile and deploy the contract on the Sepolia testnet.
   - Use the Chainlink price feed addresses for the constructor.

3. **Deploy the `EnergyArbitrage` Contract**:
   - Open `EnergyArbitrage.sol` in Remix IDE.
   - Update the constructor parameters with the deployed `PriceOracle` address and other required addresses.
   - Compile and deploy the contract on the Sepolia testnet.

4. **Fund the Contract**:
   - Transfer WETH and DAI to the `EnergyArbitrage` contract.

5. **Approve Routers**:
   - Interact with WETH and DAI token contracts to approve Uniswap and Sushiswap routers.

### Testing

1. **Check Prices**:
   - Automatically check prices on Uniswap and Sushiswap for the WETH/DAI pair using PriceOracle.sol called from the EnergyArbitrage contract

2. **Execute Arbitrage**:
   - Call the `executeArbitrage` function on the `EnergyArbitrage` contract if profitable conditions are identified.

3. **Verify Profit**:
   - Check the events emitted by the contract to verify the profit from arbitrage.

## Contributing
Contributions to improve this project are welcome. Please fork the repository, create a new branch, and submit a pull request with your changes.

## License
This is an open license project.  Updates to occur as status changes

---

Feel free to customize this README.md further to better fit your project's specifics and additional details you might want to include.
