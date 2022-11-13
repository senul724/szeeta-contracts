const ethers = require('ethers');
const nft_address = "0x14f8fa03DEeF2902C86778b6951bB0703dC3AFb1";
const abi = 
[
  'function addEventUri(uint256 eventId, string metadataUri)',
  'function approve(address to, uint256 tokenId)',
  'function balanceOf(address owner) view returns (uint256)',
  'function eventURI(uint256) view returns (string)',
  'function getApproved(uint256 tokenId) view returns (address)',
  'function isApprovedForAll(address owner, address operator) view returns (bool)',
  'function mint(address contributor, uint256 eventId) returns (uint256)',
  'function name() view returns (string)',
  'function owner() view returns (address)',
  'function ownerOf(uint256 tokenId) view returns (address)',
  'function renounceOwnership()',
  'function safeTransferFrom(address from, address to, uint256 tokenId)',
  'function safeTransferFrom(address from, address to, uint256 tokenId, bytes data)',
  'function setApprovalForAll(address operator, bool approved)',
  'function supportsInterface(bytes4 interfaceId) view returns (bool)',
  'function symbol() view returns (string)',
  'function tokenCounter() view returns (uint256)',
  'function tokenURI(uint256 tokenId) view returns (string)',
  'function transferFrom(address from, address to, uint256 tokenId)',
  'function transferOwnership(address newOwner)'
];
const mumbai_rpc = "https://polygon-mumbai.g.alchemy.com/v2/ileRGQPiVmSJfxyqyF1nG2ZeyE3JjsVV"
const pvt = "c7c880a37ebc1713391673184f13a89158c5ddca9a72538a1d632fd2878e2f5b"

// derived
const provider = new ethers.providers.JsonRpcProvider(mumbai_rpc)
const signer = new ethers.Wallet(pvt, provider)
const contract = new ethers.Contract(nft_address, abi, signer);

const run = async()=>{
  const res = await contract.callStatic.owner();
  console.log(res);
}

run()
