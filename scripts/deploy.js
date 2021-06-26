// scripts/deploy.js
async function main() {
  const SplitPay = await ethers.getContractFactory("SplitPay");
  console.log("Deploying SplitPay...");
  const splitPay = await SplitPay.deploy();
  await splitPay.deployed();
  console.log("SplitPay deployed to: ", splitPay.address);
}

main()
  .then(() => process.exit(0))
  .catch(e => {
    console.error(e);
    process.exit(1);
  });
