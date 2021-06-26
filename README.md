# SplitPay
Smart contract that forwards a payment to an address, or splits a payment between two addresses, while taking a cut.


## Usage

### deposit(...)
Deposits the value sent to the contract and records `receiverPerc`% for the `receiver` and `100 - receiverPerc`% for the owner of the contract.

E.g. sending 100 wei while calling `deposit(0xABC..., 98)` deposits 100 wei to the contracts and records 98 wei for address 0xABC... and 2 wei for the owner.

### depositReferral(...)
Deposits the value sent to the contract and records `receiverPerc`% for the `receiver`, `referralPerc`% for the `referral`, and `100 - receiverPerc - referralPerc`% for the owner of the contract.

E.g. sending 100 wei while calling `depositReferral(0xABC..., 98, 0x123..., 1)` deposits 100 wei to the contract and records 98 wei for address 0xABC..., 1 wei for address 0x123..., and 1 wei for the owner.

### withdraw()
Allows the caller to withdraw the amount of funds recorded for their address.

### depositsOf()
Returns the amount recorded for a specific address.

### fallbackBalance()
Returns the amount deposited through the fallback (i.e. sent wrongfully to the contract).

### ownerWithdraw()
Allows the owner of the contract to withdraw the funds deposited through the fallback.


## Dev
* `./compile.sh` compiles all contracts
* `./run-node.sh` starts a local ethereum blockchain node (run in separate terminal window)
* `./deploy.sh` deploys the compiled contracts to the local blockchain node
* `./run-test.sh` runs all tests
* `./console.sh` launches hardhat console
