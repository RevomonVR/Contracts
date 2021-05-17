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
    function tiers() external view returns (Tier[6] memory);
    
    struct Tier {
        uint256 index;
        uint256 minRevoToHold;
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
    
    struct Pool {
        string poolName;
        uint256 startTime;
        uint256 initialBalance;
        uint256 staked;
        uint256 duration;
        uint256 percentage;
        bool terminated;
        mapping(address => Stake) stakes;
    }
    
    struct Stake {
        uint256 stakedAmount;
        uint256 startTime;
        uint256 poolIndex;
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
    
    //EVENTS
    event StakeEvent(uint256 revoAmount, address wallet);

    //MODIFIERS
    modifier stakeProtection(uint256 _poolIndex, uint256 _revoAmount) {
        //Stake not done
        require(pools[_poolIndex].stakes[msg.sender].stakedAmount == 0, "Stake already done");
        
        IRevoTierContract.Tier memory userTier = revoTier.getRealTimeTier(msg.sender);
        IRevoTierContract.Tier[6] memory tiers = revoTier.tiers();
        
        //User must belong to at least the first tier
        require(userTier.minRevoToHold > 0, "User must belong to a tier");
        
        //Minimum amount >= minRevoToHold of the tier && Maximum amount < minRevoToHold of the tier + 1 
        if(userTier.index < 5){
            require(_revoAmount >= userTier.minRevoToHold && _revoAmount < tiers[userTier.index + 1].minRevoToHold, "Amount to stake must be in tier range");
        }else{
            //No max amount for the last tier
            require(_revoAmount >= userTier.minRevoToHold, "Amount to stake must be in tier range");
        }(t)
        _;
    }
    
    constructor(address _revoAddress, address _revoTier) {
        setRevo(_revoAddress);
        setRevoTier(_revoTier);
        
        createPool("Pool 1", 1000000000000000000000000, 2678400, 2123);
        createPool("Pool 2", 10000000000000000000000001, 8035200, 10192);
        createPool("Pool 3", 1000000000000000000000000, 16070400, 25479);
    }
    
    /****************************
            POOLS functions
    *****************************/
    
    /*
    Add a new pool to a new incremented index
    */
    function createPool(string memory _name, uint256 _balance, uint256 _duration, uint256 _percentage) public onlyOwner {
        updatePool(poolIndex, _name, _balance, _duration, _percentage);
        poolIndex++;
    }
    
    /*
    Update a pool to specific index
    */
    function updatePool(uint256 _index, string memory _name, uint256 _balance, uint256 _duration, uint256 _percentage) public onlyOwner {
        pools[_index].poolName = _name;
        pools[_index].initialBalance = _balance;
        pools[_index].duration = _duration;
        pools[_index].percentage = _percentage;
    }
    
    /*
    Update terminated variable in pool at a specific index
    */
    function updateTerminated(uint256 _index, bool _terminated) public onlyOwner {
        pools[_index].terminated = _terminated;
    }
    
    /****************************
            STAKE functions
    *****************************/
    
    function stake(uint256 _poolIndex, uint256 _revoAmount) public stakeProtection(_poolIndex, _revoAmount) {
        revoToken.transferFrom(msg.sender, address(this), _revoAmount);
        
        pools[_poolIndex].stakes[msg.sender].stakedAmount = _revoAmount;
        pools[_poolIndex].stakes[msg.sender].startTime = block.timestamp;
        pools[_poolIndex].stakes[msg.sender].poolIndex = _poolIndex;
        
        
        emit StakeEvent(_revoAmount, msg.sender);
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
                stakes[index] = Stake(s.stakedAmount, s.startTime, s.poolIndex, s.withdrawStake);
                index++;
            }
        }
        
        return stakes;
    }
    
    function getUserStake(uint256 _poolIndex, address _user) public view returns(Stake memory){
        return pools[_poolIndex].stakes[_user];
    }
    
     /*
    Update staking info
    */
    /*function updateStaking(uint256 _index, uint256 _duration, uint256 _percentage) public onlyOwner{
        staking[_index].duration = _duration;
        staking[_index].percentage = _percentage;
    }*/
}