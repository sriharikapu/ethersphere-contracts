## Ethersphere

## Table of Contents

* [Description](#description)
* [Assumptions](#assumptions)
* [Contracts](#contracts)


## Description
Ethersphere allows users to place a 3d icon via augmented reality on a location anywhere in the world. Byt dividing the
world into 5x5x5m grids, users can buy locations all around the world and place their custom augmented reality object
for the world to see. People can outbid other's for a desirable location, such as in front of the Eiffel Tower.

The contract uses ERC721 to divide the world into non-fungible cube for users to purchase. A user can use the 
ethersphere.am interface to easily purchase a cube. 

The owner of a cube can now purchase on object on a cube and sell a cube

## Assumptions
- The price of the initial location can be changed due to the extreme volatility of the price of ETH.


## Contracts
### Ethersphere Contracts
#### [EthersphereAccessControl.sol](https://github.com/shanefontaine/ethersphere-contracts/blob/master/contracts/EthersphereAccessControl.sol)
- Access control contract for Ethersphere. Assigns a CFO for the rest of the contracts

#### [EthersphereBase.sol](https://github.com/shanefontaine/ethersphere-contracts/blob/master/contracts/EthersphereBase.sol)
- Base logic of the contracts

#### [EthersphereCube.sol](https://github.com/shanefontaine/ethersphere-contracts/blob/master/contracts/EthersphereCube.sol)
- Cube definitions

#### [EthersphereFinance.sol](https://github.com/shanefontaine/ethersphere-contracts/blob/master/contracts/EthersphereFinance.sol)
- Buyouts and financing

#### [EthersphereMinting.sol](https://github.com/shanefontaine/ethersphere-contracts/blob/master/contracts/EthersphereMinting.sol)
- Creation of cubes


