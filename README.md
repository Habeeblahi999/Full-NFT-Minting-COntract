# Full Featured NFT Minting Contract

A production-ready ERC-721 NFT minting contract built with 
Solidity and OpenZeppelin, deployed on the Ethereum Sepolia testnet.

## Features
- 🎨 ERC-721 NFT standard
- 🔒 Whitelist presale with Merkle tree verification
- 🌍 Public sale phase
- 🎭 Reveal mechanism (hidden metadata before reveal)
- 💰 Configurable mint price
- 🐋 Max per wallet limit
- 👑 Royalties (ERC-2981) - 5% default
- ⏸️ Pause mechanism for emergencies
- 💵 Withdraw funds function
- 🆓 Owner free mint

## Tech Stack
- Solidity 0.8.20
- OpenZeppelin Contracts
- Remix IDE
- Ethereum Sepolia Testnet

## Contract Details
- **Network:** Ethereum Sepolia Testnet
- **Contract Address:** 0x153C67Fa15Cf7B229146711AE91565F8fD60D905
- **Token Name:** MyNFT
- **Symbol:** MNFT
- **Max Supply:** 1,000

## Live Contract
View on Etherscan:
https://sepolia.etherscan.io/address/0x153C67Fa15Cf7B229146711AE91565F8fD60D905

## How It Works
- Owner activates whitelist or public sale
- Users mint NFTs by sending ETH
- Hidden metadata shown until owner reveals
- Owner can pause contract in emergencies
- Owner withdraws ETH from contract

## Functions
| Function | Description |
|---|---|
| `mint` | Public mint with ETH |
| `whitelistMint` | Whitelist mint with merkle proof |
| `ownerMint` | Owner free mint |
| `reveal` | Reveal real metadata |
| `withdraw` | Withdraw contract balance |
| `pause/unpause` | Emergency pause |
| `setPublicSaleActive` | Activate public sale |
| `setWhitelistSaleActive` | Activate whitelist sale |

## License
MIT
