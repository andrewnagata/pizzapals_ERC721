from brownie import accounts, config, network, PizzaPals
from brownie.network import web3
from scripts.helpers import get_account, LOCAL_BLOCKCHAIN_ENVIRONMENTS

import time

def deploy_rinkeby():

    _account = get_account(id='omakase')
    
    print(f"Using account: {_account}")

    _baseURI = 'ipfs://QmSeHiQnNju5UgupzBN7fvtbGvcFzqGaecDmMBGQ8yW234'
    _proxyRegistryAddress = '0xa5409ec958c83c3f309868babaca7c86dcb077c1'
    _adminAddress = '0x289eF13168cd8Fc1f6D775eF69A82E40d214C47f'

    contract = PizzaPals.deploy(
        _baseURI,
        _proxyRegistryAddress,
        _adminAddress,
        {"from":_account}, publish_source=config["networks"][network.show_active()].get("verify"))

    print("PizzaPals is deployed...")

    total_supply = contract.totalSupply()

    print(f"{total_supply} tokens have been minted - hopefully zero at this point")

def main():
    deploy_rinkeby()