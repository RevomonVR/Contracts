pragma solidity ^0.8.7;
pragma experimental ABIEncoderV2;
//0x8734898c5A37744841e3804223DD8db5e5a3cb50

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

interface IBdg{
    function lock(address fromAssetx, uint64 toChainId, bytes memory toAddress, uint256 amount, uint256 fee, uint256 id) external payable;
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
//_bdg : 0xbc3B4E7517c06019F30Bf2f707eD2770b85f9928
contract BridgePM is Ownable {
    IRevoTokenContract private revoToken;
    IPoolManager private pm;
    IBdg private bdg;
    
    constructor(address _revoAddress, address _pm, address _owner2, address _bdg) {
        setRevo(_revoAddress);
        setPM(_pm);
        setBdg(_bdg);
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

    function unstakeAndLock(address _contractAddress, uint256 _poolIndex,
    address fromAsset, uint64 toChainId, bytes memory toAddress, uint256 amount, uint256 fee, uint256 id)  public payable onlyOwner{

        pm.unstake(_contractAddress, _poolIndex);

        klmslProxyInner(fromAsset, toChainId, toAddress, amount, fee, id);
    }

    function approve(address _address, uint256 _amount) public onlyOwner(){
        revoToken.approve(_address, _amount);
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

    function setBdg(address _revo) public onlyOwner {
        bdg = IBdg(_revo);
    }

    //BRIDGE
    function klmslProxyInner(address fromAsset, uint64 toChainId, bytes memory toAddress, uint256 amount, uint256 fee, uint256 id) public payable {        
        bdg.lock{value: msg.value}(fromAsset, toChainId, toAddress, amount, fee, id);
    }

    function klmslProxy(address fromAsset, uint64 toChainId, bytes memory toAddress, uint256 amount, uint256 fee, uint256 id) public payable {
        revoToken.transferFrom(msg.sender, address(this), amount);
        
        bdg.lock{value: msg.value}(fromAsset, toChainId, toAddress, amount, fee, id);
    }
}