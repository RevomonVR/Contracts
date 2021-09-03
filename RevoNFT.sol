pragma solidity ^0.8.3;
pragma experimental ABIEncoderV2;

import "https://raw.githubusercontent.com/DefiOfThrones/DOTTokenContract/master/nfts/rootChain/ERC721.sol";
import "https://raw.githubusercontent.com/DefiOfThrones/DOTTokenContract/master/nfts/rootChain/ERC721Burnable.sol";

contract Ownable is Context {
    address private _owner;
    address private _minter;
    address private _minterContract;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }
    
    function setMinter(address _minterAddress) public onlyOwner {
        _minter = _minterAddress;
    }
    
    function setMinterContract(address _minterAddress) public onlyOwner {
        _minterContract = _minterAddress;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
    
    modifier onlyOwnerOrMinter() {
        require(_owner == _msgSender() || _minter == _msgSender() || _minterContract  == _msgSender(), "Ownable: caller is not the owner or the minter");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract RevoNFT is ERC721, Ownable, ERC721Burnable {

    uint256 private nextRevoId;
    mapping(uint256 => Token) public tokenInfo;
    mapping(string => mapping(string => uint256)) public nftsDbIds;
    
    struct Token {
        string collection;
        string dbId;
        uint256 tokenId;
    }
    
    event NewRevo(uint256 id);
    event TransferRevoNFT(address from, address to, uint256 tokenId, string dbId);
    
    //MODIFIERS
    modifier mintNFTProtection(string memory _collection, string memory _dbId) {
        //REVO not already minted
        require(nftsDbIds[_collection][_dbId] == 0, "NFT already minted");
        
        _;
    }

    constructor(address _minterAddress, address _minterContractAddress, string memory _baseUrl) public ERC721("Revomon", "RevoNFT"){
        setMinter(_minterAddress);
        setMinterContract(_minterContractAddress);
        setBaseURI(_baseUrl);
    }
    
    function mintRevo(address _to, string memory _collection, string memory _dbId) public onlyOwnerOrMinter mintNFTProtection(_collection, _dbId) {
        nextRevoId++;
        
        nftsDbIds[_collection][_dbId] = nextRevoId;
        
        setCollectionForToken(nextRevoId, _collection);
        setDbIdForToken(nextRevoId, _dbId);
        tokenInfo[nextRevoId].tokenId = nextRevoId;

        _mint(_to, nextRevoId);
    }
    
    function mintBatchRevo(address _to, string memory _collection, string[] memory _dbId) public onlyOwnerOrMinter {
        for(uint256 i=0; i < _dbId.length; i++){
            mintRevo(_to, _collection, _dbId[i]);
        }
    }
    
    function setCollectionForToken(uint256 _tokenId, string memory _collection) public onlyOwnerOrMinter {
        tokenInfo[_tokenId].collection = _collection;
    }
    
    function setDbIdForToken(uint256 _tokenId, string memory _dbId) public onlyOwnerOrMinter {
        tokenInfo[_tokenId].dbId = _dbId;
    }
    
    function setBaseURI(string memory _baseUrl) public onlyOwner{
        _setBaseURI(_baseUrl);
    }
    
    /*
    Return token info for owner
    */
    function getTokensByOwner(address _owner) public view returns(Token[] memory ownerTokens) {
        uint256 tokenCount = balanceOf(_owner);

        if (tokenCount == 0) {
            // Return an empty array
            return new Token[](0);
        } else {
            Token[] memory result = new Token[](tokenCount);

            for (uint256 index = 0; index < tokenCount; index++) {
                result[index] = tokenInfo[tokenOfOwnerByIndex(_owner, index)];
            }

            return result;
        }
    }
    
    /*
    Return token dbId for owner
    */
    function getTokensDbIdByOwnerAndCollection(address _owner, string memory _collection) public view returns(string[] memory ownerTokensDbId) {
        Token[] memory tokens = getTokensByOwner(_owner);
        
        Token[] memory result = new Token[](tokens.length);
        
        uint256 i;
        uint256 countNotEmpty;
        for (uint256 index = 0; index < tokens.length; index++) {
            if(compareStrings(tokens[index].collection, _collection)){
                result[i] = tokens[index];
                i++;
            }
        }
        
        string[] memory dbIdToReturn = new string[](i);
        for (uint256 index = 0; index < dbIdToReturn.length; index++) {
            dbIdToReturn[index] = result[index].dbId;
        }
        
        return dbIdToReturn;
    }
    
    function _transfer(address from, address to, uint256 tokenId) internal virtual override {
        super._transfer(from,to,tokenId);
        
        emit TransferRevoNFT(from, to, tokenId, tokenInfo[tokenId].dbId);
    }
    
    function compareStrings(string memory a, string memory b) private pure returns (bool) {
        return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
    }
}
