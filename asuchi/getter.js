const {Interface, FormatTypes} = require("@ethersproject/abi")
const abi = require('../build/Administration.sol/Administration.json').abi

const out = new Interface(abi).format(FormatTypes.full);
console.log(out)
