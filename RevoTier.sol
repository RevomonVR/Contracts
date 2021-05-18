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
  function tokenRevoAddress() external returns (address);
}

interface IRevoPoolManagerContract{
  function getRevoStakedFromStakingPools(address wallet) external view returns (uint256);
  function getLPStakedFromFarmingPools(address wallet) external view returns (uint256);
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

//Factory : 0xcA143Ce32Fe78f1f7019d7d551a6402fC5350c73
// Deployed contract 0x211733993aB13A135e2BD80C381b5145185570C7
contract RevoTier is Ownable{
    using SafeMath for uint256;
    
    //TIER Struct
    struct Tier {
        uint256 index;
        uint256 minRevoToHold;
        uint256 stakingAPRBonus;
        string name;
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
    //Tiers
    Tier[6] public tiers;
    
    //Enable or disable balance fetch
    bool public liquidityBalanceEnabled;
    bool public stakingBalanceEnabled;
    //Boost tier + 1 
    bool public nftBoostEnabled;
    //Max Tier boost 
    uint256 maxTierIndexBoost;
    
    
    constructor(address _revoLibAddress, address _revoPoolManager) {
        setRevoLib(_revoLibAddress);
        setRevoToken(revoLib.tokenRevoAddress());
        setRevoPoolManager(_revoPoolManager);
        //Enable liquidity balance
        setLiquidityBalanceEnable(true);
        //Enable staking balance
        setStakingBalanceEnable(true);
        //Enable NFT Tier boost 
        setNftBoostEnable(false);
        //Set Max tier index boost to 3 included
        setMaxTierIndexBoost(3);
        
        //Tiers
        setTier(0, 1000000000000000000000, 0,  "Trainee");
        setTier(1, 2500000000000000000000, 25, "Tamer");
        setTier(2, 5000000000000000000000, 50, "Ranger");
        setTier(3, 10000000000000000000000, 60, "Veteran");
        setTier(4, 25000000000000000000000, 70, "Elite");
        setTier(5, 100000000000000000000000, 80, "Master");
    }
    
    
    function getRealTimeTier(address _wallet) public view returns(Tier memory) {
        uint256 balance = revoToken.balanceOf(_wallet);
        
        //Get Revo from Cake V2 Pool & Farming pools 
        if(liquidityBalanceEnabled){
            //Get LP tokens from wallet balance & farming pools
            balance = balance.add(getTokensFromLiquidity(msg.sender, true));
        }
        
        //Get Revo from staking pools
        if(stakingBalanceEnabled){
            balance = balance.add(getTokensFromStaking(msg.sender));
        }
        
        uint256 tierIndex = 9999;
        for(uint256 i = 0; i < tiers.length; i++){
            if(balance >= tiers[i].minRevoToHold){
                tierIndex = i;
            }
        }
        
        if(nftBoostEnabled && tierIndex <= maxTierIndexBoost){
            //TODO 
            tierIndex = tierIndex.add(1);
        }
        
        return tierIndex < 9999 ? tiers[tierIndex] : Tier(99, 0, 0, "");
    }
    
    function setTier(uint256 _tierIndex, uint256 _minRevo, uint256 _stakingAPRBonus, string memory _name) public onlyOwner{
        tiers[_tierIndex].index = _tierIndex;
        tiers[_tierIndex].minRevoToHold = _minRevo;
        tiers[_tierIndex].stakingAPRBonus = _stakingAPRBonus;
        tiers[_tierIndex].name = _name;
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
    
    function getTier(uint256 _index) public view returns(Tier memory){
        return tiers[_index];
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
    
}
