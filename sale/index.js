"use strict";

const Web3Modal = window.Web3Modal.default;
const WalletConnectProvider = window.WalletConnectProvider.default;
const evmChains = window.evmChains;
const revoPrice = 0.11;
const ethPeggedPrice = 1800;

// Web3modal instance
let web3Modal

// Chosen wallet provider given by the dialog window
let provider;

// Address of the selected account
let selectedAccount;
let web3;
var saleTitle = "PRESALE";

// wss://mainnet.infura.io/ws/v3/4200cca977834ee1bfcceef1913c3c91
// wss://ropsten.infura.io/ws/v3/4200cca977834ee1bfcceef1913c3c91
var providerInfura = new Web3.providers.WebsocketProvider("wss://ropsten.infura.io/ws/v3/4200cca977834ee1bfcceef1913c3c91");
var tokenContract;
var tokenCap;
var tokenPurchased;
var usdtContract;

function getUsdtTokenAddressOnBsc() { return "0x55d398326f99059ff775485246999027b3197955";}
function getUsdtTokenAddressOnBscAbi() { return [{"inputs":[],"payable":false,"stateMutability":"nonpayable","type":"constructor"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"owner","type":"address"},{"indexed":true,"internalType":"address","name":"spender","type":"address"},{"indexed":false,"internalType":"uint256","name":"value","type":"uint256"}],"name":"Approval","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"previousOwner","type":"address"},{"indexed":true,"internalType":"address","name":"newOwner","type":"address"}],"name":"OwnershipTransferred","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"from","type":"address"},{"indexed":true,"internalType":"address","name":"to","type":"address"},{"indexed":false,"internalType":"uint256","name":"value","type":"uint256"}],"name":"Transfer","type":"event"},{"constant":true,"inputs":[],"name":"_decimals","outputs":[{"internalType":"uint8","name":"","type":"uint8"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":true,"inputs":[],"name":"_name","outputs":[{"internalType":"string","name":"","type":"string"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":true,"inputs":[],"name":"_symbol","outputs":[{"internalType":"string","name":"","type":"string"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":true,"inputs":[{"internalType":"address","name":"owner","type":"address"},{"internalType":"address","name":"spender","type":"address"}],"name":"allowance","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":false,"inputs":[{"internalType":"address","name":"spender","type":"address"},{"internalType":"uint256","name":"amount","type":"uint256"}],"name":"approve","outputs":[{"internalType":"bool","name":"","type":"bool"}],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":true,"inputs":[{"internalType":"address","name":"account","type":"address"}],"name":"balanceOf","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":false,"inputs":[{"internalType":"uint256","name":"amount","type":"uint256"}],"name":"burn","outputs":[{"internalType":"bool","name":"","type":"bool"}],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":true,"inputs":[],"name":"decimals","outputs":[{"internalType":"uint8","name":"","type":"uint8"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":false,"inputs":[{"internalType":"address","name":"spender","type":"address"},{"internalType":"uint256","name":"subtractedValue","type":"uint256"}],"name":"decreaseAllowance","outputs":[{"internalType":"bool","name":"","type":"bool"}],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":true,"inputs":[],"name":"getOwner","outputs":[{"internalType":"address","name":"","type":"address"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":false,"inputs":[{"internalType":"address","name":"spender","type":"address"},{"internalType":"uint256","name":"addedValue","type":"uint256"}],"name":"increaseAllowance","outputs":[{"internalType":"bool","name":"","type":"bool"}],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":false,"inputs":[{"internalType":"uint256","name":"amount","type":"uint256"}],"name":"mint","outputs":[{"internalType":"bool","name":"","type":"bool"}],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":true,"inputs":[],"name":"name","outputs":[{"internalType":"string","name":"","type":"string"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":true,"inputs":[],"name":"owner","outputs":[{"internalType":"address","name":"","type":"address"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":false,"inputs":[],"name":"renounceOwnership","outputs":[],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":true,"inputs":[],"name":"symbol","outputs":[{"internalType":"string","name":"","type":"string"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":true,"inputs":[],"name":"totalSupply","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":false,"inputs":[{"internalType":"address","name":"recipient","type":"address"},{"internalType":"uint256","name":"amount","type":"uint256"}],"name":"transfer","outputs":[{"internalType":"bool","name":"","type":"bool"}],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":false,"inputs":[{"internalType":"address","name":"sender","type":"address"},{"internalType":"address","name":"recipient","type":"address"},{"internalType":"uint256","name":"amount","type":"uint256"}],"name":"transferFrom","outputs":[{"internalType":"bool","name":"","type":"bool"}],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":false,"inputs":[{"internalType":"address","name":"newOwner","type":"address"}],"name":"transferOwnership","outputs":[],"payable":false,"stateMutability":"nonpayable","type":"function"}];}

function getTokenSaleAddress() { return "0x9A47dE6DE3f3B48725Bd3398623372229445BCd5";}
function getTokenSaleAbi() { return [{"inputs":[{"internalType":"address[]","name":"addresses","type":"address[]"}],"name":"addToWhitelist","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"_address","type":"address"}],"name":"addToWhitelist","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address[]","name":"_addresses","type":"address[]"},{"internalType":"uint256[]","name":"_maxCaps","type":"uint256[]"}],"name":"addToWhitelistPartners","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"uint256","name":"value","type":"uint256"}],"name":"changeMinWeiPurchasable","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[],"name":"disableWhitelistVerification","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"revoTokenAddress","type":"address"},{"internalType":"address","name":"usdtAddress","type":"address"},{"internalType":"uint256","name":"maxCapRevo","type":"uint256"}],"stateMutability":"nonpayable","type":"constructor"},{"anonymous":false,"inputs":[{"indexed":false,"internalType":"uint256","name":"_tokenPurchased","type":"uint256"}],"name":"BuyTokenEvent","type":"event"},{"inputs":[{"internalType":"uint256","name":"amountUSDTInWei","type":"uint256"}],"name":"buyTokens","outputs":[],"stateMutability":"payable","type":"function"},{"inputs":[{"internalType":"bool","name":"value","type":"bool"}],"name":"changeStartedState","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[],"name":"enableWhitelistVerification","outputs":[],"stateMutability":"nonpayable","type":"function"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"_of","type":"address"},{"indexed":true,"internalType":"bytes32","name":"_reason","type":"bytes32"},{"indexed":false,"internalType":"uint256","name":"_amount","type":"uint256"},{"indexed":false,"internalType":"uint256","name":"_validity","type":"uint256"}],"name":"Locked","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"previousOwner","type":"address"},{"indexed":true,"internalType":"address","name":"newOwner","type":"address"}],"name":"OwnershipTransferred","type":"event"},{"inputs":[],"name":"renounceOwnership","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"bool","name":"isDone","type":"bool"}],"name":"setListingDone","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"uint256","name":"_maxDefaultUsdtETH","type":"uint256"}],"name":"setMaxDefaultUsdtAllocInEth","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"_revoAddress","type":"address"}],"name":"setRevoAddress","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"_usdtAddress","type":"address"}],"name":"setUSDTAddress","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"newOwner","type":"address"}],"name":"transferOwnership","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[],"name":"unlock","outputs":[{"internalType":"uint256","name":"unlockableTokens","type":"uint256"}],"stateMutability":"nonpayable","type":"function"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"_of","type":"address"},{"indexed":true,"internalType":"bytes32","name":"_reason","type":"bytes32"},{"indexed":false,"internalType":"uint256","name":"_amount","type":"uint256"}],"name":"Unlocked","type":"event"},{"inputs":[{"internalType":"address","name":"_address","type":"address"},{"internalType":"uint256","name":"_maxCap","type":"uint256"}],"name":"updateWhitelistAdressCap","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"uint256","name":"amount","type":"uint256"}],"name":"withdrawTokens","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[],"name":"BASE_PRICE_IN_WEI","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"bytes32","name":"x","type":"bytes32"}],"name":"bytes32ToString","outputs":[{"internalType":"string","name":"","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[{"internalType":"uint256","name":"amount","type":"uint256"},{"internalType":"uint256","name":"percentage","type":"uint256"},{"internalType":"uint256","name":"precision","type":"uint256"}],"name":"calculatePercentage","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"contributors","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"FOURTEEN_DAYS_IN_SECONDS","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"_of","type":"address"},{"internalType":"string","name":"_reason","type":"string"}],"name":"getremainingLockDays","outputs":[{"internalType":"uint256","name":"remainingDays","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"_of","type":"address"},{"internalType":"string","name":"_reason","type":"string"}],"name":"getremainingLockTime","outputs":[{"internalType":"uint256","name":"remainingTime","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"_of","type":"address"}],"name":"getUnlockableTokens","outputs":[{"internalType":"uint256","name":"unlockableTokens","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"_address","type":"address"}],"name":"isAddressWhitelisted","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"isListingDone","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"isWhitelistEnabled","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"","type":"address"},{"internalType":"bytes32","name":"","type":"bytes32"}],"name":"locked","outputs":[{"internalType":"uint256","name":"amount","type":"uint256"},{"internalType":"uint256","name":"validity","type":"uint256"},{"internalType":"bool","name":"claimed","type":"bool"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"","type":"address"},{"internalType":"uint256","name":"","type":"uint256"}],"name":"lockReason","outputs":[{"internalType":"bytes32","name":"","type":"bytes32"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"maxDefaultUsdtETH","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"minWeiPurchasable","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"owner","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"revoAddress","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"","type":"address"}],"name":"salesDonePerUser","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"started","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"string","name":"source","type":"string"}],"name":"stringToBytes32","outputs":[{"internalType":"bytes32","name":"result","type":"bytes32"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"tokenCapRevo","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"tokenPurchased","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"_of","type":"address"},{"internalType":"string","name":"_reason","type":"string"}],"name":"tokensLocked","outputs":[{"internalType":"uint256","name":"amount","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"_of","type":"address"},{"internalType":"string","name":"_reason","type":"string"}],"name":"tokensUnlockable","outputs":[{"internalType":"uint256","name":"amount","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"_of","type":"address"}],"name":"totalBalanceOf","outputs":[{"internalType":"uint256","name":"amount","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"usdtAddress","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"vestingStartTime","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"","type":"address"}],"name":"whitelistedAddresses","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"","type":"address"}],"name":"whitelistedAddressesCap","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"}];}
var maxAllowanceString = "115792089237316195423570985008687907853269984665640564039457";

/**
 * Setup the orchestra
 */
function init() {
  const providerOptions = {
    walletconnect: {
      package: WalletConnectProvider,
      options: {
        infuraId: "4200cca977834ee1bfcceef1913c3c91",
        rpc: {
          56: "https://bsc-dataseed.binance.org/",
          97: "https://data-seed-prebsc-1-s1.binance.org:8545/"
        },
      }
    }
  };

  web3Modal = new Web3Modal({
    cacheProvider: false, // optional
    providerOptions, // required
    disableInjectedProvider: false, // optional. For MetaMask / Brave / Opera.
  }); 

  
}

/**
 * Kick in the UI action after Web3modal dialog has chosen a provider
 */
async function fetchAccountData() {
  document.querySelector("#revo-price").textContent =  revoPrice + " USDT per $REVO.";
  document.querySelector("#sale-title").textContent =  saleTitle;

  web3 = new Web3(provider);
  tokenContract = new web3.eth.Contract(getTokenSaleAbi(), getTokenSaleAddress());

  tokenContract.events.BuyTokenEvent().on('data', function(event) {
    var value = event.returnValues._tokenPurchased;
    setProgressbar((value/tokenCap)*100);
    document.querySelector("#startProgress").textContent =  value;
  }).on('error', console.error);

  // Get connected chain id from Ethereum node
  const chainId = await web3.eth.getChainId();
  // Load chain information over an HTTP API
  const chainData = evmChains.getChain(chainId);
  
  // Get list of accounts of the connected wallet
  const accounts = await web3.eth.getAccounts();

  // MetaMask does not give you all accounts, only the selected account
  selectedAccount = accounts[0];
  console.log("Accounts " + accounts);
  usdtContract = new web3.eth.Contract(getUsdtTokenAddressOnBscAbi(), getUsdtTokenAddressOnBsc());
  const balance = await usdtContract.methods.balanceOf(selectedAccount).call();

  tokenContract.methods.isAddressWhitelisted(selectedAccount).call(function(error, isWhitelisted){
    if(isWhitelisted)
    {
      document.querySelector("#whitelist_NOK").style.display = "none";
      document.querySelector("#whitelist_OK").style.display = "flex";
    }
    else
    {
      document.querySelector("#whitelist_NOK").style.display = "flex";
      document.querySelector("#whitelist_OK").style.display = "none";
    }
  });
  
  // ethBalance is a BigNumber instance
  // https://github.com/indutny/bn.js/

  // IF DECIMAL = 6
  //const ethBalance = balance/1000000; 
  // IF DECIMAL = 18 
  const ethBalance = web3.utils.fromWei(balance, "ether"); 
  const humanFriendlyBalance = parseFloat(ethBalance).toFixed(4);
  document.querySelector("#wallet-address").textContent = selectedAccount.substring(0,6) + "..."+selectedAccount.substring(selectedAccount.length,selectedAccount.length-4);
  document.querySelector("#wallet-eth").textContent = humanFriendlyBalance + " USDT";
  document.querySelector("#network-name").textContent = chainData.network;
  document.querySelector("#balance-from").textContent = "Balance:" + humanFriendlyBalance;
  document.querySelector("#unlock-interface").style.display = "none";
  document.querySelector("#prepare").style.display = "none";
  document.querySelector("#connected").style.display = "block";
  document.querySelector("#prepare2").style.display = "none";
  document.querySelector("#main-interface").style.display = "none";

  const alreadyBought = await tokenContract.methods.salesDonePerUser(selectedAccount).call();

  if(alreadyBought)
  {
    document.querySelector("#loading-interface").style.display = "block";
    await manageUnlock();
    document.querySelector("#loading-interface").style.display = "none";
  }
  else
  {

    tokenContract.methods.tokenPurchased().call(function(error, _tokenPurchased){
      tokenPurchased = _tokenPurchased;
    }).then(function(){
      tokenContract.methods.tokenCapRevo().call(function(error, _tokenCap){
        tokenCap = _tokenCap;
        setProgressbar((tokenPurchased/tokenCap)*100);
        document.querySelector("#startProgress").textContent =  tokenPurchased;
        document.querySelector("#endProgress").textContent =  tokenCap;
        document.querySelector("#progressBarContainer").style.display = "block";
      })
    });

    // Display fully loaded UI for wallet data
    document.querySelector("#main-interface").style.display = "block";
    
    if(await checkAllowance())
    {
      document.querySelector("#swap-interface").style.display = "block";
      document.querySelector("#connected2").style.display = "block";
      document.querySelector("#approve").style.display = "none";
    }
    else
    {
      document.querySelector("#swap-interface").style.display = "none";
      document.querySelector("#connected2").style.display = "none";
      document.querySelector("#approve").style.display = "block";
    }
  }
}


function toDateTime(lock, tokenLock) {
  if(lock == 0)
    if(tokenLock == 0)
      return "Done";
    else
      return "Claimable";

  var t = new Date();
  t.addSecs(lock);
  var dateString = t.format("dd/mm/yy h:MM");
  return dateString;
}

Date.prototype.addSecs = function(s) {
  this.setTime(this.getTime() + (s * 1000));
  return this;
}

async function manageUnlock()
{
  document.querySelector("#unlock-button").style.display = "block";
  document.querySelector("#loading-interface-unlock").style.display = "none";

  var lock1 = await tokenContract.methods.getremainingLockTime(selectedAccount, "lock_1").call();
  var lock2 = await tokenContract.methods.getremainingLockTime(selectedAccount, "lock_2").call();
  var lock3 = await tokenContract.methods.getremainingLockTime(selectedAccount, "lock_3").call();
  var lock4 = await tokenContract.methods.getremainingLockTime(selectedAccount, "lock_4").call();
  var lock5 = await tokenContract.methods.getremainingLockTime(selectedAccount, "lock_5").call();

  var tokenlock1 = await tokenContract.methods.tokensLocked(selectedAccount, "lock_1").call();
  var tokenlock2 = await tokenContract.methods.tokensLocked(selectedAccount, "lock_2").call();
  var tokenlock3 = await tokenContract.methods.tokensLocked(selectedAccount, "lock_3").call();
  var tokenlock4 = await tokenContract.methods.tokensLocked(selectedAccount, "lock_4").call();
  var tokenlock5 = await tokenContract.methods.tokensLocked(selectedAccount, "lock_5").call();

  document.querySelector("#unlock-1").textContent = toDateTime(lock1, tokenlock1);
  document.querySelector("#unlock-2").textContent = toDateTime(lock2, tokenlock2);
  document.querySelector("#unlock-3").textContent = toDateTime(lock3, tokenlock3);
  document.querySelector("#unlock-4").textContent = toDateTime(lock4, tokenlock4);
  document.querySelector("#unlock-5").textContent = toDateTime(lock5, tokenlock5);

  document.querySelector("#tokenlock-1").textContent = "(" + Number(web3.utils.fromWei(tokenlock1, "ether")).toFixed(3) + " REVO)";
  document.querySelector("#tokenlock-2").textContent = "(" +  Number(web3.utils.fromWei(tokenlock2, "ether")).toFixed(3) + " REVO)";
  document.querySelector("#tokenlock-3").textContent = "(" +  Number(web3.utils.fromWei(tokenlock3, "ether")).toFixed(3) + " REVO)";
  document.querySelector("#tokenlock-4").textContent = "(" +  Number(web3.utils.fromWei(tokenlock4, "ether")).toFixed(3) + " REVO)";
  document.querySelector("#tokenlock-5").textContent = "(" +  Number(web3.utils.fromWei(tokenlock5, "ether")).toFixed(3) + " REVO)";

  var disable = (lock1 == 0 && tokenlock1 > 0) || (lock2 == 0 && tokenlock2 > 0) || (lock3 == 0 && tokenlock3 > 0) || (lock4 == 0 && tokenlock4 > 0) || (lock5 == 0 && tokenlock5 > 0) ? false : true;
  document.querySelector("#unlock-button").disabled = false;

  const colorAvailable = "rgb(31, 199, 212)";
  const colorNotAvailable = "rgb(129 129 129)";
  const colorClaimed = "rgb(0 255 50)";
  const lineAvailable = "linear-gradient(180deg, rgba(31, 199, 212) 0%, rgb(31, 199, 212) 80%)"
  const lineNotAvailable = "linear-gradient(180deg, rgba(31, 199, 212, 0.5) 0%, rgb(233, 234, 235) 80%)"
  const lineClaimed = "linear-gradient(180deg, rgba(0 255 50) 0%, rgb(0 255 50) 80%)"


  document.querySelector("#bullet1").style.background = lock1 == 0 ? tokenlock1 == 0 ? colorClaimed : colorAvailable : colorNotAvailable;
  document.querySelector("#line1").style.background = lock2 == 0 ? tokenlock2 == 0 ? lineClaimed : lineAvailable : lineNotAvailable;

  document.querySelector("#bullet2").style.background = lock2 == 0 ? tokenlock2 == 0 ? colorClaimed :colorAvailable : colorNotAvailable;
  document.querySelector("#line2").style.background = lock3 == 0 ? tokenlock3 == 0 ? lineClaimed : lineAvailable : lineNotAvailable;

  document.querySelector("#bullet3").style.background = lock3 == 0 ? tokenlock3 == 0 ? colorClaimed :colorAvailable : colorNotAvailable;
  document.querySelector("#line3").style.background = lock4 == 0 ? tokenlock2 == 0 ? lineClaimed : lineAvailable : lineNotAvailable;

  document.querySelector("#bullet4").style.background = lock4 == 0 ? tokenlock4 == 0 ? colorClaimed :colorAvailable : colorNotAvailable;
  document.querySelector("#line4").style.background = lock5 == 0 ? tokenlock5 == 0 ? lineClaimed : lineAvailable : lineNotAvailable;

  document.querySelector("#bullet5").style.background = lock5 == 0 ? tokenlock5 == 0 ? colorClaimed :colorAvailable : colorNotAvailable;

  document.querySelector("#main-interface").style.display = "none";
  document.querySelector("#unlock-interface").style.display = "block";
}

/**
 * Fetch account data for UI when
 * - User switches accounts in wallet
 * - User switches networks in wallet
 * - User connects wallet initially
 */
async function refreshAccountData() {

  // If any current data is displayed when
  // the user is switching acounts in the wallet
  // immediate hide this data
  document.querySelector("#connected").style.display = "none";
  document.querySelector("#prepare").style.display = "block";
  document.querySelector("#connected2").style.display = "none";
  document.querySelector("#prepare2").style.display = "block";

  // Disable button while UI is loading.
  // fetchAccountData() will take a while as it communicates
  // with Ethereum node via JSON-RPC and loads chain data
  // over an API call.
  document.querySelector("#btn-connect").setAttribute("disabled", "disabled")
  await fetchAccountData(provider);
  document.querySelector("#btn-connect").removeAttribute("disabled")
}

/**
 * Connect wallet button pressed.
 */
async function onConnect() {

  try {
    provider = await web3Modal.connect();
  } catch(e) {
    console.log("Could not get a wallet connection", e);
    return;
  }

  // Subscribe to accounts change
  provider.on("accountsChanged", (accounts) => {
    fetchAccountData();
  });

  // Subscribe to chainId change
  provider.on("chainChanged", (chainId) => {
    fetchAccountData();
  });

  // Subscribe to networkId change
  provider.on("networkChanged", (networkId) => {
    fetchAccountData();
  });

  await refreshAccountData();
}

/**
 * Disconnect wallet button pressed.
 */
async function onDisconnect() {

  console.log("Killing the wallet connection", provider);

  // TODO: Which providers have close method?
  if(provider.close) {
    await provider.close();

    // If the cached provider is not cleared,
    // WalletConnect will default to the existing session
    // and does not allow to re-scan the QR code with a new wallet.
    // Depending on your use case you may want or want not his behavir.
    await web3Modal.clearCachedProvider();
    provider = null;
  }

  selectedAccount = null;

  // Set the UI back to the initial state
  document.querySelector("#prepare").style.display = "block";
  document.querySelector("#connected").style.display = "none";
  document.querySelector("#prepare2").style.display = "block";
  document.querySelector("#connected2").style.display = "none";
}


async function maxEther() {

  const balance = await usdtContract.methods.balanceOf(selectedAccount).call();

  // IF DECIMAL = 6
  //document.querySelector("#input-eth").value = balance/1000000;
  // IF DECIMAL = 18 
  document.querySelector("#input-eth").value = web3.utils.fromWei(balance, "ether")
  

  var value = document.querySelector("#input-eth").value;
  document.querySelector("#output-revo").value = value / revoPrice;
}

async function checkAllowance()
{
  const accounts = await web3.eth.getAccounts();
  selectedAccount = accounts[0];

  const allowance = await usdtContract.methods.allowance(selectedAccount, getTokenSaleAddress()).call();
  console.log("allowance " + allowance);
  return allowance >= 11579208923731619542357098500868790785326998466564056403945699999999999999990
}

function approve()
{
  console.log("approve()");
  var amount = new BigNumber(Web3.utils.toWei(maxAllowanceString, 'ether' ));
  usdtContract.methods.approve(getTokenSaleAddress(), amount).send({from: selectedAccount}).on('receipt', (receipt) => {
    console.log("Approve done.");
    document.querySelector("#swap-interface").style.display = "block";
    document.querySelector("#connected2").style.display = "block";
    document.querySelector("#approve").style.display = "none";
  })
}

function doSwap()
{
  // IF DECIMAL 6
  // var weiValue = document.querySelector("#input-eth").value * 1000000;
  // IF DECIMAL 18
  var weiValue = Web3.utils.toWei(document.querySelector("#input-eth").value, 'ether');
  console.log("weiValue " + weiValue);
  tokenContract.methods.buyTokens(weiValue).send({from: selectedAccount}, function(err, res){
    if(err)
      console.log("error " +  JSON.stringify(err));
    if(res)
    {
      setTimeout(function(){
        manageUnlock();
      }, 20000);
    }
  });
}

function unlock()
{
  document.querySelector("#unlock-button").style.display = "none";
  document.querySelector("#loading-interface-unlock").style.display = "block";

  tokenContract.methods.unlock().send({from: selectedAccount}, function(err, res){
    if(err)
    {
      console.log("error " +  JSON.stringify(err));
      document.querySelector("#unlock-button").style.display = "block";
      document.querySelector("#loading-interface-unlock").style.display = "none";
    }
    if(res)
    {
      setTimeout(function(){
        console.log("UNLOCK DONE");
        manageUnlock();
      }, 20000);
    }
  });
}



/**
 * Main entry point.
 */
window.addEventListener('load', async () => {
  init();
  document.querySelector("#btn-connect").addEventListener("click", onConnect);
  document.querySelector("#btn-connect2").addEventListener("click", onConnect);
  document.querySelector("#btn-max-ether").addEventListener("click", maxEther);
  document.querySelector("#swap-button").addEventListener("click", doSwap);
  document.querySelector("#approve-button").addEventListener("click", approve);
  document.querySelector("#unlock-button").addEventListener("click", unlock);
  document.querySelector("#input-eth").addEventListener('input', (event) => {
    var value = document.querySelector("#input-eth").value;
    // document.querySelector("#output-revo").value = value * (ethPeggedPrice/revoPrice);
    document.querySelector("#output-revo").value = value / revoPrice;
  });
  document.querySelector("#output-revo").addEventListener('input', (event) => {
    var value = document.querySelector("#output-revo").value;
    document.querySelector("#input-eth").value = value * revoPrice;
  });
});

function setProgressbar(value) {
  var elem = document.getElementById("barStatus");   
  elem.style.width = value + '%'; 
}

function getSlicedAddress(address) {
  tokenContract.methods.getSlicedAddress(address).call(function(error, sliced){
      console.log("Sliced => " + sliced);
  });
}

var dateFormat = function () {
  var    token = /d{1,4}|m{1,4}|yy(?:yy)?|([HhMsTt])\1?|[LloSZ]|"[^"]*"|'[^']*'/g,
      timezone = /\b(?:[PMCEA][SDP]T|(?:Pacific|Mountain|Central|Eastern|Atlantic) (?:Standard|Daylight|Prevailing) Time|(?:GMT|UTC)(?:[-+]\d{4})?)\b/g,
      timezoneClip = /[^-+\dA-Z]/g,
      pad = function (val, len) {
          val = String(val);
          len = len || 2;
          while (val.length < len) val = "0" + val;
          return val;
      };

  // Regexes and supporting functions are cached through closure
  return function (date, mask, utc) {
      var dF = dateFormat;

      // You can't provide utc if you skip other args (use the "UTC:" mask prefix)
      if (arguments.length == 1 && Object.prototype.toString.call(date) == "[object String]" && !/\d/.test(date)) {
          mask = date;
          date = undefined;
      }

      // Passing date through Date applies Date.parse, if necessary
      date = date ? new Date(date) : new Date;
      if (isNaN(date)) throw SyntaxError("invalid date");

      mask = String(dF.masks[mask] || mask || dF.masks["default"]);

      // Allow setting the utc argument via the mask
      if (mask.slice(0, 4) == "UTC:") {
          mask = mask.slice(4);
          utc = true;
      }

      var    _ = utc ? "getUTC" : "get",
          d = date[_ + "Date"](),
          D = date[_ + "Day"](),
          m = date[_ + "Month"](),
          y = date[_ + "FullYear"](),
          H = date[_ + "Hours"](),
          M = date[_ + "Minutes"](),
          s = date[_ + "Seconds"](),
          L = date[_ + "Milliseconds"](),
          o = utc ? 0 : date.getTimezoneOffset(),
          flags = {
              d:    d,
              dd:   pad(d),
              ddd:  dF.i18n.dayNames[D],
              dddd: dF.i18n.dayNames[D + 7],
              m:    m + 1,
              mm:   pad(m + 1),
              mmm:  dF.i18n.monthNames[m],
              mmmm: dF.i18n.monthNames[m + 12],
              yy:   String(y).slice(2),
              yyyy: y,
              h:    H % 12 || 12,
              hh:   pad(H % 12 || 12),
              H:    H,
              HH:   pad(H),
              M:    M,
              MM:   pad(M),
              s:    s,
              ss:   pad(s),
              l:    pad(L, 3),
              L:    pad(L > 99 ? Math.round(L / 10) : L),
              t:    H < 12 ? "a"  : "p",
              tt:   H < 12 ? "am" : "pm",
              T:    H < 12 ? "A"  : "P",
              TT:   H < 12 ? "AM" : "PM",
              Z:    utc ? "UTC" : (String(date).match(timezone) || [""]).pop().replace(timezoneClip, ""),
              o:    (o > 0 ? "-" : "+") + pad(Math.floor(Math.abs(o) / 60) * 100 + Math.abs(o) % 60, 4),
              S:    ["th", "st", "nd", "rd"][d % 10 > 3 ? 0 : (d % 100 - d % 10 != 10) * d % 10]
          };

      return mask.replace(token, function ($0) {
          return $0 in flags ? flags[$0] : $0.slice(1, $0.length - 1);
      });
  };
}();

// Some common format strings
dateFormat.masks = {
  "default":      "ddd mmm dd yyyy HH:MM:ss",
  shortDate:      "m/d/yy",
  mediumDate:     "mmm d, yyyy",
  longDate:       "mmmm d, yyyy",
  fullDate:       "dddd, mmmm d, yyyy",
  shortTime:      "h:MM TT",
  mediumTime:     "h:MM:ss TT",
  longTime:       "h:MM:ss TT Z",
  isoDate:        "yyyy-mm-dd",
  isoTime:        "HH:MM:ss",
  isoDateTime:    "yyyy-mm-dd'T'HH:MM:ss",
  isoUtcDateTime: "UTC:yyyy-mm-dd'T'HH:MM:ss'Z'"
};

// Internationalization strings
dateFormat.i18n = {
  dayNames: [
      "Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat",
      "Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"
  ],
  monthNames: [
      "Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec",
      "January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"
  ]
};

// For convenience...
Date.prototype.format = function (mask, utc) {
  return dateFormat(this, mask, utc);
};