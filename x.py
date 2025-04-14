from web3 import Web3

w3 = Web3(Web3.HTTPProvider("http://localhost:8545"))

contract = w3.eth.get_code("0xD6b040736e948621c5b6E0a494473c47a6113eA8")

print(contract.hex())

