pragma solidity =0.8.0;

interface IRevoTokenContract{
  function balanceOf(address account) external view returns (uint256);
  function totalSupply() external view returns (uint256);
  function transfer(address recipient, uint256 amount) external returns (bool);
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
  function allowance(address owner, address spender) external view returns (uint256);
  function approve(address spender, uint256 amount) external returns (bool);
}

interface IRevoStakingContract{
    struct Stake {
        uint256 stakedAmount;
        uint256 startTime;
        uint256 poolIndex;
        uint256 tierIndex;
        uint256 reward;
        uint256 harvested;
        bool withdrawStake;
    }
    
    function getUserStakes(address _user) external view returns (Stake[] memory);
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

contract RevoPoolManager is Ownable{
    using SafeMath for uint256;
    
    //Revo Token
    address public revoAddress;
    IRevoTokenContract revoToken;
    //Staking pools
    address[] public stakingPools;
    //Farming pools
    address[] public farmingPools;
    
    constructor(address _revoAddress) {
        setRevo(_revoAddress);
    }
    
    /*
    Returns the amount of Revo staked from all staking pools accross all contracts
    */
    function getRevoStakedFromStakingPools(address _wallet) public view returns(uint256) {
        uint256 revoStaked;
        for(uint256 i = 0; i < stakingPools.length; i++){
            if(stakingPools[i] != 0x0000000000000000000000000000000000000000){
                IRevoStakingContract.Stake[] memory stakes = IRevoStakingContract(stakingPools[i]).getUserStakes(_wallet);
                for(uint256 s = 0; s < stakes.length; s++){ 
                    revoStaked = revoStaked.add(stakes[i].stakedAmount);
                }
            }
        }
        return revoStaked;
    }
    
    /*
    Returns the amount of LP tokens staked from all farming pools
    */
    function getLPStakedFromFarmingPools(address _wallet) public view returns(uint256) {
        uint256 lpStaked;
        for(uint256 i = 0; i < farmingPools.length; i++){
            if(farmingPools[i] != 0x0000000000000000000000000000000000000000){
                // TODO
                //lpStaked = lpStaked.add()
            }
        }
        return lpStaked;
    }
    
    /*
    Add an address in pools array
    */
    function addPoolAddress(address _address, bool _isFarming) public onlyOwner {
        (_isFarming ? farmingPools : stakingPools).push(_address);
    }
    
    /*
    Remove an address in pools array
    */
    function removePoolAddress(address _address, bool _isFarming) public onlyOwner {
        uint256 index = 99999999;
        address[] storage addresses = (_isFarming ? farmingPools : stakingPools);
        for(uint256 i = 0; i < addresses.length; i++){
            if(addresses[i] == _address){
                index = i;
            }
        }
        if(index < 99999999){
            delete addresses[index];
        }
    }
    
    /*
    Set revo Address & token
    */
    function setRevo(address _revo) public onlyOwner {
        revoAddress = _revo;
        revoToken = IRevoTokenContract(revoAddress);
    }
    
    function getPools(bool _isFarming) public view returns(address[] memory) {
        return _isFarming ? farmingPools : stakingPools;
    }
}