const ethers = require('ethers');
const admin_address = "0xb67C3b6F403c3cF0De21d35Eca81a143fF810B6E";
const abi = require("./admin.json").abi;
const netAbi = require("./admin.json").netAbi;
const mumbai_rpc = "https://polygon-mumbai.g.alchemy.com/v2/ileRGQPiVmSJfxyqyF1nG2ZeyE3JjsVV"
const pvt = "c7c880a37ebc1713391673184f13a89158c5ddca9a72538a1d632fd2878e2f5b"

// derived
const provider = new ethers.providers.JsonRpcProvider(mumbai_rpc)
const signer = new ethers.Wallet(pvt, provider)
const contract = new ethers.Contract(admin_address, abi, signer);

const run = async()=>{
  const bsc_admin = await contract.callStatic.networkAdmins(80001);
  const netAdminContract = new ethers.Contract(bsc_admin, netAbi, signer);
  const receiver = await netAdminContract.callStatic.receivers(1);
  console.log(`admin:${bsc_admin} \n receiver:${receiver}\n\n`);
}

const run2 = async()=>{
  const owner = await contract.callStatic.closed(1);
  console.log(owner)
}

run2()
