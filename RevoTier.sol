pragma solidity >=0.8.0;

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
  function calculatePercentage(uint256 _amount, uint256 _percentage, uint256 _precision) external view returns (uint256);
}

interface IRevoPoolManagerContract{
  function getRevoStakedFromStakingPools(address wallet) external view returns (uint256);
  function getLPStakedFromFarmingPools(address wallet) external view returns (uint256);
}

interface IRevoNFTToken{
    function getTokensDbIdByOwnerAndCollection(address _owner, string memory _collection) external view returns(string[] memory ownerTokensDbId);
    function tokenInfo(uint256) external view returns(string memory collection, string memory dbId, uint256 tokenId);
    function balanceOf(address owner) external view returns (uint256 balance);
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);
}

interface IRevoNFTStaking{
    function isDiamondHandsStaked(address _owner) external view returns(bool);
    function isRevupStaked(address _owner) external view returns(bool);
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

    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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

contract RevoTier is Ownable{
    using SafeMath for uint256;
    
    //TIER Struct
    struct Tier {
        uint256 index;
        uint256 minRevoToHold;
        uint256 stakingAPRBonus;
        string name;
        uint256 marketplaceFee;
    }
    
    //Revo Token
    address public revoAddress;
    IRevoTokenContract revoToken;
    //Revo lib
    address public revoLibAddress;
    IRevoLib revoLib;
    //Revo PoolManager 
    address public revoPoolManagerAddress;
    IRevoPoolManagerContract revoPoolManager;
    //REVO NFT STAKING
    IRevoNFTStaking revoNFTStaking;
    //Tiers
    Tier[6] public tiers;
    
    //Enable or disable balance fetch
    bool public liquidityBalanceEnabled;
    bool public stakingBalanceEnabled;
    //Boost tier + 1 
    bool public nftBoostEnabled;
    //Max Tier boost 
    uint256 public maxTierIndexBoost;
    //Revo NFT Token
    IRevoNFTToken revoNFTToken;
    uint256 public marketPlaceFeeNoTier;
    
    constructor(address _revoLibAddress, address _revoPoolManager, address _revoNFTToken, address _revoNFTStaking) {
        setRevoLib(_revoLibAddress);
        setRevoToken(revoLib.tokenRevoAddress());
        setRevoPoolManager(_revoPoolManager);
        setRevoNFTToken(_revoNFTToken);
        setRevoNFTStaking(_revoNFTStaking);
        //Enable liquidity balance
        setLiquidityBalanceEnable(true);
        //Enable staking balance
        setStakingBalanceEnable(true);
        //Enable NFT Tier boost 
        setNftBoostEnable(true);
        //Set Max tier index boost to 3 included
        setMaxTierIndexBoost(3);
        
        //Tiers
        setTier(0, 1000000000000000000000, 0,  "Trainee", 35);
        setTier(1, 2500000000000000000000, 25, "Tamer", 30);
        setTier(2, 5000000000000000000000, 50, "Ranger", 25);
        setTier(3, 10000000000000000000000, 60, "Veteran", 20);
        setTier(4, 25000000000000000000000, 70, "Elite", 15);
        setTier(5, 100000000000000000000000, 80, "Master", 0);
    }
    
    function getTierIndex(address _wallet) public view returns(uint256){
        uint256 balance = revoToken.balanceOf(_wallet);
        
        //Get Revo from Cake V2 Pool & Farming pools 
        if(liquidityBalanceEnabled){
            //Get LP tokens from wallet balance & farming pools
            balance = balance.add(getTokensFromLiquidity(_wallet, true));
        }
        
        //Get Revo from staking pools
        if(stakingBalanceEnabled){
            balance = balance.add(getTokensFromStaking(_wallet));
        }
        
        uint256 tierIndex = 9999;
        for(uint256 i = 0; i < tiers.length; i++){
            if(balance >= tiers[i].minRevoToHold){
                tierIndex = i;
            }
        }
        
        return tierIndex;
    }
    
    
    function getRealTimeTier(address _wallet) public view returns(Tier memory) {
        uint256 tierIndex = getTierIndex(_wallet);
        
        return tierIndex < 9999 ? tiers[tierIndex] : Tier(99, 0, 0, "", marketPlaceFeeNoTier);
    }
    
    function getRealTimeTierWithDiamondHands(address _wallet) public view returns(Tier memory){
        
        uint256 tierIndex = getTierIndex(_wallet);
        
        if(nftBoostEnabled && (tierIndex <= maxTierIndexBoost || tierIndex == 9999)){

            bool found = revoNFTStaking.isDiamondHandsStaked(_wallet);

            if(found){
                tierIndex = tierIndex < 9999 ? tierIndex.add(1) : 0;
            }
        }
        
        return tierIndex < 9999 ? tiers[tierIndex] : Tier(99, 0, 0, "", marketPlaceFeeNoTier);
    }
    
    function getBatchTiers(address[] memory _wallets) public view returns(uint256[] memory) {
        uint256[] memory tiers = new uint256[](_wallets.length);
        
        for(uint256 i=0; i < _wallets.length; i++){
            address wallet = _wallets[i];
            
            tiers[i] = getRealTimeTierWithDiamondHands(wallet).index;
        }
        
        return tiers;
    }
    
    function setTier(uint256 _tierIndex, uint256 _minRevo, uint256 _stakingAPRBonus, string memory _name, uint256 _marketplaceFee) public onlyOwner{
        tiers[_tierIndex].index = _tierIndex;
        tiers[_tierIndex].minRevoToHold = _minRevo;
        tiers[_tierIndex].stakingAPRBonus = _stakingAPRBonus;
        tiers[_tierIndex].name = _name;
        tiers[_tierIndex].marketplaceFee = _marketplaceFee;
    }
    
    /*
    Set revo Address & token
    */
    function setRevoToken(address _revo) public onlyOwner {
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
    
    /*
    Set revoPoolManager Address & Interface
    */
    function setRevoPoolManager(address _revoPoolManager) public onlyOwner {
        revoPoolManagerAddress = _revoPoolManager;
        revoPoolManager = IRevoPoolManagerContract(_revoPoolManager);
    }
    
    /*
    Set revoNFTToken Interface
    */
    function setRevoNFTToken(address _revoNFTToken) public onlyOwner {
        revoNFTToken = IRevoNFTToken(_revoNFTToken);
    }
    
    /*
    Set revoPoolManager Address & Interface
    */
    function setNftBoostEnable(bool _enable) public onlyOwner {
        nftBoostEnabled = _enable;
    }
    
    /*
    Enable or disable cake v2 pool Balance
    */
    function setLiquidityBalanceEnable(bool _enable) public onlyOwner{
        liquidityBalanceEnabled = _enable;
    }
    
    /*
    Enable or disable staking pools Balance
    */
    function setStakingBalanceEnable(bool _enable) public onlyOwner{
        stakingBalanceEnabled = _enable;
    }
    
    /*
    Set maxime tier index to be eligible for tier boost
    */
    function setMaxTierIndexBoost(uint256 _index) public onlyOwner{
        maxTierIndexBoost = _index;
    }

    /*
    Set revo tier Address & contract
    */
    function setRevoNFTStaking(address _revoNFTStaking) public onlyOwner {
        revoNFTStaking = IRevoNFTStaking(_revoNFTStaking);
    }
    
    function getTier(uint256 _index) public view returns(Tier memory){
        return tiers[_index];
    }
    
    function getTiers() public view returns(Tier[] memory){
        Tier[] memory tiersToReturn = new Tier[](6);
        for(uint256 i = 0; i < tiers.length; i++){
            tiersToReturn[i] = tiers[i];
        }
        return tiersToReturn;
    }

    function setMarketPlaceFeeNoTier(uint256 _fee) public onlyOwner{
        marketPlaceFeeNoTier = _fee;
    }
    
    /*
    UTILS
    */
    function getTokensFromLiquidity(address _wallet, bool _isRevo) public view returns(uint256){
        uint256 revoPoolTokens;
        uint256 bnbPoolTokens;
        
        uint256 lpTokensAmount = revoLib.getLpTokens(_wallet).add(revoPoolManager.getLPStakedFromFarmingPools(_wallet));
        
        (revoPoolTokens, bnbPoolTokens) = revoLib.getLiquidityValue(lpTokensAmount);
        
        return _isRevo ? revoPoolTokens : bnbPoolTokens;
    }
    
    function getTokensFromStaking(address _wallet) public view returns(uint256){
        return revoPoolManager.getRevoStakedFromStakingPools(_wallet);
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