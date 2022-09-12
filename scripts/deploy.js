const hre = require("hardhat");

const args = require('../scripts/arguments.js');

async function main() {
    // Compiling all of the contracts again just in case
    await hre.run('compile');

    // Connect to the signer
    const [deployer] = await ethers.getSigners();
    console.log(`✅ Connected to ${deployer.address}`);

    // Deploy receivable token
    const ERC721Receivable = await ethers.getContractFactory("ERC721Receivable");
    
    // Get the arguments from the arguments.js file and use them to deploy
    receivable = await ERC721Receivable.deploy(...args);
    // Wait for it to be deployed
    receivable = await receivable.deployed();
    console.log("✅ ERC721Receivable deployed to:", receivable.address);
    
    console.table({
        "Deployer": deployer.address,
        "Remaining ETH Balance": parseInt((await deployer.getBalance()).toString()) / 1000000000000000000,
        "ERC721Receivable": receivable.address,
    })

    // Notes: With the contract deployed the sale will not be open.
    // To start the sale you will need to run the `setMintOpen` function.
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });