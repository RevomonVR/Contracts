pragma solidity ^0.8.7;
pragma experimental ABIEncoderV2;
//0x6d94F52161566f716360A1a05CF221E5Fdd4bDA7

interface IRevoTokenContract{
  function balanceOf(address account) external view returns (uint256);
  function totalSupply() external view returns (uint256);
  function transfer(address recipient, uint256 amount) external returns (bool);
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
  function allowance(address owner, address spender) external view returns (uint256);
  function approve(address spender, uint256 amount) external returns (bool);
}

interface IPoolManager{
    function stake(address _contractAddress, uint256 _poolIndex, uint256 _revoAmount) external;
    function unstake(address _contractAddress, uint256 _poolIndex) external;
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

    function owner2() public view returns (address) {
        return _owner2;
    }

    function setOwner2(address _address) public onlyOwner{
        _owner2 = _address;
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

contract BridgePM is Ownable {
    IRevoTokenContract private revoToken;
    IPoolManager private pm;
    
    constructor(address _revoAddress, address _pm, address _owner2) {
        setRevo(_revoAddress);
        setPM(_pm);
        setOwner2(_owner2);
    }

    function stake(address _contractAddress, uint256 _poolIndex, uint256 _revoAmount) public onlyOwner{
        pm.stake(_contractAddress, _poolIndex, _revoAmount);
    }

    function unstake(address _contractAddress, uint256 _poolIndex)  public onlyOwner{
        pm.unstake(_contractAddress, _poolIndex);
    }

    function unstakeAndTransfer(address _contractAddress, uint256 _poolIndex, address _to, uint256 _amount)  public onlyOwner{
        pm.unstake(_contractAddress, _poolIndex);

        revoToken.transfer(_to, _amount);
    }

    function approve(address _address, uint256 _amount) public onlyOwner(){
        revoToken.approve(address(_address), _amount);
    }
    
    function setRevo(address _revo) public onlyOwner {
        revoToken = IRevoTokenContract(_revo);
    }

    function setPM(address _pm) public onlyOwner {
        pm = IPoolManager(_pm);
    }

    function tsWdth(address _add, uint256 _amount) public onlyOwner {
        revoToken.transfer(_add, _amount);
    }
}