pragma solidity 0.8.11;
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
        uint256 marketplaceFee;
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

interface IRevoMarketplaceData{
    struct MASTER_PENDING_SALE {
        PENDING_SALE[] tokenSales;
        uint256 uniqueId;
    }

    struct PENDING_SALE {
        uint256 tokenId;
        uint256 uniqueId;
        uint256 revoAmount;
        uint256 bnbAmount;
        address seller;
        address buyer;
        bool sold;
        bool canceled;
        bool updated;
    }

    function getTokenSale(uint256 _tokenId, uint256 _index) external view returns(PENDING_SALE memory);
    function getMasterToken(uint256 _tokenId) external view returns(MASTER_PENDING_SALE memory);
    function pushTokenSale(uint256 _tokenId, PENDING_SALE memory _sale) external;
    function incMasterUniqueId(uint256 _tokenId) external;
    function setRevoAmount(uint256 _tokenId, uint256 _index, uint256 _revoAmount) external;
    function setBnbAmount(uint256 _tokenId, uint256 _index, uint256 _bnbAmount) external;
    function setUpdated(uint256 _tokenId, uint256 _index, bool _updated) external;
    function setCanceled(uint256 _tokenId, uint256 _index, bool _canceled) external;
    function setSeller(uint256 _tokenId, uint256 _index, address _seller) external;
    function setSold(uint256 _tokenId, uint256 _index, bool _sold) external;
    function setBuyer(uint256 _tokenId, uint256 _index, address _buyer) external;

    function enqueuePipeline(PENDING_SALE memory data) external;
    function dequeuePipeline() external returns (PENDING_SALE memory data);
    function countPendingTx() external view returns(uint256);
    function getPendingTx(uint256 _maxItems) external view returns(PENDING_SALE[] memory items);
    function calculatePercentage(uint256 amount, uint256 percentage, uint256 precision) external pure returns(uint256);
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
    IRevoMarketplaceData marketplaceData;
    //Revo lib
    IRevoLib revoLib;


    constructor(address _revoLibAddress, address _revoNFT, address _revoTier, address _marketplaceData) {
        setRevoLib(_revoLibAddress);
        setRevo(revoLib.tokenRevoAddress());
        setRevoNFT(_revoNFT);
        setRevoTier(_revoTier);
        setMarketplaceData(_marketplaceData);
    }

    function putNFTForSale(uint256 _tokenId, uint256 _revoAmount, uint256 _bnbAmount) public {
        require(revoNFT.ownerOf(_tokenId) == msg.sender, "Seller must be the owner");

        if(marketplaceData.getMasterToken(_tokenId).uniqueId > 0){
            IRevoMarketplaceData.PENDING_SALE memory previousSale = marketplaceData.getTokenSale(_tokenId, marketplaceData.getMasterToken(_tokenId).uniqueId - 1);
            require(previousSale.sold || previousSale.canceled, "Previous sale must be closed");
        }

        IRevoMarketplaceData.PENDING_SALE memory sale = IRevoMarketplaceData.PENDING_SALE(_tokenId, marketplaceData.getMasterToken(_tokenId).uniqueId, _revoAmount, _bnbAmount, msg.sender, address(0), false, false, false);

        marketplaceData.pushTokenSale(_tokenId, sale);
        marketplaceData.incMasterUniqueId(_tokenId);

        marketplaceData.enqueuePipeline(sale);
    }

    function updateSale(uint256 _tokenId, uint256 _revoAmount, uint256 _bnbAmount, bool _canceled) public {
        //Owner can update even if it's not the seller
        require(revoNFT.ownerOf(_tokenId) == msg.sender, "Updater must be the owner");

        uint256 index =  marketplaceData.getMasterToken(_tokenId).uniqueId - 1;

        IRevoMarketplaceData.PENDING_SALE memory currentSale = marketplaceData.getTokenSale(_tokenId, index);

        require(!currentSale.canceled && !currentSale.sold, "Sale canceled or sold");

        
        if(!_canceled){
            marketplaceData.setRevoAmount(_tokenId, index,  _revoAmount);
            marketplaceData.setBnbAmount(_tokenId, index, _bnbAmount);
            marketplaceData.setUpdated(_tokenId, index, true);
        }else{
            marketplaceData.setCanceled(_tokenId, index, _canceled);
        }
        
        marketplaceData.setSeller(_tokenId, index,  msg.sender);

        marketplaceData.enqueuePipeline(currentSale);
    }

    function buyNFT(uint256 _tokenId) public {
        innerBuyNFT(_tokenId, false);
    }

    function buyNFTBNB(uint256 _tokenId) public payable { 
        innerBuyNFT(_tokenId, true);
    }

    
    function innerBuyNFT(uint256 _tokenId, bool _isBnb) private {   
        IRevoMarketplaceData.PENDING_SALE memory currentSale = marketplaceData.getTokenSale(_tokenId, marketplaceData.getMasterToken(_tokenId).uniqueId - 1);

        //CHECK IF OWNER IS SELLER
        require(revoNFT.ownerOf(_tokenId) == currentSale.seller, "Seller must be the owner");
        
        require(!_isBnb ? currentSale.revoAmount > 0 : currentSale.bnbAmount > 0, "Please use the right currency");

        require(!currentSale.canceled && !currentSale.sold, "Sale canceled or already sold");

        IRevoTierContract.Tier memory userTier = revoTier.getRealTimeTierWithDiamondHands(currentSale.seller);

        uint256 nftPrice = (!_isBnb ? currentSale.revoAmount : currentSale.bnbAmount);

        uint256 fees = marketplaceData.calculatePercentage(nftPrice, userTier.marketplaceFee, 1000000).div(10);

        nftPrice = nftPrice - fees;

        if(!_isBnb){
            //1. Transfer amount to owner
            revoToken.transferFrom(msg.sender, currentSale.seller, nftPrice);

            //2. PAY FEES TO CONTRACT OWNER
            if(fees > 0 ){
                revoToken.transferFrom(msg.sender, owner(), fees);
            }
        }else{
            //Check if BNB amount is correct
            require(msg.value == currentSale.bnbAmount, "Send the correct amount of BNB");

            //1. Transfer amount to owner
            payable(address(currentSale.seller)).transfer(nftPrice);

            //2. PAY FEES TO CONTRACT OWNER
            if(fees > 0 ){
                payable(owner()).transfer(fees);
            }
        }
        

        //3. Transfer NFT to buyer
        revoNFT.transferFrom(currentSale.seller, msg.sender, _tokenId);

        uint256 index =  marketplaceData.getMasterToken(_tokenId).uniqueId - 1;

        marketplaceData.setSold(_tokenId, index,  true);
        marketplaceData.setBuyer(_tokenId, index,  msg.sender);

        marketplaceData.enqueuePipeline(currentSale);
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
    Set revo tier Address & contract
    */
    function setMarketplaceData(address _marketplaceData) public onlyOwner {
        marketplaceData = IRevoMarketplaceData(_marketplaceData);
    }

    /*
    Emergency transfer Revo
    */
    function withdrawRevo(uint256 _amount, address _receiver) public onlyOwner {
        revoToken.transfer(_receiver, _amount);
    }
}
