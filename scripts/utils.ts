import "@nomiclabs/hardhat-ethers";
import "@nomiclabs/hardhat-waffle";
import { ethers } from "hardhat";
import { Contract, ContractFactory } from "ethers";

export function contractFromABI(contractAddr: string, abi, ...args) {
  return new ethers.Contract(contractAddr, abi, ...args);
}

export async function contractFromCompiled(
  contractAddr: string,
  contractName: string,
  ...args
) {
  const cf: ContractFactory = await ethers.getContractFactory(
    contractName,
    ...args
  );
  return cf.attach(contractAddr);
}

export async function deployContractFromCompiled(
  contractName: string,
  ...deployArgs
) {
  const cf: ContractFactory = await ethers.getContractFactory(contractName);
  const c: Contract = await cf.deploy(...deployArgs);
  await c.deployed();
  return c;
}
