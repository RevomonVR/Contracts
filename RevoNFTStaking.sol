pragma solidity ^0.8.11;

interface IRevoNFT{
    
    struct Token {
        string collection;
        string dbId;
        uint256 tokenId;
    }
    
    function nftsDbIds(string memory _collection, string memory _dbId) external view returns (uint256);
    function transferFrom(address from, address to, uint256 tokenId) external;
    function tokenInfo(uint256) external view returns(string memory collection, string memory dbId, uint256 tokenId);
    function burn(uint256 tokenId) external;
    function getTokensByOwner(address _owner) external view returns(Token[] memory ownerTokens);
    function balanceOf(address account) external view returns (uint256);
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);
}

interface IRevoLib{
  function tokenRevoAddress() external view returns (address);
}

interface IRevoTokenContract{
  function balanceOf(address account) external view returns (uint256);
  function totalSupply() external view returns (uint256);
  function transfer(address recipient, uint256 amount) external returns (bool);
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
  function allowance(address owner, address spender) external view returns (uint256);
  function approve(address spender, uint256 amount) external returns (bool);
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
    address private _owner2;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }
    
    function setOwner2(address _contractAddress) public onlyOwner {
        _owner2 = _contractAddress;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender() || _owner2 == _msgSender(), "Ownable: caller is not the owner");
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

contract RevoNFTStaking is Ownable {
    
    IRevoNFT private revoNFT;
    IRevoTokenContract revoToken;
    //Diamond hand nft id
    uint256 public diamondHandsMinId;
    uint256 public diamondHandsMaxId;
    
    mapping(address => NFT_STAKING) public staking; 
    
    struct NFT_STAKING {
        uint256 revupTokenId;
        uint256 diamondHandsTokenId;
    }
    
    constructor(address _revoNFT, address _revoLib){
        setRevoNFT(_revoNFT);
        setRevo(IRevoLib(_revoLib).tokenRevoAddress());
        setDiamondHandsId(296, 2586);
    }
    
    /*
    Stake Revup or diamond hands
    */
    function stake(bool _isDiamond, uint256 _tokenId) public {

        //TODO UNCOMMENT
        //require(_isDiamond ? isDiamondHands(msg.sender, _tokenId) : isRevup(msg.sender, _tokenId), "Token is not correct");

        require((_isDiamond ? staking[msg.sender].diamondHandsTokenId : staking[msg.sender].revupTokenId) == 0 , "NFT already staked");
        
        revoNFT.transferFrom(msg.sender, address(this), _tokenId);
        
        if(_isDiamond){
            setDiamondHandsId(msg.sender, _tokenId);
        }else{
            setRevupTokenId(msg.sender, _tokenId);
        }
    }

    /*
    Untake Revup or diamond hands
    */
    function unStake(bool _isDiamond) public {

        require((_isDiamond ? staking[msg.sender].diamondHandsTokenId : staking[msg.sender].revupTokenId) != 0 , "NFT not staked");
        
        revoNFT.transferFrom(address(this), msg.sender, _isDiamond ? staking[msg.sender].diamondHandsTokenId : staking[msg.sender].revupTokenId);

        if(_isDiamond){
            setDiamondHandsId(msg.sender, 0);
        }else{
            setRevupTokenId(msg.sender, 0);
        }
    }

    function isDiamondHandsStaked(address _owner) public view returns(bool) {
        return staking[_owner].diamondHandsTokenId != 0;
    }

    function isRevupStaked(address _owner) public view returns(bool) {
        return staking[_owner].revupTokenId != 0;
    }

    function setDiamondHandsId(address _user, uint256 _id) public onlyOwner {
        staking[_user].diamondHandsTokenId = _id;
    }
    
    function setRevupTokenId(address _user, uint256 _id) public onlyOwner {
        staking[_user].revupTokenId = _id;
    }
    
    /*
    Set revo Address & token
    */
    function setRevo(address _revo) public onlyOwner {
        revoToken = IRevoTokenContract(_revo);
    }
    
    function setRevoNFT(address _revoNFT) public onlyOwner {
        revoNFT = IRevoNFT(_revoNFT);
    }
    
    function withdrawRevo(uint256 _amount) public onlyOwner {
        revoToken.transfer(owner(), _amount);
    }

    function transferNFT(uint256 _tokenId, address _recipient) public onlyOwner {
        revoNFT.transferFrom(address(this), _recipient, _tokenId);
    }

    function isRevup(address _user, uint256 _tokenId) public view returns(bool){
        uint256 tokenCount = revoNFT.balanceOf(_user);

        if (tokenCount == 0) {
            // Return an empty array
            return false;
        } else {
            bool find = false;
            for (uint256 index = 0; index < tokenCount; index++) {
                
                (string memory collection , string memory dbId , uint256 tokenId) = revoNFT.tokenInfo(revoNFT.tokenOfOwnerByIndex(_user, index));
                if(compareStrings(collection, "R3VUP") && tokenId == _tokenId){
                    find = true;
                    index = tokenCount;
                }
            }

            return find;
        }
    }

    function isDiamondHands(address _user, uint256 _tokenId) public view returns(bool){
        bool found = false;
        uint256 tokenCount = revoNFT.balanceOf(_user);

        if (tokenCount > 0) {
            for (uint256 index = 0; index < tokenCount; index++) {
                (, string memory dbId , uint256 tokenId ) = revoNFT.tokenInfo(revoNFT.tokenOfOwnerByIndex(_user, index));
                uint256 dbIdInt = stringToUint(dbId);
                if(dbIdInt >= diamondHandsMinId && dbIdInt <= diamondHandsMaxId && _tokenId == tokenId){
                    found = true;
                    index = tokenCount;
                }
            }
        }

        return found;
    }

    /*
    Set diamond hand min max id
    */
    function setDiamondHandsId(uint256 _min, uint256 _max) public onlyOwner{
        diamondHandsMinId = _min;
        diamondHandsMaxId = _max;
    }

    function compareStrings(string memory a, string memory b) private pure returns (bool) {
        return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
    }

    /*
    String to uint
    */
    function stringToUint(string memory s) private view returns (uint result) {
        bytes memory b = bytes(s);
        uint i;
        result = 0;
        for (i = 0; i < b.length; i++) {
            uint c = uint8(b[i]);
            if (c >= 48 && c <= 57) {
                result = result * 10 + (c - 48);
            }
        }
    }
}