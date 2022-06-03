from brownie import accounts, config, network, PizzaPals
from brownie.network import web3
from scripts.helpers import get_account, LOCAL_BLOCKCHAIN_ENVIRONMENTS

import time

def deploy_pizzapals():

    _account = get_account() #id="omakase"
    
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
    
    merkleRoot = "0x4bccf72e838639e527cacbfd835194e8a2778ecfc72102a5d1fe1726386ad041"
    merkle_tx = contract.setWhitelistMerkleRoot(merkleRoot, {"from":_account})
    merkle_tx.wait(1)

    mint_amount = 1
    proof = ['0x5c4a1afe01494e8514ae2a01ae4d9e6ceb2839e29f0b727832f936c96a597d7f', '0xfa820a421a73532a4f7f1b072c73674692fe3d1d758a3320bdf06aad2d2a3af8', '0x89461e4537c6a022510184bb3c82022c1e1402f474cd217c0a98d586977b16cf', '0x3d9106a6957a620fe9c63496eef34841970efe43a6d9c17f2176993d73b62721', '0xace771901db8c356784cf897ef446c9fc94b0c2a718310176023857712ed5c4c']
    
    # can_mint = False
    # try:
    #     can_mint = contract.canMintPresale(_account, proof)
    # except:
    #     print("bad proof here.")

    # print(f"CAN MINT: {can_mint}")

    # presale_tx = contract.whitelistMint(mint_amount, proof, {"from":_account})
    # presale_tx.wait(1)

    print("Staring the sale!")
    start_tx = contract.togglePublicSale(100, {"from":_account})
    start_tx.wait(1)

    # _account = get_account()
    # print(f"Using account: {_account}")

    value = web3.toWei(0.04, "ether") * mint_amount
    purchase_tx = contract.publicMint(mint_amount, {"from":_account, "value":value, })
    purchase_tx.wait(1)

    print("First purchase complete")

    total_supply = contract.totalSupply()

    print(f"{total_supply} tokens have been minted")

    token_uri = contract.tokenURI(0)
    print (f"PRE_REVEAL URI: {token_uri}")

    reveal_string = "ipfs/real_base_uri/"
    reveal_tx = contract.setBaseURIRevealed(reveal_string, {"from":_account})
    reveal_tx.wait(1)

    print("Reveal URI set success!")

    reveal_uri = contract.tokenURI(0)
    print (f"REVEALED URI: {reveal_uri}")

def main():
    deploy_pizzapals()