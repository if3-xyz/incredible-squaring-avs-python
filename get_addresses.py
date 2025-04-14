import json

def get_addresses_dict():
    with open("eigenlayer-contracts/script/output/devnet/SLASHING_deploy_from_scratch_deployment_data.json", "r") as f:
        data = json.load(f)
    return data["addresses"]

addresses_dict = get_addresses_dict()

for key, value in addresses_dict.items():
    print(f"{key}: {value}")
