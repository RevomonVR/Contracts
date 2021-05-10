pragma solidity >=0.5.0;

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
    constructor () public { }

    function _msgSender() internal view virtual returns (address payable) {
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

    constructor () public {
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
        uint256 minRevoToHold;
        string name;
    }
    
    //Revo Token
    address public revoAddress;
    IRevoTokenContract revoToken;
    //Revo lib
    address public revoLibAddress;
    IRevoLib revoLib;
    //Tiers
    Tier[] public tiers;
    
    //Condtions
    bool public poolBalanceEnabled;
    
    constructor(address _revoAddress, address _revoLibAddress) public {
        setRevo(_revoAddress);
        setRevo(_revoLibAddress);
        //Enable pool balance
        setPoolBalanceEnable(true);
        
        //tiers
        setTiers(0, 1000000000000000000000, "Trainee");
        setTiers(1, 2500000000000000000000, "Tamer");
        setTiers(2, 5000000000000000000000, "Ranger");
        setTiers(3, 10000000000000000000000, "Veteran");
        setTiers(4, 25000000000000000000000, "Elite");
        setTiers(5, 100000000000000000000000, "Master");
    }
    
    
    function getRealTimeTier(address _wallet) public view returns(uint256) {
        uint256 balance = revoToken.balanceOf(_wallet);
        
        if(poolBalanceEnabled){
            //If pool balance is enabled 
            uint256 revoPoolTokens;
            uint256 bnbPoolTokens;
            (revoPoolTokens, bnbPoolTokens) = revoLib.getLiquidityValue(revoLib.getLpTokens(msg.sender));
            
            balance.add(revoPoolTokens);
        }
        
        uint256 tierIndex;
        for(uint256 i = tiers.length - 1; i >= 1; i--){
            if(balance >= tiers[i].minRevoToHold){
                tierIndex = i;
            }
        }
        return tierIndex;
    }
    
    function setTiers(uint256 _tierIndex, uint256 _minRevo, string memory _name) public onlyOwner{
        tiers[_tierIndex].minRevoToHold = _minRevo;
        tiers[_tierIndex].name = _name;
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
    Enable or disable cake v2 pool Balance
    */
    function setPoolBalanceEnable(bool _enable) public onlyOwner{
        poolBalanceEnabled = _enable;
    }
}
