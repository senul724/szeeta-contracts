const ethers = require('ethers');
const {Interface, FormatTypes} = require("@ethersproject/abi")

const admin_address = "0xb67C3b6F403c3cF0De21d35Eca81a143fF810B6E";
const mumbai_rpc = "https://polygon-mumbai.g.alchemy.com/v2/ileRGQPiVmSJfxyqyF1nG2ZeyE3JjsVV"
const pvt = "c7c880a37ebc1713391673184f13a89158c5ddca9a72538a1d632fd2878e2f5b"

const rawAbi = require('../build/Administration.sol/Administration.json').abi;
const abi = new Interface(rawAbi).format(FormatTypes.full);

// derived
const provider = new ethers.providers.JsonRpcProvider(mumbai_rpc)
const signer = new ethers.Wallet(pvt, provider)
const contract = new ethers.Contract(admin_address, abi, signer);
