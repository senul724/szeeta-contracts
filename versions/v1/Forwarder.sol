// SPDX-License-Identifier: MIT
// This is a customized OpenZeppelin Forwarder Contract according to a custom relayer

pragma solidity ^0.8.7;

import '@openzeppelin/contracts/utils/cryptography/ECDSA.sol';
import '@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol';
import './interfaces/IFactory.sol';

contract Forwarder is EIP712 {
    using ECDSA for bytes32;
    address org;
    address factory;
    struct forwardData {
        address from;
        address receiver;
        uint256 randomNo;
        uint256 nonce;
    }

    bytes32 private constant typeHash =
        keccak256(
            'forwardData(address from,address receiver,uint256 randomNo,uint256 nonce)'
        );

    mapping(address => uint256) private _nonces;

    modifier onlyOrg() {
        require(msg.sender == org);
        _;
    }

    constructor(address org_, address factory_) EIP712('FundRaiser', '0.0.1') {
        org = org_;
        factory = factory_;
    }

    function getNonce(address from) public view onlyOrg returns (uint256) {
        return _nonces[from];
    }

    function verify(forwardData calldata data, bytes calldata signature)
        internal
        view
        returns (bool)
    {
        address signer = _hashTypedDataV4(
            keccak256(
                abi.encode(typeHash, data.from, data.receiver, data.nonce)
            )
        ).recover(signature);
        return _nonces[data.from] == data.nonce && signer == org;
    }

    function execute(
        forwardData calldata data,
        // bytes calldata signature,
        address[] calldata tokenList
    ) external onlyOrg returns (address contractAddress) {
        // require(verify(data, signature), 'Signer is not org');
        _nonces[data.from] = data.nonce + 1;

        contractAddress = IFactory(factory).createContract(
            data.receiver,
            data.randomNo,
            tokenList
        );
    }
}			// Only required to send ether to the recipient from the initiating external account.
			value: costInWei,
			// Used to prevent transaction reuse across blockchains. Auto-filled by MetaMask.
			chainId: await state.signer.getChainId(),
		};
		let receipt = await state.signer.sendTransaction(tx)
		console.log(receipt);
		console.log(`************************Recept`);
		console.log(Object.keys(costInWei));
		/*
		add the transaction receipt to the database mapping it with the user address
		*/
		return {
			success: costInWei["_hex"] == receipt.value['_hex']
		}
	}

	// Relay transaction after payement confirmation
	const relay = async () => {
		alert("comming into relay")
		// Getting Signer using the private key and executing calls
		for (let i = 0; i < dataList.length; i++) {
			// Ignore this fucking useless error #gohometypescript
			let provider = new providers.JsonRpcProvider(networks[dataList[i].chain]);
			let wallet = new Wallet("c7c880a37ebc1713391673184f13a89158c5ddca9a72538a1d632fd2878e2f5b").connect(provider);
			let data = DataForSig(dataList[i].chain, await state.signer.getAddress(), receiver, i, GetRandom());
			let payload = data.value;
			let inputData = [payload.from, payload.receiver, payload.randomNo, payload.nonce];
			let sig = await wallet._signTypedData(data.domainSeparator, data.types, data.value);
			console.log("signature ****************************");
			console.log(sig);
			console.log("**********************************");
			let contract = new Contract(forwarderAddresses[dataList[i].chain], forwarderSend, wallet);
			let contractAddress = await contract.execute(inputData, sig, dataList[i].tokens,{
				gasPrice:100,
				gasLimit:9000000
			});
			console.log("receipt ****************************");
			console.log(contractAddress);
			console.log("**********************************");
			console.log(Object.keys(contractAddress))
			console.log("**********************************");

			// This might 
