pragma solidity ^0.8.3;
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
    function balanceOf(address owner) external view returns (uint256 balance);
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);
    function tokenInfo(uint256) external view returns(string memory collection, string memory dbId, uint256 tokenId);
}

interface IRevoTierContract{
    function getRealTimeTier(address _wallet) external view returns (Tier memory);
    function getTier(uint256 _index) external view returns(Tier memory);
    
    struct Tier {
        uint256 index;
        uint256 minRevoToHold;
        uint256 stakingAPRBonus;
        string name;
        uint256 marketplaceFee;
    }
}

interface IRevoEggFarmer{
    function hatchEgg(uint256 _tokenId, address user) external;
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

contract RevoNFTUtils is Ownable {
    using SafeMath for uint256;
     
    address public revoAddress;
    IRevoTokenContract private revoToken;
    address public revoLibAddress;
    IRevoLib private revoLib;
    address public tierAddress;
    IRevoTierContract revoTier;
    IRevoEggFarmer revoEggFarmer;
    
    IRevoNFT private revoNFT;
    
    uint256 private nextRevoId;
    uint256 public revoFees;
    
    uint256 public counter;
    uint256 public minTierBooster = 4;
    ITEMS_SALEABLE[99] public itemSaleable;
    //PENDING BUY
    mapping(uint256 => PENDING_TX) pendingTx;
    uint256 public firstPending = 1;
    uint256 public lastPending = 0;

    mapping(address => mapping(string => mapping(string => uint256))) public triggerMintHistory; 
    
    struct ITEMS_SALEABLE {
        uint256 index;
        string name;
        string description;
        uint256 price;
        string itemType;
        bool enabled;
        uint256 count;
        uint256 maxItems;
        uint256[3] prices;
    }
    
    struct PENDING_TX {
        uint256 itemIndex;
        string dbId;
        string collection;
        uint256 uniqueId;
        string itemType;
        address sender;
        uint256[] tokenIds;
    }

    
    event CreateNFT(address sender, string dbId, string collection);
    event BuyItem(address sender, uint256 index);
    event HatchEgg(address sender, uint256 tokenId);
    event OpenBooster(address sender, uint256 tokenId);

    constructor(address _revoLibAddress, address _revoNFT, address _revoTier) {
        setRevoLib(_revoLibAddress);
        setRevo(revoLib.tokenRevoAddress());
        setRevoNFT(_revoNFT);
        setRevoTier(_revoTier);
        
        revoFees = 100000000000000000;
    }
    
    /*
    Trigger nft creation
    */
    function triggerCreateNFT(string memory _dbId, string memory _collection) public payable {
        require(canMint(msg.sender), "You must own a R3V-UP to mint.");

        require(msg.value >= revoFees, "Send the required amount");

        payable(owner()).transfer(msg.value);
        
        triggerMintHistory[msg.sender][_collection][_dbId] = revoFees;
        
        enqueuePendingTx(PENDING_TX(0, _dbId, _collection, counter, "", msg.sender, new uint[](0)));
        
        emit CreateNFT(msg.sender, _dbId, _collection);
        
        counter++;
    }
    
    /*
    Buy item sellable & add pending buy to queue
    */
    function buyItem(uint256 _itemIndex) public {
        //Check if item is available in inventory
        require(itemSaleable[_itemIndex].count < itemSaleable[_itemIndex].maxItems, "All items sold");
        //Must be master to buy booster
        require(!compareStrings(itemSaleable[_itemIndex].itemType, "BOOSTER") || revoTier.getRealTimeTier(msg.sender).index >= minTierBooster, "Must belong to minTier to buy booster");
        
        enqueuePendingTx(PENDING_TX(_itemIndex, "", "", counter, itemSaleable[_itemIndex].itemType, msg.sender, new uint[](0)));
        
        revoToken.transferFrom(msg.sender, address(this), getItemPrice(_itemIndex));
        
        itemSaleable[_itemIndex].count = itemSaleable[_itemIndex].count.add(1);
        
        emit BuyItem(msg.sender, itemSaleable[_itemIndex].index);
        
        counter++;
    }

    function hatchEgg(uint256 _tokenId) public {
        revoEggFarmer.hatchEgg(_tokenId, msg.sender);

        enqueuePendingTx(PENDING_TX(_tokenId, "", "EGG", counter, "HATCH", msg.sender, new uint[](0)));

        emit HatchEgg(msg.sender, _tokenId);

        counter++;
    }

    function openBooster(uint256 _tokenId) public {
        require(isNFTBooster(_tokenId, msg.sender), "NFT is not a booster");

        //TRANSFER AND BURN BOOSTER NFT
        revoNFT.transferFrom(msg.sender, address(this), _tokenId);
        revoNFT.burn(_tokenId);

        enqueuePendingTx(PENDING_TX(_tokenId, "", "BOOSTER", counter, "OPEN", msg.sender, new uint[](0)));

        emit OpenBooster(msg.sender, _tokenId);

        counter++;
    }

    function isNFTBooster(uint256 _tokenId, address _user) public view returns(bool){
        IRevoNFT.Token[] memory tokens = revoNFT.getTokensByOwner(_user);
        for(uint256 i = 0; i < tokens.length; i++){
            if(tokens[i].tokenId == _tokenId && compareStrings(tokens[i].collection, "BOOSTER")){
                return true;
            }
        }
        return false;
    }
    
    function getItemPrice(uint256 _itemIndex) public view returns(uint256){
        uint256 price = itemSaleable[_itemIndex].price;
        
        if(!compareStrings(itemSaleable[_itemIndex].itemType, "R3VUP")){
            
            uint256 step = itemSaleable[_itemIndex].maxItems / 3;
            uint priceIndex = itemSaleable[_itemIndex].count < step ? 0 :
            itemSaleable[_itemIndex].count < (step * 2) ? 1 : 2;
            
            price = itemSaleable[_itemIndex].prices[priceIndex];
        }
        
        return price;
    }

    function canMint(address _user) public view returns(bool){
        uint256 tokenCount = revoNFT.balanceOf(_user);

        if (tokenCount == 0) {
            // Return an empty array
            return false;
        } else {
            bool find = false;
            for (uint256 index = 0; index < tokenCount; index++) {
                
                (string memory collection , , ) = revoNFT.tokenInfo(revoNFT.tokenOfOwnerByIndex(_user, index));
                if(compareStrings(collection, "R3VUP")){
                    find = true;
                    index = tokenCount;
                }
            }

            return find;
        }
    }
    
    function setRevoFees(uint256 _fees) public onlyOwner {
        revoFees = _fees;
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
    
    function setRevoNFT(address _revoNFT) public onlyOwner {
        revoNFT = IRevoNFT(_revoNFT);
    }

    /*
    Set revo tier Address & contract
    */
    function setRevoTier(address _revoTier) public onlyOwner {
        tierAddress = _revoTier;
        revoTier = IRevoTierContract(tierAddress);
    }

    /*
    Set revo egg farmer contract
    */
    function setRevoEggFarmer(address _revoEggFarmer) public onlyOwner {
        revoEggFarmer = IRevoEggFarmer(_revoEggFarmer);
    }
    
    function withdrawRevo(uint256 _amount) public onlyOwner {
        revoToken.transfer(owner(),_amount);
    }

    function setMinTierBooster(uint256 _minTierBooster) public onlyOwner {
        minTierBooster = _minTierBooster;
    }
    
    function editItemsaleable(uint256 _index, string memory _name, string memory _description, uint256 _price, string memory _itemType, bool _enabled,
    uint256 _count, uint256 _maxItems, uint256[3] memory _prices) public onlyOwner{
        itemSaleable[_index].index = _index;
        itemSaleable[_index].name = _name;
        itemSaleable[_index].description = _description;
        itemSaleable[_index].price = _prices[0];
        itemSaleable[_index].itemType = _itemType;
        itemSaleable[_index].enabled = _enabled;
        editInventory(_index, _count, _maxItems);
        editItemsaleablePrices(_index, _prices);
    }
    
    function editItemsaleablePrices(uint256 _index, uint256[3] memory _prices) public onlyOwner{
        itemSaleable[_index].prices = _prices;
    }
    
    function editInventory(uint256 _index, uint256 _count, uint256 _maxItems) public onlyOwner{
        itemSaleable[_index].count = _count;
        itemSaleable[_index].maxItems = _maxItems;
    }
    
    function getAllItemssaleable() public view  returns(ITEMS_SALEABLE[] memory){
        uint256 count;
        for(uint i = 0; i < itemSaleable.length; i++){
            if(itemSaleable[i].enabled){
                count++;
            }
        }
        
        ITEMS_SALEABLE[] memory itemToReturn = new ITEMS_SALEABLE[](count);
        for(uint256 i = 0; i < itemSaleable.length; i++){
            if(itemSaleable[i].enabled){
                itemToReturn[i] = itemSaleable[i];
                itemToReturn[i].price = getItemPrice(i);
            }
        }
        return itemToReturn;
    }
    
    /*
    PENDING BUY QUEUE
    */
    
    function enqueuePendingTx(PENDING_TX memory data) private {
        lastPending += 1;
        pendingTx[lastPending] = data;
    }

    function dequeuePendingTx() public onlyOwner returns (PENDING_TX memory data) {
        require(lastPending >= firstPending);  // non-empty queue

        data = pendingTx[firstPending];

        delete pendingTx[firstPending];
        firstPending += 1;
    }
    
    function countPendingTx() public view returns(uint256){
        return firstPending <= lastPending ? (lastPending - firstPending) + 1 : 0;
    }
    
    function getPendingTx(uint256 _maxItems) public view returns(PENDING_TX[] memory items){
        uint256 count = countPendingTx();
        count = count > _maxItems ? _maxItems : count;
        PENDING_TX[] memory itemToReturn = new PENDING_TX[](count);
        
        for(uint256 i = 0; i < count; i ++){
            itemToReturn[i] =  pendingTx[firstPending + i];
        }
        
        return itemToReturn;
    }
    
    function compareStrings(string memory a, string memory b) private pure returns (bool) {
        return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
    }
}