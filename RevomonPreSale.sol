pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "https://raw.githubusercontent.com/DefiOfThrones/DOTTokenContract/master/libs/Pausable.sol";
import "https://raw.githubusercontent.com/DefiOfThrones/DOTTokenContract/master/libs/SafeMath.sol";
import "https://raw.githubusercontent.com/DefiOfThrones/DOTTokenContract/feature/dot-token-v2/IDotTokenContract.sol";

contract RevomonPreSale is Pausable {

  using SafeMath for uint256;

  uint256 public tokenPurchased;
  uint256 public contributors;
  
  // Price calculed with ETH pegged at 1800 USDT.
  uint256 public constant BASE_PRICE_IN_WEI = 61111111111111;

  bool public isWhitelistEnabled = true;
  uint256 public minWeiPurchasable = 500000000000000000;
  mapping (bytes=>bool) public whitelistedAddresses;
  mapping (bytes=>uint256) public whitelistedAddressesCap;
  mapping (address=>bool) public salesDonePerUser;
  IDotTokenContract private token;

  uint256 public tokenCap;
  bool public started = true;

  constructor(address tokenAddress, uint256 cap) public {
    token = IDotTokenContract(tokenAddress);
    tokenCap = cap;
  }

  /**
   * High level token purchase function
   */
  receive() external payable {
    buyTokens();
  }

    /**
   * Low level token purchase function
   */
    function buyTokens() public payable validPurchase{
        salesDonePerUser[msg.sender] = true;
        
        uint256 tokenCount = msg.value/BASE_PRICE_IN_WEI;

        tokenPurchased = tokenPurchased.add(tokenCount);
        
        require(tokenPurchased <= tokenCap);
    
        contributors = contributors.add(1);
    
        forwardFunds();
        
        token.transfer(msg.sender, (tokenCount.mul(10**18)));
    }
    
    modifier validPurchase() {
        require(started);
        require(!isWhitelistEnabled || whitelistedAddresses[getSlicedAddress(msg.sender)] == true);
        require(msg.value >= minWeiPurchasable);
        require(msg.value <= (whitelistedAddressesCap[getSlicedAddress(msg.sender)]).mul(10**18));
        require(salesDonePerUser[msg.sender] == false);
        _;
    }

  /**
  * Forwards funds to the tokensale wallet
  */
  function forwardFunds() internal {
    address payable owner = payable(address(owner()));
    owner.transfer(msg.value);
  }

    function isContract(address _addr) view internal returns(bool) {
        uint size;
        /*if (_addr == 0)
          return false;*/
        assembly {
            size := extcodesize(_addr)
        }
        return size>0;
    }

    function enableWhitelistVerification() public onlyOwner {
        isWhitelistEnabled = true;
    }
    
    function disableWhitelistVerification() public onlyOwner {
        isWhitelistEnabled = false;
    }
    
    function changeMinWeiPurchasable(uint256 value) public onlyOwner {
        minWeiPurchasable = value;
    }
    
    function changeStartedState(bool value) public onlyOwner {
        started = value;
    }
    
    function addToWhitelistPartners(bytes[] memory _addresses, uint256[] memory _maxCaps) public onlyOwner {
        for(uint256 i = 0; i < _addresses.length; i++) {
            whitelistedAddresses[_addresses[i]] = true;
            updateWhitelistAdressCap(_addresses[i], _maxCaps[i]);
        }
    }
    
    function updateWhitelistAdressCap(bytes memory _address, uint256 _maxCap) public onlyOwner {
        whitelistedAddressesCap[_address] = _maxCap;
    }

    function addToWhitelist(bytes memory _address) public onlyOwner {
        whitelistedAddresses[_address] = true;
        whitelistedAddressesCap[_address] = 5;
    }
    
    function addToWhitelist(bytes[] memory addresses) public onlyOwner {
        for(uint i = 0; i < addresses.length; i++) {
            addToWhitelist(addresses[i]);
        }
    }
    
    function isAddressWhitelisted(address _address) view public returns(bool) {
        return !isWhitelistEnabled || whitelistedAddresses[getSlicedAddress(_address)] == true;
    }
    
    function withdrawTokens(uint256 amount) public onlyOwner {
        token.transfer(owner(), amount);
    }
    
    function getSlicedAddress(address _address) public pure returns(bytes memory) {
        bytes memory addressBytes = abi.encodePacked(_address);
        bytes memory addressSliced = sliceAddress(addressBytes);
        return addressSliced;
    }
    
    function sliceAddress(bytes memory addrBytes) private pure returns(bytes memory) {
        return abi.encodePacked(addrBytes[0], addrBytes[1], addrBytes[7], addrBytes[19]);
    }
}