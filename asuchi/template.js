const ethers = require('ethers');

const mumbai_rpc = "https://holy-boldest-sun.bsc.discover.quiknode.pro/51ae2de80450e4bcf458bbfe7daf24277d75b242/"

// derived
const provider = new ethers.providers.JsonRpcProvider(mumbai_rpc)
provider.getNetwork().then(console.log)
