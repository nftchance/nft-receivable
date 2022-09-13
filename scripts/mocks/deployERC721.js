const hre = require("hardhat");

async function main() {
    // Compiling all of the contracts again just in case
    await hre.run('compile');

    // Connect to the signer
    const [deployer] = await ethers.getSigners();
    console.log(`✅ Connected to ${deployer.address}`);

    // Deploy mock Token contract
    const Token = await hre.ethers.getContractFactory("MockERC721");
    
    // Get the arguments from the arguments.js file and use them to deploy
    token = await Token.deploy("Mock Token", "MOCK");
    // Wait for it to be deployed
    token = await token.deployed();
    console.log("✅ Token Mock deployed to:", token.address);
    
    console.table({
        "Deployer": deployer.address,
        "Remaining ETH Balance": parseInt((await deployer.getBalance()).toString()) / 1000000000000000000,
        "Token Mock": token.address,
    })
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });