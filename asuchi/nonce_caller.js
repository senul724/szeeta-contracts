const ethers = require('ethers');

// deployer
const pvt = "ea2412f6afa3e15444909e8a064aecdb9c0aa8f061fe4d22b305a0d0d9a66581"

// derived
const matic = new ethers.providers.JsonRpcProvider("https://polygon-mumbai.g.alchemy.com/v2/ileRGQPiVmSJfxyqyF1nG2ZeyE3JjsVV")
const gorli = new ethers.providers.JsonRpcProvider("https://eth-goerli.g.alchemy.com/v2/kQ1eeQsV0UXkIg-2zAMSCtzU-T1t97px")
const b_test = new ethers.providers.JsonRpcProvider("https://data-seed-prebsc-1-s1.binance.org:8545/")

const wallet = new ethers.Wallet(pvt)

// methods
const run = async(provider, name)=>{
  let signer = wallet.connect(provider);
  let nonce = await signer.getTransactionCount()
  console.log(`${name}: ${nonce}`)
}

run(matic, "matic")
run(gorli, "gorli")
run(b_test, "bsc test")
