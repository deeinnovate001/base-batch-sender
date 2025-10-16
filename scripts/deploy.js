async function main() {
  const [deployer] = await ethers.getSigners();
  
  console.log("Deploying contracts with the account:", deployer.address);
  console.log("Account balance:", (await deployer.provider.getBalance(deployer.address)).toString());

  const BatchSender = await ethers.getContractFactory("BatchSender");
  const batchSender = await BatchSender.deploy();
  
  await batchSender.waitForDeployment();
  
  const contractAddress = await batchSender.getAddress();
  console.log("BatchSender deployed to:", contractAddress);
  console.log("Fee wallet set to: 0x75F387d2351785174f20474308C71E578feFCFF6");
  console.log("Initial fee percentage: 0.1%");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
