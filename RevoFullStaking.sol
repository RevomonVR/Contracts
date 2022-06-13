// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.3;
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
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

contract Context {
    constructor () { }

    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; 
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;
    address public _poolManager;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    function getPoolManager() public view returns (address) {
        return _poolManager;
    }

    function setPoolManager(address _pm) public onlyOwner{
        _poolManager = _pm;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender() || _poolManager == _msgSender(), "Ownable: caller is not the owner");
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


/**
 * @title DeFi Of Thrones Mana Pool Contract
 * @author Maxime Reynders - DefiOfThrones (https://github.com/DefiOfThrones/DOTTokenContract)
 */
contract RevoFullStaking is Ownable {
    uint256 SECONDS_IN_YEAR = 31104000;
    using SafeMath for uint256;

    struct Pool {
        string poolName;
        uint256 poolIndex;
        uint256 startTime;
        uint256 totalReward;
        uint256 totalStaked;
        uint256 currentReward;
        uint256 duration;
        uint256 APR;
        bool terminated;
        uint256 maxRevoStaking;
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
    //Revo lib
    address public revoLibAddress;
    IRevoLib revoLib;
    //Tier
    address public tierAddress;
    IRevoTierContract revoTier;
    //Emergency right
    bool public emergencyRightBurned;

    uint public poolIndex;
    uint256 public rewardPrecision = 1000000000000000000;

    //Pools
    mapping (uint => Pool) public pools;
    mapping(uint256 => mapping(address => Stake)) public stakes;

    //EVENTS
    event StakeEvent(uint256 revoAmount, address wallet);
    event HarvestEvent(uint256 revoAmount, address wallet);
    event UnstakeEvent(uint256 revoStakeAmount, uint256 revoHarvestAmount, address wallet);

    //MODIFIERS
    modifier stakeProtection(uint256 _poolIndex, uint256 _revoAmount, address _wallet) {
        //TIERS 
        IRevoTierContract.Tier memory userTier = revoTier.getRealTimeTier(_wallet);

        //Pool not terminated
        require(!pools[_poolIndex].terminated, "Pool closed");
        
        //User must belong to at least the first tier
        require(userTier.minRevoToHold > 0, "User must belong to a tier");
        
        //Max Revo amount to stake 
        require(stakes[_poolIndex][_wallet].stakedAmount.add(_revoAmount) <= pools[_poolIndex].maxRevoStaking, "Please stake less than the max amount");
        
        //Stake more than 0
        require(_revoAmount > 0, "Please stake more than 0 Revo");
        
        _;
    }

    constructor(address _revoLibAddress, address _revoTier, address _poolManagerAddress) {
        setRevoLib(_revoLibAddress);
        setRevo(revoLib.tokenRevoAddress());
        setRevoTier(_revoTier);
        setPoolManager(_poolManagerAddress);
    }

    /*
    Create a new pool to a new incremented index + transfer Revo to it
    */
    function createPool(string memory _name, uint256 _balance, uint256 _duration, uint256 _apr, uint256 _maxRevoStaking) public onlyOwner {
        updatePool(poolIndex, _name, _balance, _duration, _apr, _maxRevoStaking);
        poolIndex++;
    }
    
    /*
    Update a pool to specific index
    */
    function updatePool(uint256 _index, string memory _name, uint256 _balance, uint256 _duration, uint256 _apr, uint256 _maxRevoStaking) public onlyOwner {
        pools[_index].poolName = _name;
        pools[_index].poolIndex = _index;
        pools[_index].startTime = block.timestamp;
        pools[_index].totalReward = _balance;
        pools[_index].APR = _apr;

        pools[_index].maxRevoStaking = _maxRevoStaking;
        

        if(pools[_index].currentReward < pools[_index].totalReward){
            addReward(pools[_index].totalReward.sub(pools[_index].currentReward), _index);  
        }
    }

    /*
    Add revo Reward
    */
    function addReward(uint256 _revoAmount, uint256 _poolIndex) public onlyOwner {
        //Transfer REVO
        pools[_poolIndex].currentReward = pools[_poolIndex].currentReward.add(_revoAmount);
        revoToken.transferFrom(msg.sender, address(this), _revoAmount);
    }

    /****************************
            STAKING functions
    *****************************/
    /*
    Stake Revo based on Tier
    */
    function performStake(uint256 _poolIndex, uint256 _revoAmount, address _wallet) public stakeProtection(_poolIndex, _revoAmount, _wallet) onlyOwner {
        Stake storage stake = stakes[_poolIndex][_wallet];
        
        //Update user stake tier index <!> Before update stakedAmount
        stake.tierIndex = revoTier.getRealTimeTier(_wallet).index;

        //1. Harvest if available
        if(stake.stakedAmount > 0){
            harvest(_poolIndex, _wallet);
        }

        //2. Update stake amount & start time & pool index for user stake
        stake.stakedAmount = stake.stakedAmount.add(_revoAmount);
        stake.startTime = block.timestamp;
        stake.poolIndex = _poolIndex;
        stake.withdrawStake = false;
        
        //3. Update total staked
        pools[_poolIndex].totalStaked = pools[_poolIndex].totalStaked.add(_revoAmount);
        
        //4. Transfer REVO
        revoToken.transferFrom(_wallet, address(this), _revoAmount);
        
        emit StakeEvent(_revoAmount, _wallet);
    }

     /*
    Unstake Revo & harvestable
    */
    function unstake(uint256 _poolIndex, address _wallet) public onlyOwner {
        Stake storage stake = stakes[_poolIndex][_wallet];
        
        //Not already unstake
        require(!stake.withdrawStake, "Revo already unstaked");
        stake.withdrawStake = true;
        
        uint256 harvestable = getHarvestable(_wallet, _poolIndex);

        //Update total staked
        pools[_poolIndex].totalStaked = pools[_poolIndex].totalStaked.sub(stake.stakedAmount);

        //Enough reward
        require(pools[_poolIndex].currentReward.sub(harvestable) > 0, "Not enough reward in contract");
        pools[_poolIndex].currentReward = pools[_poolIndex].currentReward.sub(harvestable);

        revoToken.transfer(_wallet, stake.stakedAmount.add(harvestable));
        
        emit UnstakeEvent(stake.stakedAmount, harvestable, _wallet);
        
        stake.harvested = stake.harvested.add(harvestable);

        stake.stakedAmount = 0;
    }

    /*
    Harvest Revo reward linearly
    */
    function harvest(uint256 _poolIndex, address _wallet) public onlyOwner {
        Stake storage stake = stakes[_poolIndex][_wallet];
        
        //Not already unstake
        require(!stake.withdrawStake, "Revo already unstaked");
        
        //Get harvestable
        uint256 harvestable = getHarvest(_wallet, _poolIndex);

        //Enough reward
        require(pools[_poolIndex].currentReward.sub(harvestable) > 0, "Not enough reward in contract");
        pools[_poolIndex].currentReward = pools[_poolIndex].currentReward.sub(harvestable);

        //Transfer harvestable 
        revoToken.transfer(_wallet, harvestable);

        //reset start time
        stake.startTime = block.timestamp;

        //Update harvested
        stake.harvested = stake.harvested.add(harvestable);
        
        emit HarvestEvent(harvestable, _wallet);
    }

    function getHarvest(address _wallet, uint256 _poolIndex) public view returns(uint256 harvestable){
        Stake storage stake = stakes[_poolIndex][_wallet];
        
        uint256 rewardPerSecond = pools[_poolIndex].APR.mul(rewardPrecision).div(SECONDS_IN_YEAR);

        uint256 secondsElapsed = block.timestamp.sub(stake.startTime);
        uint256 rewardPercent = rewardPerSecond.mul(secondsElapsed);
        harvestable =  revoLib.calculatePercentage(stake.stakedAmount, rewardPercent, rewardPrecision, 100).div(rewardPrecision);
    }

    /*
    Get Revo harvestable
    */
    function getHarvestable(address _wallet, uint256 _poolIndex) public view returns(uint256){
        return getHarvest(_wallet, _poolIndex);
    }
    
    /*
    Return the user reward for a specific pool & for a specific amount
    */
    function getUserPoolReward(uint256 _poolIndex, uint256 _stakeAmount, address _wallet) public view returns(uint256){
        return 0; //Not implemented in dynamic staking
    }

    /*
    Get pool indexes for user
    */
    function getUserStakes(address _user) public view returns(Stake[] memory){
        uint256 count;
        for(uint256 i = 0; i < poolIndex; i++){
            if(stakes[i][_user].stakedAmount > 0){ count++;}
        }
        
        Stake[] memory stakesToReturn = new Stake[](count);
        uint index;
        for(uint256 i = 0; i < poolIndex; i++){
            Stake memory s = stakes[i][_user];
            if(s.stakedAmount > 0){
                stakesToReturn[index] = Stake(s.stakedAmount, s.startTime, s.poolIndex, s.tierIndex, s.reward, s.harvested, s.withdrawStake);
                index++;
            }
        }
        
        return stakesToReturn;
    }

    function getUserStake(uint256 _poolIndex, address _user) public view returns(Stake memory){
        return stakes[_poolIndex][_user];
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

    /*
    Set revo tier Address & contract
    */
    function setRevoTier(address _revoTier) public onlyOwner {
        tierAddress = _revoTier;
        revoTier = IRevoTierContract(tierAddress);
    }

    /*
    Emergency transfer Revo
    */
    function withdrawRevo(uint256 _amount) public onlyOwner {
        if(!emergencyRightBurned){
            revoToken.transfer(owner(), _amount);
        }
    }

    function burnEmergencyRight() public onlyOwner {
        emergencyRightBurned = true;
    }

    /*
    Update terminated variable in pool at a specific index
    */
    function updateTerminated(uint256 _index, bool _terminated) public onlyOwner {
        pools[_index].terminated = _terminated;
    }

    function getAllPools() public view returns(Pool[] memory){
        Pool[] memory poolsToReturn = new Pool[](poolIndex);
        for(uint256 i = 0; i < poolIndex; i++){
            poolsToReturn[i] = pools[i];
        }
        
        return poolsToReturn;
    }
}
