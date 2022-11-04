const {Interface, FormatTypes} = require("@ethersproject/abi")
const abi = require('../build/NetworkAdmin.sol/NetworkAdmin.json').abi

const out = new Interface(abi).format(FormatTypes.full);
console.log(out)
