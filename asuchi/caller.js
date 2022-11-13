const ethers = require('ethers');
const admin_address = "0x577DAF37c72E374f94AaDAF61B2941ac91a0e43D";
const abi = [
  'constructor(uint256 feeFactor_, address org_, address handler_)',
  'function AddpublicCollectionAddress(address collectionAddress)',
  'function addNetwork(uint256 netId)',
  'function changeFeeFactor(uint256 newFeeFactor)',
  'function changeHandler(address newHandler)',
  'function changeOrg(address newOrg)',
  'function changeReceiver(address newReceiver, uint256 chainId, address caller, uint256 eventId, uint256 nonce, bytes signature)',
  'function close(address caller, uint256 eventId, uint256 nonce, bytes signature, address nftContract)',
  'function closed(uint256) view returns (bool)',
  'function createCustomCollection(address eventOwner, uint256 eventId, string name, string symbol, string uri) returns (address)',
  'function createEvent(address owner, tuple(uint256 netId, address receiver)[] chainData) returns (uint256)',
  'function customCollections(uint256) view returns (address)',
  'function eventCounter() view returns (uint256)',
  'function feeFactor() view returns (uint256)',
  'function joinPublicCollection(uint256 eventId, string metadataUri)',
  'function mintCustom(address contributor, uint256 eventId)',
  'function mintPublic(address contributor, uint256 eventId)',
  'function networkAdmins(uint256) view returns (address)',
  'function org() view returns (address)',
  'function owners(uint256) view returns (address)',
  'function publicCollectionAddress() view returns (address)',
  'function recordNativeContribution(uint256 eventId, uint256 amount, uint256 netId)',
  'function recordTokenContribution(uint256 eventId, uint256 amount, uint256 netId, address token)',
  'function transferAuthority(address newOwner, address caller, uint256 eventId, uint256 nonce, bytes signature, address nftContract)'
];
const mumbai_rpc = "https://polygon-mumbai.g.alchemy.com/v2/ileRGQPiVmSJfxyqyF1nG2ZeyE3JjsVV"
const pvt = "c7c880a37ebc1713391673184f13a89158c5ddca9a72538a1d632fd2878e2f5b"

// derived
const provider = new ethers.providers.JsonRpcProvider(mumbai_rpc)
const signer = new ethers.Wallet(pvt, provider)
const contract = new ethers.Contract(admin_address, abi, signer);

const run = async()=>{
  await contract.addNetwork(5);
  console.log("5 done!")
  await contract.addNetwork(97);
  console.log("97 done!")
  await contract.addNetwork(80001);
  console.log("80001 done!")
}

run()
