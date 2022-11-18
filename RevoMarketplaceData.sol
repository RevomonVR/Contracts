pragma solidity 0.8.11;
pragma experimental ABIEncoderV2;

/*interface IRevoMarketplaceData{
    function getTokenSale(uint256 _tokenId, uint256 _index) external view returns(PENDING_SALE memory);
    function pushTokenSale(uint256 _tokenId, PENDING_SALE memory _sale) external;
    function incMasterUniqueId(uint256 _tokenId) external;
    function setRevoAmount(uint256 _tokenId, uint256 _revoAmount) external;
    function setBnbAmount(uint256 _tokenId, uint256 _bnbAmount) external;
    function setUpdated(uint256 _tokenId, bool _updated) external;
    function setCanceled(uint256 _tokenId, bool _canceled) external;
    function setSeller(uint256 _tokenId, address _seller) external;

    function enqueuePipeline(PENDING_SALE memory data) external;
    function dequeuePipeline() external onlyOwner returns (PENDING_SALE memory data);
    function countPendingTx() external view returns(uint256);
    function getPendingTx(uint256 _maxItems) external view returns(PENDING_SALE[] memory items);
}*/


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
contract RevoMarketplaceData is Ownable {

    uint256 public firstPending = 1;
    uint256 public lastPending = 0;

    mapping(uint256 => MASTER_PENDING_SALE) public masterTokenSales;

    mapping(uint256 => PENDING_SALE) pipeline;

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

    constructor() {
    }

    function getMasterToken(uint256 _tokenId) public view returns(MASTER_PENDING_SALE memory){
        return masterTokenSales[_tokenId];
    }

    function getTokenSale(uint256 _tokenId, uint256 _index) public view returns(PENDING_SALE memory){
        return masterTokenSales[_tokenId].tokenSales[_index];
    }

    function pushTokenSale(uint256 _tokenId, PENDING_SALE memory _sale) public onlyOwner{
        masterTokenSales[_tokenId].tokenSales.push(_sale);
    }

    function incMasterUniqueId(uint256 _tokenId) public onlyOwner{
        masterTokenSales[_tokenId].uniqueId++;
    }

    function setRevoAmount(uint256 _tokenId, uint256 _index, uint256 _revoAmount) public onlyOwner{
        masterTokenSales[_tokenId].tokenSales[_index].revoAmount = _revoAmount;
    }

    function setBnbAmount(uint256 _tokenId, uint256 _index, uint256 _bnbAmount) public onlyOwner{
        masterTokenSales[_tokenId].tokenSales[_index].bnbAmount = _bnbAmount;
    }

    function setUpdated(uint256 _tokenId, uint256 _index, bool _updated) public onlyOwner{
        masterTokenSales[_tokenId].tokenSales[_index].updated = _updated;
    }

    function setCanceled(uint256 _tokenId, uint256 _index, bool _canceled) public onlyOwner{
        masterTokenSales[_tokenId].tokenSales[_index].canceled = _canceled;
    }

    function setSeller(uint256 _tokenId, uint256 _index, address _seller) public onlyOwner {
        masterTokenSales[_tokenId].tokenSales[_index].seller = _seller;
    }

    function setSold(uint256 _tokenId, uint256 _index, bool _sold) public onlyOwner{
        masterTokenSales[_tokenId].tokenSales[_index].sold = _sold;
    }

    function setBuyer(uint256 _tokenId, uint256 _index, address _buyer) public onlyOwner {
        masterTokenSales[_tokenId].tokenSales[_index].buyer = _buyer;
    }

    function calculatePercentage(uint256 amount, uint256 percentage, uint256 precision) public pure returns(uint256){
        return ((((amount * precision) * percentage)) / 100) / precision;
    }

    /*
    PENDING BUY QUEUE
    */
    
    function enqueuePipeline(PENDING_SALE memory data) public onlyOwner {
        lastPending += 1;
        pipeline[lastPending] = data;
    }

    function dequeuePipeline() public onlyOwner returns (PENDING_SALE memory data) {
        require(lastPending >= firstPending);  // non-empty queue

        data = pipeline[firstPending];

        delete pipeline[firstPending];
        firstPending += 1;
    }
    
    function countPendingTx() public view returns(uint256){
        return firstPending <= lastPending ? (lastPending - firstPending) + 1 : 0;
    }
    
    function getPendingTx(uint256 _maxItems) public view returns(PENDING_SALE[] memory items){
        uint256 count = countPendingTx();
        count = count > _maxItems ? _maxItems : count;
        PENDING_SALE[] memory itemToReturn = new PENDING_SALE[](count);
        
        for(uint256 i = 0; i < count; i ++){
            itemToReturn[i] =  pipeline[firstPending + i];
        }
        
        return itemToReturn;
    }
}
