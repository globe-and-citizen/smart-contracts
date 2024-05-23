const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("AdCampaignManager", function () {
  let AdCampaignManager, adCampaignManager, owner, advertiser;

  beforeEach(async function () {
    // Get the contract factory and signers
    AdCampaignManager = await ethers.getContractFactory("AdCampaignManager");
    [owner, advertiser] = await ethers.getSigners();

    // Deploy the contract
    adCampaignManager = await AdCampaignManager.deploy();
    await adCampaignManager.waitForDeployment();
  });

  it("should create a new ad campaign", async function () {
    const budget = ethers.parseEther("1");
    const connectedAdCampaignManager = adCampaignManager.connect(advertiser);
    // Create the ad campaign
    const tx = await connectedAdCampaignManager.createAdCampaign(budget, {
      value: budget,
    });

    await expect(tx).to.emit(adCampaignManager, "AdCampaignCreated");

    const receipt = await tx.wait();
    const campaignCode = (await receipt.logs)[0].args[0];

    // Retrieve the details of the newly created campaign
    const campaign = await adCampaignManager.getAdCampaignByCode(campaignCode);

    // Assert that the advertiser of the newly created campaign is the connected address
    expect(campaign.advertiser).to.equal(advertiser.address);
  });

  it("should allow the owner to claim payment", async function () {
    const budget = ethers.parseEther("1");
    const tx=await adCampaignManager
      .connect(advertiser)
      .createAdCampaign(budget, { value: budget });
    
    const receipt = await tx.wait();
    const campaignCode = (await receipt.logs)[0].args[0];
    
    const currentAmountSpent = budget;

    const claimTx= await adCampaignManager
      .connect(owner)
      .claimPayment(campaignCode, currentAmountSpent);

    await expect(claimTx).to.emit(adCampaignManager, "PaymentReleased");

    const campaign = await adCampaignManager.getAdCampaignByCode(campaignCode);
    expect(campaign.status).to.equal(2); // Completed
  });

  
  it("should allow an advertiser to request withdrawal", async function () {
      const budget = ethers.parseEther("2");
      const createCampaignTx=await adCampaignManager.connect(advertiser).createAdCampaign(budget, { value: budget });
      
      const createCampaignReceipt = await createCampaignTx.wait();
      const campaignCode = (await createCampaignReceipt.logs)[0].args[0];

      const withdrawTx= await adCampaignManager.connect(advertiser).requestWithdrawal(campaignCode);
      await expect(withdrawTx).to.emit(adCampaignManager,'WithdrawalRequested')
      const campaign = await adCampaignManager.getAdCampaignByCode(campaignCode);
      expect(campaign.status).to.equal(1); // WithdrawalRequested
  });

  it("should allow the owner to approve withdrawal", async function () {
      const budget = ethers.parseEther("1");
      const createCampaignTx=await adCampaignManager.connect(advertiser).createAdCampaign(budget, { value: budget });
      
      const createCampaignReceipt = await createCampaignTx.wait();
      const campaignCode = (await createCampaignReceipt.logs)[0].args[0];
      

      const currentAmountSpent = ethers.parseEther("0.5");

      await adCampaignManager.connect(advertiser).requestWithdrawal(campaignCode);

      const approvalTx= await adCampaignManager.connect(owner).approveWithdrawal(campaignCode, currentAmountSpent);
      
      const campaign = await adCampaignManager.getAdCampaignByCode(campaignCode);

      await expect(approvalTx).to.emit(adCampaignManager,'BudgetWithdrawn').withArgs(campaignCode,campaign.advertiser,ethers.parseEther("0.5"));
      await expect(approvalTx).to.emit(adCampaignManager,'PaymentReleasedOnWithdrawApproval').withArgs(campaignCode,ethers.parseEther("0.5"));
     
      expect(campaign.status).to.equal(2); // Completed
  });

  it("should pause and unpause the contract", async function () {
      await adCampaignManager.connect(owner).pause();
      expect(await adCampaignManager.paused()).to.be.true;

      await adCampaignManager.connect(owner).unpause();
      expect(await adCampaignManager.paused()).to.be.false;
  });

  
});
