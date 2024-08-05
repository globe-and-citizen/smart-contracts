const hre = require("hardhat");
const readline = require("readline");

async function main() {
    // Get the contract factory
    const AdCampaignManager = await hre.ethers.getContractFactory("AdCampaignManager");

    // Estimate the gas required for deployment
    const deployTransaction = await AdCampaignManager.getDeployTransaction();
    const gasEstimate = await hre.ethers.provider.estimateGas(deployTransaction);

    // Get the current gas price
    // Get the current gas price
    const gasPrice = await hre.network.provider.send("eth_gasPrice");

    // Ensure both values are BigNumbers
    const gasEstimateBigNumber = hre.ethers.toBigInt(gasEstimate.toString());
    const gasPriceBigNumber = hre.ethers.toBigInt(gasPrice.toString());

    // Calculate the total gas cost in MATIC
    const gasCost = gasEstimateBigNumber*gasPriceBigNumber;
    const gasCostInMatic = hre.ethers.formatEther(gasCost);

    console.log(`Estimated gas cost for deployment: ${gasCostInMatic} MATIC`);

    // Ask for user confirmation
    const rl = readline.createInterface({
        input: process.stdin,
        output: process.stdout
    });

    const question = (str) => {
        return new Promise((resolve) => {
            rl.question(str, resolve);
        });
    };

    const answer = await question("Do you want to proceed with the deployment? (yes/no) ");
    rl.close();

    if (answer.toLowerCase() === "yes") {
        // Deploy the contract
        const adCampaignManager = await AdCampaignManager.deploy();

        // Wait for deployment to complete
        await adCampaignManager.deployed();

        console.log("Deployed contract address:", adCampaignManager.address);
    } else {
        console.log("Deployment cancelled.");
    }
}

// Execute the main function
main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
