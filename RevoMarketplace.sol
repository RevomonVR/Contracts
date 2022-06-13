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
    function getRealTimeTierWithDiamondHands(address _wallet) external view returns(Tier memory);
    
    struct Tier {
        uint256 index;
        uint256 minRevoToHold;
        uint256 stakingAPRBonus;
        string name;
    }
}

interface IRevoNFT{
    struct Token {
        string collection;
        string dbId;
        uint256 tokenId;
    }
    
    function nftsDbIds(string memory _collection, string memory _dbId) external view returns (uint256);
    function getTokensDbIdByOwnerAndCollection(address _owner, string memory _collection) external view returns(string[] memory ownerTokensDbId);
    function burn(uint256 tokenId) external;
    function transferFrom(address from, address to, uint256 tokenId) external;
    function getTokensByOwner(address _owner) external view returns(Token[] memory ownerTokens);
    function ownerOf(uint256 tokenId) external returns(address);
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
    address public _owner2;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    function getOwner2() public view returns (address) {
        return _owner2;
    }

    function setOwner2(address _owner) public onlyOwner{
        _owner2 = _owner;
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


/**
 * @title Revo full staking contract
 * @author Maxime Reynders
 */
contract RevoMarketplace is Ownable {
    using SafeMath for uint256;

    //Revo Token
    address public revoAddress;
    IRevoTokenContract revoToken;
    IRevoTierContract revoTier;
    IRevoNFT revoNFT;
    //Revo lib
    IRevoLib revoLib;

    bool public emergencyRightBurned;

    uint256 public firstPending;
    uint256 public lastPending;
    //tier fees
    uint256[7] tierFees;
    uint256 salesUniqueId;
    uint256 buyUniqueId;
    uint256 saleUniqueId;

    //PENDING BUY
    PENDING_SALE[] public saleHistory;
    PENDING_SALE[] public buyHistory;
    mapping(uint256 => PENDING_SALE) tokenSales;

    struct PENDING_SALE {
        uint256 tokenId;
        uint256 saleUniqueId;
        uint256 buyUniqueId;
        uint256 revoAmount;
        uint256 bnbAmount;
        address seller;
        address buyer;
        bool sold;
    }


    //EVENTS TODDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDoooooooooooooooooo
    //event StakeEvent(uint256 revoAmount, address wallet);

    constructor(address _revoLibAddress, address _revoNFT, address _revoTier) {
        setRevoLib(_revoLibAddress);
        setRevo(revoLib.tokenRevoAddress());
        setRevoNFT(_revoNFT);
        setRevoTier(_revoTier);

        setTierFees(0, 35);//Trainee
        setTierFees(1, 30);//Tamer
        setTierFees(2, 25);//Ranger
        setTierFees(3, 20);//Veteran
        setTierFees(4, 15);//Elite
        setTierFees(5, 0);//Master
        setTierFees(6, 4);//No tier
    }

    function putNFTForSale(uint256 _tokenId, uint256 _revoAmount, uint256 _bnbAmount) public {
        require(revoNFT.ownerOf(_tokenId) == msg.sender, "Seller must be the owner");

        PENDING_SALE memory sale = PENDING_SALE(_tokenId, saleUniqueId, 0, _revoAmount, _bnbAmount, msg.sender, address(0), false);

        tokenSales[_tokenId] = sale;

        saleHistory.push(sale);

        saleUniqueId++;
    }

    function buyNFT(uint256 _tokenId) public {
        innerBuyNFT(_tokenId, false);
    }

    function buyNFTBNB(uint256 _tokenId) public payable { 
        innerBuyNFT(_tokenId, true);
    }

    
    function innerBuyNFT(uint256 _tokenId, bool _isBnb) private {
        require(!_isBnb ? tokenSales[_tokenId].revoAmount > 0 : tokenSales[_tokenId].bnbAmount > 0, "Please use the right currency");

        IRevoTierContract.Tier memory userTier = revoTier.getRealTimeTierWithDiamondHands(tokenSales[_tokenId].seller);

        uint256 nftPrice = (!_isBnb ? tokenSales[_tokenId].revoAmount : tokenSales[_tokenId].bnbAmount);
        
        uint256 fees = calculatePercentage(nftPrice, tierFees[userTier.index < 6 ? userTier.index : 6], 1000000).div(10);

        nftPrice = nftPrice - fees;

        if(!_isBnb){
            //1. Transfer amount to owner
            revoToken.transferFrom(msg.sender, tokenSales[_tokenId].seller, nftPrice);

            //2. PAY FEES
            revoToken.transferFrom(msg.sender, address(this), fees);
        }else{
            //Check if BNB amount is correct
            require(msg.value == tokenSales[_tokenId].bnbAmount, "Send the correct amount of BNB");

            //1. Transfer amount to owner
            payable(address(tokenSales[_tokenId].seller)).transfer(nftPrice);

            //2. PAY FEES
            //Nothing to do already in contract
        }
        

        //3. Transfer NFT to buyer
        revoNFT.transferFrom(tokenSales[_tokenId].seller, msg.sender, _tokenId);

        tokenSales[_tokenId].sold = true;

        PENDING_SALE memory sale = PENDING_SALE(tokenSales[_tokenId].tokenId, tokenSales[_tokenId].saleUniqueId, buyUniqueId, tokenSales[_tokenId].revoAmount, tokenSales[_tokenId].bnbAmount, tokenSales[_tokenId].seller, msg.sender, true);
        buyHistory.push(sale);

        buyUniqueId++;
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
        revoLib = IRevoLib(_revoLib);
    }

    function setRevoNFT(address _revoNFT) public onlyOwner {
        revoNFT = IRevoNFT(_revoNFT);
    }

    /*
    Set revo tier Address & contract
    */
    function setRevoTier(address _revoTier) public onlyOwner {
        revoTier = IRevoTierContract(_revoTier);
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

    function setTierFees(uint256 _tier, uint256 _fee) public onlyOwner {
        tierFees[_tier] = _fee;
    }

    function calculatePercentage(uint256 amount, uint256 percentage, uint256 precision) public pure returns(uint256){
        return amount.mul(precision).mul(percentage).div(100).div(precision);
    }
}
