const ethers = require('ethers');
const admin_address = "0xdd62E5C5543eEf54b249C689b4458C559AE2eD10";
const abi = require("./admin.json").abi;
const mumbai_rpc = "https://polygon-mumbai.g.alchemy.com/v2/ileRGQPiVmSJfxyqyF1nG2ZeyE3JjsVV"
const {sigOut} = require('./data-for-sig');

const pvt = "c7c880a37ebc1713391673184f13a89158c5ddca9a72538a1d632fd2878e2f5b"
const addr = "0x15Cf49f835C5545810a2CCd4c8F71B17dc16aE22"

const pvt2 = "ea2412f6afa3e15444909e8a064aecdb9c0aa8f061fe4d22b305a0d0d9a66581"
const addr2 = "0x083C316d4dd02c58FA7EbA2F9008dCf8979b84B2"

// derived
const provider = new ethers.providers.JsonRpcProvider(mumbai_rpc)
const signer1 = new ethers.Wallet(pvt, provider)
const signer2 = new ethers.Wallet(pvt2, provider)
const contract = new ethers.Contract(admin_address, abi, signer1);

// signature data
// (caller, eventid nonce)
const payload = sigOut(addr2, 1, 2)
const {domainseparator, types, value} = payload;

// methods
const run2 = async()=>{
  const signature = await  signer2._signTypedData(domainseparator, types, value)
                                    // (newOwner, caller, eventId, nonce, bytes signature)
  const res = await contract.callStatic.owners(1)
  console.log(res)
}


const run = async()=>{
  await contract.addNetwork(5) 
  console.log("eth done!")
  await contract.addNetwork(97) 
  console.log("binance done!")
  await contract.addNetwork(80001) 
  console.log("matic done!")
  await contract.createEvent(addr, [[5,addr], [97,addr], [80001,addr]])
  console.log("created!")
}

run2()
