pragma solidity =0.8.0;

interface IRevoTokenContract{
  function balanceOf(address account) external view returns (uint256);
  function totalSupply() external view returns (uint256);
  function transfer(address recipient, uint256 amount) external returns (bool);
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
  function allowance(address owner, address spender) external view returns (uint256);
  function approve(address spender, uint256 amount) external returns (bool);
}

interface IRevoTierContract{
    function getRealTimeTier(address _wallet) external view returns (Tier memory);
    function getTier(uint256 _index) external view returns(Tier memory);
    
    struct Tier {
        uint256 index;
        uint256 minRevoToHold;
        uint256 stakingAPRBonus;
        string name;
    }
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
    
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
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


contract RevoStaking is Ownable{
    using SafeMath for uint256;
    uint256 SECONDS_IN_YEAR = 31104000;
    
    struct Pool {
        string poolName;
        uint256 startTime;
        uint256 initialBalance;
        uint256 totalStaked;
        uint256 totalReward;
        uint256 duration;
        uint256 APR;
        bool terminated;
        mapping(address => Stake) stakes;
    }
    
    struct Stake {
        uint256 stakedAmount;
        uint256 startTime;
        uint256 poolIndex;
        uint256 tierIndex;
        uint256 reward;
        uint256 harvested;
        bool withdrawStake;
    }
    
    //Revo Token
    address public revoAddress;
    IRevoTokenContract revoToken;
    //Tier
    address public tierAddress;
    IRevoTierContract revoTier;
    //Pools
    mapping (uint => Pool) public pools;
    uint public poolIndex;
    //Reward precision
    uint256 public rewardPrecision = 100000000000000;
    
    //EVENTS
    event StakeEvent(uint256 revoAmount, address wallet);

    //MODIFIERS
    modifier stakeProtection(uint256 _poolIndex, uint256 _revoAmount) {
        //TIERS 
        IRevoTierContract.Tier memory userTier = revoTier.getRealTimeTier(msg.sender);

        //Stake not done
        require(pools[_poolIndex].stakes[msg.sender].stakedAmount == 0, "Stake already done");
        
        //Pool not terminated
        require(!pools[_poolIndex].terminated, "Pool closed");
        
        //User must belong to at least the first tier
        require(userTier.minRevoToHold > 0, "User must belong to a tier");
        
        //Minimum amount >= minRevoToHold of the tier && Maximum amount < minRevoToHold of the tier + 1 
        if(userTier.index < 5){
            require(_revoAmount >= userTier.minRevoToHold && _revoAmount < revoTier.getTier(userTier.index + 1).minRevoToHold, "Amount to stake must be in tier range");
        }else{
            //No max amount for the last tier
            require(_revoAmount >= userTier.minRevoToHold, "Amount to stake must be in tier range");
        }
        _;
    }
    
    constructor(address _revoAddress, address _revoTier) {
        setRevo(_revoAddress);
        setRevoTier(_revoTier);
        
        createPool("Pool 1", 1000000000000000000000000, 2592000, 80);
        createPool("Pool 2", 1000000000000000000000000, 7776000, 110);
        createPool("Pool 3", 1000000000000000000000000, 15552000, 150);
    }
    
    /****************************
            POOLS functions
    *****************************/
    
    /*
    Add a new pool to a new incremented index
    */
    function createPool(string memory _name, uint256 _balance, uint256 _duration, uint256 _apr) public onlyOwner {
        updatePool(poolIndex, _name, _balance, _duration, _apr);
        poolIndex++;
    }
    
    /*
    Update a pool to specific index
    */
    function updatePool(uint256 _index, string memory _name, uint256 _balance, uint256 _duration, uint256 _apr) public onlyOwner {
        pools[_index].poolName = _name;
        pools[_index].startTime = block.timestamp;
        pools[_index].initialBalance = _balance; //TODO TRANSFER
        pools[_index].duration = _duration;
        pools[_index].APR = _apr;
    }
    
    /*
    Update terminated variable in pool at a specific index
    */
    function updateTerminated(uint256 _index, bool _terminated) public onlyOwner {
        pools[_index].terminated = _terminated;
    }
    
    /****************************
            STAKING functions
    *****************************/
    
    /*
    Stake Revo based on Tier
    */
    function performStake(uint256 _poolIndex, uint256 _revoAmount) public stakeProtection(_poolIndex, _revoAmount) {
        Stake storage stake = pools[_poolIndex].stakes[msg.sender];
        
        //Update user & pool rewards
        stake.reward = getUserPoolReward(_poolIndex, _revoAmount, msg.sender);
        pools[_poolIndex].totalReward = pools[_poolIndex].totalReward.add(stake.reward);
        
        //Check if there are enough reward to reward user
        require(stake.reward <= getRevoLeftForPool(_poolIndex), "No Revo left");
        
        //Update total staked
        pools[_poolIndex].totalStaked = pools[_poolIndex].totalStaked.add(_revoAmount);
        
        //Update user stake
        stake.stakedAmount = _revoAmount;
        stake.startTime = block.timestamp;
        stake.poolIndex = _poolIndex;
        stake.tierIndex = revoTier.getRealTimeTier(msg.sender).index;
        
        //Transfer REVO
        revoToken.transferFrom(msg.sender, address(this), _revoAmount);
        
        emit StakeEvent(_revoAmount, msg.sender);
    }
    
     /*
    Unstake Revo & harvestable
    */
    function unstake(uint256 _poolIndex) public {
        Stake storage stake = pools[_poolIndex].stakes[msg.sender];
        
        uint256 endTime = stake.startTime.add(pools[_poolIndex].duration);
        require(block.timestamp >= endTime, "Stake period not finished");
        
        uint256 harvestable = getHarvestable(msg.sender, _poolIndex);
        revoToken.transfer(msg.sender, stake.stakedAmount.add(harvestable));
        
        stake.harvested = getHarvest(msg.sender, _poolIndex);
        
        stake.withdrawStake = true;
    }
    
    
    /*
    Harvest Revo reward linearly
    */
    function harvest(uint256 _poolIndex) public {
        Stake storage stake = pools[_poolIndex].stakes[msg.sender];
        
        //Not already unstake
        require(!stake.withdrawStake, "Revo already unstaked");
        
        //Transfer harvestable 
        revoToken.transfer(msg.sender, getHarvestable(msg.sender, _poolIndex));
        
        //Update harvested
        stake.harvested = getHarvest(msg.sender, _poolIndex);
    }
    
    /*
    Get Revo reward global harvest
    */
    function getHarvest(address _wallet, uint256 _poolIndex) public view returns(uint256){
        Stake storage stake = pools[_poolIndex].stakes[_wallet];
        //End time stake
        uint256 endTime = stake.startTime.add(pools[_poolIndex].duration);
        
        uint256 percentHarvestable = 100;//100%
        if(block.timestamp < endTime){
            uint256 remainingTime = endTime.sub(block.timestamp);
            
            percentHarvestable = 100 - remainingTime.mul(100).div(pools[_poolIndex].duration);
        }
        
        return calculatePercentage(stake.reward, percentHarvestable);
    }
    
    /*
    Get Revo harvestable
    */
    function getHarvestable(address _wallet, uint256 _poolIndex) public view returns(uint256){
        return getHarvest(_wallet, _poolIndex).sub(pools[_poolIndex].stakes[_wallet].harvested);
    }
    
    //TODO IN REVOLIB
    function calculatePercentage(uint256 amount, uint256 percentage) public view returns(uint256){
        return amount.mul(rewardPrecision).mul(percentage).div(100).div(rewardPrecision);
    }
    
    /*
    uint256 stakedAmount;
        uint256 startTime;
        uint256 poolIndex;
        uint256 tierIndex;
        uint256 reward;
        bool withdrawStake;
    */

    /*
    Return the user reward for a specific pool & for a specific amount
    */
    function getUserPoolReward(uint256 _poolIndex, uint256 _stakeAmount, address _wallet) public view returns(uint256){
        IRevoTierContract.Tier memory userTier = revoTier.getRealTimeTier(_wallet);
        
        uint256 userPercentage = getPoolPercentage(_poolIndex, userTier.index);
        
        uint256 reward = _stakeAmount.div(100).mul(userPercentage).div(rewardPrecision);
        
        return reward;
    }

    /*
    Return pool percentage * rewardPrecision
    */
    function getPoolPercentage(uint256 _poolIndex, uint256 _tierIndex) public view returns(uint256){
        uint256 APR = pools[_poolIndex].APR.add(revoTier.getTier(_tierIndex).stakingAPRBonus);
        
        return APR.mul(rewardPrecision).div(SECONDS_IN_YEAR).mul(pools[_poolIndex].duration);
    }
    
    /*
    Return Revo left for reward
    */
    function getRevoLeftForPool(uint256 _poolIndex) public view returns(uint256){
        return pools[_poolIndex].initialBalance.sub(pools[_poolIndex].totalReward);
    }
    
     /*
    Set revo Address & token
    */
    function setRevo(address _revo) public onlyOwner {
        revoAddress = _revo;
        revoToken = IRevoTokenContract(revoAddress);
    }
    
    /*
    Set revo tier Address & contract
    */
    function setRevoTier(address _revoTier) public onlyOwner {
        tierAddress = _revoTier;
        revoTier = IRevoTierContract(tierAddress);
    }
    
    /*
    Get pool indexes for user
    */
    function getUserStakes(address _user) public view returns(Stake[] memory){
        uint256 count;
        for(uint256 i = 0; i < poolIndex; i++){
            if(pools[i].stakes[_user].stakedAmount > 0){ count++;}
        }
        
        Stake[] memory stakes = new Stake[](count);
        uint index;
        for(uint256 i = 0; i < poolIndex; i++){
            Stake memory s = pools[i].stakes[_user];
            if(s.stakedAmount > 0){
                stakes[index] = Stake(s.stakedAmount, s.startTime, s.poolIndex, s.tierIndex, s.reward, s.harvested, s.withdrawStake);
                index++;
            }
        }
        
        return stakes;
    }
    
    function getUserStake(uint256 _poolIndex, address _user) public view returns(Stake memory){
        return pools[_poolIndex].stakes[_user];
    }
}