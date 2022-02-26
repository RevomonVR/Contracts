pragma solidity ^0.8.3;
pragma experimental ABIEncoderV2;

interface IRevoTokenContract{
  function balanceOf(address account) external view returns (uint256);
  function totalSupply() external view returns (uint256);
  function transfer(address recipient, uint256 amount) external returns (bool);
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
  function allowance(address owner, address spender) external view returns (uint256);
  function approve(address spender, uint256 amount) external returns (bool);
}

interface IRevoLib{
  function getLiquidityValue(uint256 liquidityAmount) external view returns (uint256 tokenRevoAmount, uint256 tokenBnbAmount);
  function getLpTokens(address _wallet) external view returns (uint256);
  function tokenRevoAddress() external view returns (address);
  function calculatePercentage(uint256 _amount, uint256 _percentage, uint256 _precision, uint256 _percentPrecision) external view returns (uint256);
}

interface IRevoNFT{
    
    struct Token {
        string collection;
        string dbId;
        uint256 tokenId;
    }
    
    function nftsDbIds(string memory _collection, string memory _dbId) external view returns (uint256);
    function transferFrom(address from, address to, uint256 tokenId) external;
    function tokenInfo(uint256 tokenId) external view returns(IRevoNFT.Token memory);
    function burn(uint256 tokenId) external;
    function getTokensByOwner(address _owner) external view returns(Token[] memory ownerTokens);
}

library SafeMath {
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, 'ds-math-add-overflow');
    }

    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, 'ds-math-sub-underflow');
    }

    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, 'ds-math-mul-overflow');
    }
}

contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor () { }

    function _msgSender() public view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;
    address private _burnerOwner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }
    
    function setBurnerOwner(address _contractAddress) public onlyOwner {
        _burnerOwner = _contractAddress;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender() || _burnerOwner == _msgSender(), "Ownable: caller is not the owner");
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

contract RevoEggFarmer is Ownable {
    using SafeMath for uint256;
     
    address public revoAddress;
    IRevoTokenContract private revoToken;
    address public revoLibAddress;
    IRevoLib private revoLib;
    
    IRevoNFT private revoNFT;
    
    mapping(address => EGG[]) public eggs; 
    EGG_INFO[99] public eggInfo;
    
    struct EGG {
        uint256 tokenId;
        uint256 stakeTs;
        uint256 revoSent;
        bool hasHatched;
    }

    struct EGG_INFO {
        uint256 itemId;
        uint256 recommendedFarmingDays;
        uint256 recommendedRevoAmount;
    }
    
    constructor(address _revoLibAddress, address _revoNFT, address _burnerAddress){
        setRevoLib(_revoLibAddress);
        setRevo(revoLib.tokenRevoAddress());
        setRevoNFT(_revoNFT);
        setBurnerOwner(_burnerAddress);
    }
    
    /*
    Stake egg
    */
    function stakeEgg(uint256 _tokenId) public {

        require(isTokenEgg(msg.sender, _tokenId), "NFT is not an egg");
        
        revoNFT.transferFrom(msg.sender, address(this), _tokenId);
        
        eggs[msg.sender].push(EGG(_tokenId, block.timestamp, 0, false));
    }
    
    /*
    Farm egg
    */
    function farmEgg(uint256 _tokenId, uint256 _revoAmount) public {
        for(uint256 i = 0; i < eggs[msg.sender].length; i++){
            if(eggs[msg.sender][i].tokenId == _tokenId){
                require(!eggs[msg.sender][i].hasHatched, "Egg has already hatched");

                revoToken.transferFrom(msg.sender, address(this), _revoAmount);
                
                eggs[msg.sender][i].revoSent = eggs[msg.sender][i].revoSent.add(_revoAmount);

                i = eggs[msg.sender].length;
            }
        }
    }
    
    /*
    Hatch egg
    */
    function hatchEgg(uint256 _tokenId, address user) public onlyOwner {
        
        for(uint256 i = 0; i < eggs[user].length; i++){
            if(eggs[user][i].tokenId == _tokenId){
                require(!eggs[user][i].hasHatched, "Egg already hatched");
                eggs[user][i].hasHatched = true;
                //BURN NFT
                revoNFT.burn(_tokenId);
                return;
            }
        }
        require(false, "User doesn't own egg");
    }

    function isTokenEgg(address _user, uint256 _tokenId) public view returns(bool){
        IRevoNFT.Token[] memory tokens = revoNFT.getTokensByOwner(_user);
        for(uint256 i = 0; i < tokens.length; i++){
            if(tokens[i].tokenId == _tokenId && compareStrings(tokens[i].collection, "EGG")){
                return true;
            }
        }
    }
    
    /*
    Get all eggs for a user
    */
    function getEggsForUser(address user) public view returns(EGG[] memory){
        return eggs[user];
    }
    
    /*
    Set revo Address & token
    */
    function setRevo(address _revo) public onlyOwner {
        revoAddress = _revo;
        revoToken = IRevoTokenContract(revoAddress);
    }
    
    /*
    Set revoLib Address & libInterface
    */
    function setRevoLib(address _revoLib) public onlyOwner {
        revoLibAddress = _revoLib;
        revoLib = IRevoLib(revoLibAddress);
    }
    
    function setRevoNFT(address _revoNFT) public onlyOwner {
        revoNFT = IRevoNFT(_revoNFT);
    }
    
    function withdrawRevo(uint256 _amount) public onlyOwner {
        revoToken.transfer(owner(), _amount);
    }
    
    function compareStrings(string memory a, string memory b) private pure returns (bool) {
        return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
    }

    function editEggInfo(uint256 _index, uint256 _itemId, uint256 _recommendedFarmingDays, uint256 _recommendedRevoAmount) public onlyOwner{
        eggInfo[_index].itemId = _itemId;
        eggInfo[_index].recommendedFarmingDays = _recommendedFarmingDays;
        eggInfo[_index].recommendedRevoAmount = _recommendedRevoAmount;
    }

    function getAllEggInfo() public view  returns(EGG_INFO[] memory){
        uint256 count;
        for(uint i = 0; i < eggInfo.length; i++){
            if(eggInfo[i].recommendedRevoAmount > 0){
                count++;
            }
        }
        
        EGG_INFO[] memory itemToReturn = new EGG_INFO[](count);
        for(uint256 i = 0; i < eggInfo.length; i++){
            if(eggInfo[i].recommendedRevoAmount > 0){
                itemToReturn[i] = eggInfo[i];
            }
        }
        return itemToReturn;
    }
}
