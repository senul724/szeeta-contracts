const ethers = require('ethers');

const rpc = ""
const abi = [""]
const addr = ""
const pvt_key = ""

// derived
const provider = new ethers.providers.JsonRpcProvider(rpc)
  const wallet = new ethers.Wallet(pvt_key).connect(
    provider,
  );
const contract = new ethers.Contract(addr, abi, wallet)

const run = async()=>{
  const res = await contract.get()
  console.log("sent")
  await res.wait();
  console.log("minted")

}
run();
