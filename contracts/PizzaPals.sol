// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzepplin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzepplin/contracts/access/Ownable.sol";
import "@openzepplin/contracts/utils/Strings.sol";
import "./ERC721EnumerablePMP.sol";

import '../interfaces/IOpenSeaCompatible.sol';

contract PizzaPals is ERC721EnumerablePMP, Ownable, IOpenSeaCompatible {

    using Strings for uint256;
    
    string  public              baseURI;
    string  private             _contractURI;

    address public              proxyRegistryAddress;
    address public              adminAddress;

    bytes32 public              whitelistMerkleRoot;
    uint256 public              MAX_SUPPLY;

    uint256 public constant     MAX_PER_TX          = 6;
    uint256 public constant     priceInWei          = 0.04 ether;

    string private _tokenBaseURI;
    string private _tokenRevealedBaseURI;

    mapping(address => bool) public projectProxy;
    mapping(address => uint) public addressToMinted;

    constructor(string memory _baseURI, 
        address _proxyRegistryAddress, 
        address _adminAddress)
        ERC721PMP("PizzaMafiaPals", "PALS") {

            baseURI = _baseURI;
            proxyRegistryAddress = _proxyRegistryAddress;
            adminAddress = _adminAddress;

            _contractURI = 'https://cloudflare-ipfs.com/ipfs/QmU3Bc1k2F1SErJk4FTPxKUwJLcV7DEqnYZGnmLRa5GRs5';
            _tokenRevealedBaseURI = '';
    }

    // IOpenSeaCompatible

    function contractURI() public view override returns (string memory) {
        return _contractURI;
    }

    function setContractURI(string memory contract_uri) external override onlyOwner {
        _contractURI = contract_uri;
    }

    // IPizzaPalsAdmin

    function setBaseURI(string memory _baseURI) public onlyOwner {
        baseURI = _baseURI;
    }

    function setBaseURIRevealed(string memory _baseURI) external onlyOwner {
        _tokenRevealedBaseURI = _baseURI;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), 'Token does not exist');
        
        string memory revealedBaseURI = _tokenRevealedBaseURI;
        return
            bytes(revealedBaseURI).length > 0
                ? string(abi.encodePacked(revealedBaseURI, tokenId.toString()))
                : baseURI;
    }

    function setProxyRegistryAddress(address _proxyRegistryAddress) external onlyOwner {
        proxyRegistryAddress = _proxyRegistryAddress;
    }

    function flipProxyState(address proxyAddress) public onlyOwner {
        projectProxy[proxyAddress] = !projectProxy[proxyAddress];
    }

    function setWhitelistMerkleRoot(bytes32 _whitelistMerkleRoot) external onlyOwner {
        whitelistMerkleRoot = _whitelistMerkleRoot;
    }

    function togglePublicSale(uint256 _MAX_SUPPLY) external onlyOwner {
        delete whitelistMerkleRoot;
        MAX_SUPPLY = _MAX_SUPPLY;
    }

    function _leaf(string memory payload) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(payload));
    }

    function _verify(bytes32 leaf, bytes32[] memory proof) internal view returns (bool) {
        return MerkleProof.verify(proof, whitelistMerkleRoot, leaf);
    }

    function burn(uint256 tokenId) public { 
        require(_isApprovedOrOwner(_msgSender(), tokenId), "Not approved to burn.");
        _burn(tokenId);
    }

    function withdraw() public  {
        (bool success, ) = adminAddress.call{value: address(this).balance}("");
        require(success, "Failed to send to Admin Address.");
    }

    function batchTransferFrom(address _from, address _to, uint256[] memory _tokenIds) public {
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            transferFrom(_from, _to, _tokenIds[i]);
        }
    }

    function batchSafeTransferFrom(address _from, address _to, uint256[] memory _tokenIds, bytes memory data_) public {
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            safeTransferFrom(_from, _to, _tokenIds[i], data_);
        }
    }

    function isOwnerOf(address account, uint256[] calldata _tokenIds) external view returns (bool){
        for(uint256 i; i < _tokenIds.length; ++i ){
            if(_owners[_tokenIds[i]] != account)
                return false;
        }

        return true;
    }

    function isApprovedForAll(address _owner, address operator) public view override returns (bool) {
        OpenSeaProxyRegistry proxyRegistry = OpenSeaProxyRegistry(proxyRegistryAddress);
        if (address(proxyRegistry.proxies(_owner)) == operator || projectProxy[operator]) return true;
        return super.isApprovedForAll(_owner, operator);
    }

    function _mint(address to, uint256 tokenId) internal virtual override {
        _owners.push(to);
        emit Transfer(address(0), to, tokenId);
    }

    // IPizzaPals

    function canMintPresale(
        address owner, 
        bytes32[] calldata proof) public view returns (bool) {
        string memory payload = string(abi.encodePacked(_msgSender()));
        require(_verify(_leaf(payload), proof), 'invalid proof');
        require(addressToMinted[_msgSender()] == 0, 'presale already claimed');

        return true;
    }

    function whitelistMint(uint256 count, bytes32[] calldata proof) public payable {
        string memory payload = string(abi.encodePacked(_msgSender()));
        require(_verify(_leaf(payload), proof), "Invalid Merkle Tree proof supplied.");
        require(count == 1, "Invalid token count provided.");
        require(addressToMinted[_msgSender()] == 0, "presale already claimed");
        //require(count * priceInWei == msg.value, "Invalid funds provided.");

        addressToMinted[_msgSender()] += count;
        uint256 totalSupply = _owners.length;
        for(uint i; i < count; i++) { 
            _mint(_msgSender(), totalSupply + i);
        }
    }

    function publicMint(uint256 count) public payable {
        uint256 totalSupply = _owners.length;
        require(totalSupply + count < MAX_SUPPLY, "Excedes max supply.");
        require(count < MAX_PER_TX, "Exceeds max per transaction.");
        require(count * priceInWei == msg.value, "Invalid funds provided.");
    
        for(uint i; i < count; i++) { 
            _mint(_msgSender(), totalSupply + i);
        }
    }

    function walletOfOwner(address _owner) public view returns (uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);
        if (tokenCount == 0) return new uint256[](0);

        uint256[] memory tokensId = new uint256[](tokenCount);
        for (uint256 i; i < tokenCount; i++) {
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokensId;
    }
}

contract OwnableDelegateProxy { }
contract OpenSeaProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}