pragma solidity ^0.5.0;

import "openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "openzeppelin-solidity/contracts/math/SafeMath.sol";

//interfaces
contract ERC20Interface {
    function totalSupply() public view returns (uint);
    function balanceOf(address tokenOwner) public view returns (uint balance);
    function allowance(address tokenOwner, address spender) public view returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

contract LoomBalanceContract is Ownable {
  using SafeMath for uint256;

  address fundingWalletAddress;
  address tokenContractAddress;
  address usdcContractAddress;

  mapping(address => uint256) internal kudoPurchaseBalance;
  mapping(address => uint256) internal kudoEarnedBalance;
  mapping(address => uint256) internal usdcBalance;

  uint256 internal kudoOwnedByContract;
  uint256 internal usdcOwnedByContract;

  function getBalance(uint tokenID, address owner)
    public view returns(uint256){

    if(tokenID == 1) {
      //KUDO
      return kudoPurchaseBalance[owner];
    } else if(tokenID == 2) {
      //USDC
      return usdcBalance[owner];
    } else if(tokenID == 3) {
      //KUDO Earned
      return kudoEarnedBalance[owner];
    }

    return 0;
  }

  // ***
  //SET TOKEN CONTRACT ADDRESSES
  // ***
  event SetContractAddressesEvent(address tokenContractAddress, address usdcContractAddress, address _fundingWalletAddress);

  function setContractAddresses(address _tokenContractAddress, address _usdcContractAddress, address _fundingWalletAddress) public {
    require(msg.sender == owner, "only owner can set the address");
    tokenContractAddress = _tokenContractAddress;
    usdcContractAddress = _usdcContractAddress;
    fundingWalletAddress = _fundingWalletAddress;

    emit SetContractAddressesEvent(_tokenContractAddress, _usdcContractAddress, _fundingWalletAddress);
  }

  function getTokenContractAddresses() public view returns (address, address, address) {
    return (address(tokenContractAddress), address(usdcContractAddress), address(fundingWalletAddress));
  }


  //Deposit KUDO
  mapping (uint256 => DepositUnit) listOfDeposits;
  uint256[] listOfDepositsIndex;

  struct DepositUnit {
      uint256 depositID;
      uint depositTokenTypeID;
      address depositBy;
      uint256 depositAmountInTokens;
      uint256 depositDate;
      uint256 depositBlockNumber;
  }

  event DepositTokenEvent(uint256 _depositID, uint256 _depositTokenTypeID, address _depositBy, uint256 _depositAmount);

  //_depositTokenID
  //1 = KUDO, 2 = USDC Chain Token
  function depositToken(uint _depositTokenTypeID, uint256 _depositAmount)
    public returns (bool) {

    address _tokenContractAddress;
    if(_depositTokenTypeID == 1){
      _tokenContractAddress = tokenContractAddress;
    }
    else if(_depositTokenTypeID == 2){
      _tokenContractAddress = usdcContractAddress;
    }
    else {
      revert("invalid _depositTokenTypeID");
    }

    uint256 newDepositID = listOfDepositsIndex.length + 1;
    listOfDeposits[newDepositID].depositID = newDepositID;
    listOfDeposits[newDepositID].depositTokenTypeID = _depositTokenTypeID;
    listOfDeposits[newDepositID].depositBy = msg.sender;
    listOfDeposits[newDepositID].depositAmountInTokens = _depositAmount;
    listOfDeposits[newDepositID].depositDate = block.timestamp;
    listOfDeposits[newDepositID].depositBlockNumber = block.number;

    if (listOfDepositsIndex.length <= newDepositID) {
      listOfDepositsIndex.push(newDepositID);
    }

    if (!ERC20Interface(_tokenContractAddress).transferFrom(msg.sender, address(this), _depositAmount)) {
      revert("depositToken.transferFrom failed");
    }


    if(_depositTokenTypeID == 1){
      kudoPurchaseBalance[msg.sender] = kudoPurchaseBalance[msg.sender].add(_depositAmount);
      kudoOwnedByContract = kudoOwnedByContract.add(_depositAmount);
    }
    else if(_depositTokenTypeID == 2){
      usdcBalance[msg.sender] = usdcBalance[msg.sender].add(_depositAmount);
      usdcOwnedByContract = usdcOwnedByContract.add(_depositAmount);
    }

    emit DepositTokenEvent(newDepositID, _depositTokenTypeID, msg.sender, _depositAmount);

    return true;
  }

  //Withdraw KUDO
  uint256[] listOfWithdrawalsIndex;
  event WithdrawKudoEvent(uint256 _withdrawID, address _withdrawBy, uint256 _withdrawAmountInTokens);

  //1 = KUDO, 2 = USDC Chain Token
  function withDrawToken(uint _withdrawTokenTypeID, uint256 _withdrawAmount)
    public returns (bool) {

    address _tokenContractAddress;
    if(_withdrawTokenTypeID == 1){
      _tokenContractAddress = tokenContractAddress;
      if(kudoPurchaseBalance[msg.sender] < _withdrawAmount){
        revert("kudoPurchaseBalance is lower than _withdrawAmount");
      }
      kudoPurchaseBalance[msg.sender] = kudoPurchaseBalance[msg.sender].sub(_withdrawAmount);
      kudoOwnedByContract = kudoOwnedByContract.sub(_withdrawAmount);

    } else if(_withdrawTokenTypeID == 2){
      _tokenContractAddress = usdcContractAddress;
      if(usdcBalance[msg.sender] < _withdrawAmount){
        revert("usdcBalance is lower than _withdrawAmount");
      }
      usdcBalance[msg.sender] = usdcBalance[msg.sender].sub(_withdrawAmount);
      usdcOwnedByContract = usdcOwnedByContract.sub(_withdrawAmount);

    }
    else {
      revert("invalid _withdrawTokenTypeID");
    }


    //transfer
    if (!ERC20Interface(_tokenContractAddress).transfer(msg.sender, _withdrawAmount)) {
      revert("withDrawToken.transfer failed");
    }

    uint256 newWithdrawalID = listOfWithdrawalsIndex.length + 1;

    if (listOfWithdrawalsIndex.length <= newWithdrawalID) {
      listOfWithdrawalsIndex.push(newWithdrawalID);
    }

    emit WithdrawKudoEvent(newWithdrawalID, msg.sender, _withdrawAmount);

    return true;
  }

  //sell usdc for kudo
  event SellKudoForUSDCEvent(address from, address to, uint256 _sellAmountInTokens, uint256 usdcTokensToReceive);
  event CalcTest1(uint256 result);
  event CalcTest2(uint256 result);

  //1.00 USDC is 2.00 KUDO so 2.00 USDC per KUDO
  //meaning => 1.00/2.00 is 0.50 KUDO per USDC
  uint256 internal rateUSDCperKUDO = 200;
  uint256 internal rateKUDOperUSDC = 50;

  uint256 internal tokendecimals = 2;//2 decimals

  //100.00 KUDO TOKENS 2 decimals
  //5.00 USDC token 2 decimals
  //sell kudo for usdc deduct 10%
  function sellKudoForUSDC(uint256 _sellAmountInTokens)
    public returns (bool) {

    /*
    emit CalcTest1(10**tokendecimals);
    emit CalcTest2(_sellAmountInTokens.div(10**tokendecimals).mul(rateUSDCperKUDO));
    */

    //check that seller has enough of kudo tokens
    if(kudoPurchaseBalance[msg.sender] < _sellAmountInTokens){
      revert("kudoPurchaseBalance is lower than _sellAmountInTokens");
    }

    uint256 _sellAmountInTokens10percent = _sellAmountInTokens.div(10);
    uint256 _sellAmountInTokensAfterFees = _sellAmountInTokens.sub(_sellAmountInTokens10percent);

    //check that the contract has enough of USDC tokens
    uint256 usdcTokensToReceive = _sellAmountInTokensAfterFees.div(10**tokendecimals).mul(rateUSDCperKUDO);
    //uint256 usdcTokensToReceive = _sellAmountInTokens.div(10**tokendecimals).mul(rateUSDCperKUDO);

    /*
    emit CalcTest1(usdcTokensToReceive);
    emit CalcTest2(usdcBalance[fundingWalletAddress]);
    */
    if(usdcBalance[fundingWalletAddress] <= usdcTokensToReceive){
      revert("usdcBalance in fundingWalletAddress is lower than usdcTokensToReceive");
     }

    //transfer kudo tokens
    kudoPurchaseBalance[msg.sender] = kudoPurchaseBalance[msg.sender].sub(_sellAmountInTokens);
    kudoPurchaseBalance[fundingWalletAddress] = kudoPurchaseBalance[fundingWalletAddress].add(_sellAmountInTokens);

    //transfer usdc tokens
    usdcBalance[fundingWalletAddress] = usdcBalance[fundingWalletAddress].sub(usdcTokensToReceive);
    usdcBalance[msg.sender] = usdcBalance[msg.sender].add(usdcTokensToReceive);
    emit SellKudoForUSDCEvent(fundingWalletAddress, msg.sender, _sellAmountInTokens, usdcTokensToReceive);
    return true;
  }

  event SellUSDCForKUDOEvent(address from, address to, uint256 _sellAmountInUSDC, uint256 kudoTokensToReceive);

  function sellUSDCForKudo(uint256 _sellAmountInUSDC)
    public returns (bool) {

    /*
    emit CalcTest1(10**tokendecimals);
    emit CalcTest2(_sellAmountInUSDC.div(10**tokendecimals).mul(rateKUDOperUSDC));
    */

    //check that seller has enough of kudo tokens
    if(usdcBalance[msg.sender] < _sellAmountInUSDC){
      revert("usdcBalance is lower than _sellAmountInUSDC");
    }

    //check that the contract has enough of USDC tokens
    uint256 kudoTokensToReceive = _sellAmountInUSDC.div(10**tokendecimals).mul(rateKUDOperUSDC);
    /*
    emit CalcTest1(usdcTokensToReceive);
    emit CalcTest2(usdcBalance[fundingWalletAddress]);
    */
    if(kudoPurchaseBalance[fundingWalletAddress] <= kudoTokensToReceive){
      revert("kudoPurchaseBalance in fundingWalletAddress is lower than kudoTokensToReceive");
    }

    //transfer usdc tokens
    usdcBalance[msg.sender] = usdcBalance[msg.sender].sub(_sellAmountInUSDC);
    usdcBalance[fundingWalletAddress] = usdcBalance[fundingWalletAddress].add(_sellAmountInUSDC);

    //transfer kudo tokens
    kudoPurchaseBalance[fundingWalletAddress] = kudoPurchaseBalance[fundingWalletAddress].sub(kudoTokensToReceive);
    kudoPurchaseBalance[msg.sender] = kudoPurchaseBalance[msg.sender].add(kudoTokensToReceive);

    emit SellUSDCForKUDOEvent(fundingWalletAddress, msg.sender, _sellAmountInUSDC, kudoTokensToReceive);
    return true;
  }
}