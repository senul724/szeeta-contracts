const Web3 = require('web3');

const examiner_address = "0xAdc052101bcEb6ac1Fdc173dDab3AA8C434EB9e6";
const mumbai_rpc = "https://polygon-mumbai.g.alchemy.com/v2/ileRGQPiVmSJfxyqyF1nG2ZeyE3JjsVV"

const rawAbi = require('../build/Examiner.sol/Examiner.json').abi;

// derived
const web3 = new Web3(mumbai_rpc)
const contract = new web3.eth.Contract(rawAbi, examiner_address);

// add flters here with a value of a indexed field 
// Ex: {eventId:1}
const filter = {}

// block time stamp to start search from
// add the creation time of the contract if none to avoid exessive search effort
const fromBlock =  29932475

// add latest to filter to the present block or any prefered range
const toBlock = "latest"

const run = async()=>{
  const payload = await contract.getPastEvents("nativeContribution",{
    filter,
    fromBlock,
    toBlock
});
  payload.map((log)=>console.log(log.returnValues));
  console.log(`${payload.length} events loged`)
}

run()
