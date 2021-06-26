// contracts/SplitPay.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract SplitPay is Ownable {
  using SafeMath for uint256;

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

    uint256 receiverAmount = amount.mul(receiverPerc).div(100);
    deposited[receiver] = deposited[receiver].add(receiverAmount);
    address owner = owner();
    deposited[owner] = deposited[owner].add(amount.sub(receiverAmount));
    emit Deposit(receiver, amount, receiverPerc);
  }

  function depositReferral(address receiver, uint256 receiverPerc, address referral, uint256 referralPerc) external payable {
    require(receiver != address(0));
    require(referral != address(0));
    uint256 amount = msg.value;
    require(amount != 0, "Can not split deposit 0 wei");
    require(receiverPerc.add(referralPerc) <= 100, "Percentages add up to more than 100");

    uint256 receiverAmount = amount.mul(receiverPerc).div(100);
    uint256 referralAmount = amount.mul(referralPerc).div(100);
    deposited[receiver] = deposited[receiver].add(receiverAmount);
    deposited[referral] = deposited[referral].add(referralAmount);
    address owner = owner();
    deposited[owner] = deposited[owner].add(amount.sub(receiverAmount).sub(referralAmount));
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
    fallbackFunds = fallbackFunds.add(amount);
    emit ReceiveDeposit(msg.sender, amount);
  }

  fallback() external payable {
    uint256 amount = msg.value;
    fallbackFunds = fallbackFunds.add(amount);
    emit FallbackDeposit(msg.sender, amount);
  }
}
