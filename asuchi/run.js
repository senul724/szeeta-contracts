const ethers = require('ethers');

const admin_address = "0xb67C3b6F403c3cF0De21d35Eca81a143fF810B6E";
const mumbai_rpc = "https://polygon-mumbai.g.alchemy.com/v2/ileRGQPiVmSJfxyqyF1nG2ZeyE3JjsVV"
const pvt = "c7c880a37ebc1713391673184f13a89158c5ddca9a72538a1d632fd2878e2f5b"

// derived
const provider = new ethers.providers.JsonRpcProvider(mumbai_rpc)
const wallet = new ethers.Wallet(pvt, provider)

wallet.signMessage("[polygonscan.com 05/01/2023 06:00:08] I, hereby verify that I am the owner/creator of the address [0x62975b14D8369A86314678F6fE6035c0faa9D988]").then(console.log)
