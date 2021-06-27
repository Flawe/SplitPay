// contracts/SplitPay.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract SplitPay is Ownable {

  event Deposit(address indexed receiver, uint256 amount, uint256 receiverPerc);
  event DepositReferral(address indexed receiver, address indexed referral, uint256 amount, uint256 receiverPerc, uint256 referralPerc);
  event Withdraw(address indexed receiver, uint256 amount);
  event ReceiveDeposit(address indexed sender, uint256 amount);
  event FallbackDeposit(address indexed sender, uint256 amount);
  event OwnerWithdraw(address indexed sender, uint256 amount);

  mapping(address => uint256) private deposited;
  uint256 private fallbackFunds;

  function depositsOf(address addr) external view returns (uint256) {
    return deposited[addr];
  }

  function deposit(address receiver, uint256 receiverPerc) external payable {
    require(receiver != address(0));
    require(receiverPerc <= 100, "Percentage is higher than 100");
    uint256 amount = msg.value;
    require(amount != 0, "Can not deposit 0 wei");

    uint256 receiverAmount = amount * receiverPerc / 100;
    deposited[receiver] += receiverAmount;
    address owner = owner();
    deposited[owner] += amount - receiverAmount;
    emit Deposit(receiver, amount, receiverPerc);
  }

  function depositReferral(address receiver, uint256 receiverPerc, address referral, uint256 referralPerc) external payable {
    require(receiver != address(0));
    require(referral != address(0));
    uint256 amount = msg.value;
    require(amount != 0, "Can not split deposit 0 wei");
    require(receiverPerc + referralPerc <= 100, "Percentages add up to more than 100");

    uint256 receiverAmount = amount * receiverPerc / 100;
    uint256 referralAmount = amount * referralPerc / 100;
    deposited[receiver] += receiverAmount;
    deposited[referral] += referralAmount;
    address owner = owner();
    deposited[owner] += amount - receiverAmount - referralAmount;
    emit DepositReferral(receiver, referral, amount, receiverPerc, referralPerc);
  }

  function withdraw() external {
    address sender = msg.sender;
    uint256 amount = deposited[sender];
    require(address(this).balance >= amount, "Contract balance too low");
    deposited[sender] = 0;
    (bool success, ) = sender.call{value: amount}("");
    require(success, "Transfer failed, recipient may have reverted.");
    emit Withdraw(sender, amount);
  }

  function fallbackBalance() external view returns (uint256) {
    return fallbackFunds;
  }

  function ownerWithdraw() external onlyOwner {
    require(fallbackFunds <= address(this).balance, "Balance lower than fallback funds!");
    uint256 amount = fallbackFunds;
    fallbackFunds = 0;
    (bool success, ) = msg.sender.call{value: amount}("");
    require(success, "Transfer failed, recipient may have reverted.");
    emit OwnerWithdraw(msg.sender, amount);
  }

  receive() external payable {
    uint256 amount = msg.value;
    fallbackFunds += amount;
    emit ReceiveDeposit(msg.sender, amount);
  }

  fallback() external payable {
    uint256 amount = msg.value;
    fallbackFunds += amount;
    emit FallbackDeposit(msg.sender, amount);
  }
}
