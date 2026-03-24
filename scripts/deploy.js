const hre = require("hardhat");

async function main() {
  console.log("Deploying FullNFT contract...");

  const [deployer] = await hre.ethers.getSigners();
  console.log("Deploying with account:", deployer.address);

  const FullNFT = await hre.ethers.getContractFactory("FullNFT");
  
  const contract = await FullNFT.deploy(
    "MyNFT",                                        // name
    "MNFT",                                         // symbol
    "https://hidden.example.com/metadata.json",     // hiddenMetadataURI
    "0x0000000000000000000000000000000000000000000000000000000000000000" // merkleRoot
  );

  await contract.waitForDeployment();

  console.log("FullNFT deployed to:", await contract.getAddress());
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
