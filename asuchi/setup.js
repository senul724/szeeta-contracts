const ethers = require('ethers');
const {Interface, FormatTypes} = require("@ethersproject/abi")

const admin_address = "0x5b906B7a59958a2c48FDE0CEDf5579dbB39B3E6E";
const old_admin_address = "0x5b906B7a59958a2c48FDE0CEDf5579dbB39B3E6E";
const mumbai_rpc = "https://polygon-mumbai.g.alchemy.com/v2/ileRGQPiVmSJfxyqyF1nG2ZeyE3JjsVV"
const pvt = "c7c880a37ebc1713391673184f13a89158c5ddca9a72538a1d632fd2878e2f5b"

const rawAbi = require('../build/Administration.sol/Administration.json').abi;
const abi = new Interface(rawAbi).format(FormatTypes.full);

// derived
const provider = new ethers.providers.JsonRpcProvider(mumbai_rpc)
const signer = new ethers.Wallet(pvt, provider)
const contract = new ethers.Contract(admin_address, abi, signer);
const old_contract = new ethers.Contract(old_admin_address, abi, signer);

const setup = async()=>{
  const nft_factory = await old_contract.callStatic.factory();
  const public_nft_contract = await old_contract.callStatic.publicCollectionAddress();

  await contract.addPublicCollectionAddress(public_nft_contract);
  await contract.addCollectionFactory(nft_factory);

  await contract.addNetwork(80001);
  console.log("matic done")
   await contract.addNetwork(97);
  console.log("binance done")
  await contract.addNetwork(5);
  console.log("eth done")
}

setup()
