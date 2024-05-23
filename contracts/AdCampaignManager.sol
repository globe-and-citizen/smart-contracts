// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

import "@openzeppelin/contracts/utils/Strings.sol";

/** Author: Global &  Citizen 
    Purpose: Manage Advertisement on Celebrity fanalyze website.
     
**/

contract AdCampaignManager is Ownable(msg.sender), Pausable, ReentrancyGuard {
    
    using Strings for uint256;

    enum CampaignStatus { Active, WithdrawalRequested, Completed }

    struct AdCampaign {
        uint256 budget;
        uint256 amountSpent;
        CampaignStatus status;
        string campaignCode;
        address advertiser;
    }

    mapping(string => uint256) public campaignCodesToId;
    mapping(uint256 => AdCampaign) public adCampaigns;
    uint256 public adCampaignCount;

    event AdCampaignCreated(string campaignCode,uint256 budget);
    event PaymentReleased(string campaignCode, uint256 paymentAmount);
    event WithdrawalRequested(string campaignCode);
    event BudgetWithdrawn(string campaignCode,address advertiser, uint256 amount);
    event PaymentReleasedOnWithdrawApproval(string campaignCode, uint256 paymentAmount);

    constructor() {}

    // Create a new ad campaign with a unique campaign code
    function createAdCampaign(uint256 budget) external payable whenNotPaused nonReentrant  {
        require(msg.value >= budget, "Insufficient funds sent");

        adCampaignCount++;
        string memory campaignCode = generateCampaignCode();
        adCampaigns[adCampaignCount] = AdCampaign(budget, 0, CampaignStatus.Active, campaignCode, msg.sender);
        campaignCodesToId[campaignCode] = adCampaignCount;

        emit AdCampaignCreated(campaignCode, budget);
    }

    // Contract owner claims payment for an ad campaign if the budget is not exceeded
    function claimPayment(string memory campaignCode, uint256 currentAmountSpent) external onlyOwner whenNotPaused nonReentrant {
        uint256 campaignId = campaignCodesToId[campaignCode];
        require(campaignId > 0, "Invalid campaign code");
        AdCampaign storage campaign = adCampaigns[campaignId];
        require(campaign.status == CampaignStatus.Active, "Campaign is not active");
        require(currentAmountSpent >= campaign.budget, "Budget not reached");

        uint256 paymentAmount = currentAmountSpent;
        campaign.amountSpent = paymentAmount;
        campaign.status = CampaignStatus.Completed;
        payable(owner()).transfer(paymentAmount);

        emit PaymentReleased(campaignCode, paymentAmount);
    }

    // Advertiser requests to withdraw the remaining budget
    function requestWithdrawal(string memory campaignCode) external nonReentrant {
        uint256 campaignId = campaignCodesToId[campaignCode];
        require(campaignId > 0, "Invalid campaign code");
        AdCampaign storage campaign = adCampaigns[campaignId];
        require(campaign.status == CampaignStatus.Active, "Campaign is not active");
        require(msg.sender == campaign.advertiser, "Only the advertiser can request withdrawal");

        campaign.status = CampaignStatus.WithdrawalRequested;
        emit WithdrawalRequested(campaignCode);
    }

    // Contract owner approves the withdrawal and funds are immediately sent to the advertiser
    function approveWithdrawal(string memory campaignCode, uint256 currentAmountSpent) external onlyOwner nonReentrant {
        uint256 campaignId = campaignCodesToId[campaignCode];
        require(campaignId > 0, "Invalid campaign code");
        AdCampaign storage campaign = adCampaigns[campaignId];
        require(campaign.status == CampaignStatus.WithdrawalRequested, "Withdrawal not requested");
        require(currentAmountSpent <= campaign.budget, "Budget exceeded");

        campaign.amountSpent = currentAmountSpent;
        uint256 remainingBudget = campaign.budget- currentAmountSpent;

        campaign.status = CampaignStatus.Completed;
        if (remainingBudget > 0) {
            payable(campaign.advertiser).transfer(remainingBudget);
        }
        payable(owner()).transfer(currentAmountSpent);

        emit BudgetWithdrawn(campaignCode,campaign.advertiser, remainingBudget);

        emit PaymentReleasedOnWithdrawApproval(campaignCode, currentAmountSpent);
    }

    // Pause contract in case of emergency
    function pause() external onlyOwner {
        _pause();
    }

    // Unpause contract when the issue is resolved
    function unpause() external onlyOwner {
        _unpause();
    }

    // Generate a unique campaign code
    function generateCampaignCode() internal view returns (string memory) {
        uint256 randomNumber = uint256(keccak256(abi.encodePacked(block.timestamp, block.prevrandao, msg.sender))) % 1000000;
        return string(abi.encodePacked("CAMPAIGN-", block.timestamp.toString(), "-", randomNumber.toString()));
    }

    // Get details of an ad campaign by campaign code
    function getAdCampaignByCode(string memory campaignCode) external view returns (AdCampaign memory) {
        uint256 campaignId = campaignCodesToId[campaignCode];
        require(campaignId > 0, "Invalid campaign code");
        return adCampaigns[campaignId];
    }

    // Fallback function to receive MATIC payments
    receive() external payable {}
}
