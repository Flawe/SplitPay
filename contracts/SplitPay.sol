// contracts/SplitPay.sol
// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "@openzeppelin/contracts/access/Ownable.sol";

contract SplitPay is Ownable {

  event Deposit(address indexed receiver, uint256 amount, uint256 receiverPerc);
  event DepositReferral(address indexed receiver, address indexed referral, uint256 amount, uint256 receiverPerc, uint256 referralPerc);
  event Withdraw(address indexed receiver, uint256 amount);

  mapping(address => uint256) private deposited;

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
}
