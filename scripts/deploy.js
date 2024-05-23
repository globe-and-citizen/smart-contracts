async function main() {
    // Get the contract factory
    const AdCampaignManager = await ethers.getContractFactory("AdCampaignManager");

    // Deploy the contract
    const adCampaignManager = await AdCampaignManager.deploy();

    // Wait for deployment to complete
    await adCampaignManager.waitForDeployment();

    console.log("deployed contract:", adCampaignManager);
}

// Execute the main function
main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
