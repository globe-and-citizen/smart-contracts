// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

import "@openzeppelin/contracts/utils/Strings.sol";

//this contract is the first version of  crypto payment goal for celebrity fanalyzer..
/**
 * @title CompetitionEscrow
 * @dev This contract handles escrow for competition purposes. It allows for funds to be deposited upon prompt creation
 * and released to the winner upon selection. The contract includes functionality to pause and unpause operations.
 */
// This contract is the first version of crypto payment goal for celebrity fanalyzer.
// This contract is the first version of crypto payment goal for celebrity fanalyzer.
/**
 * @title CompetitionEscrow
 * @dev This contract handles escrow for competition purposes. It allows for funds to be deposited upon prompt creation
 * and released to the winner upon selection. The contract includes functionality to pause and unpause operations.
 */
contract CompetitionEscrow is Ownable(msg.sender), Pausable, ReentrancyGuard {
    using Strings for uint256;
    
    struct EscrowData {
        string escrowCode; // Unique code for the escrow
        address payable depositor; // Address of the user who deposited the funds
        address payable recipient; // Address of the recipient (winner of the competition)
        uint256 amount; // Amount of funds deposited
        bool isRefunded; // Flag indicating if the funds have been refunded
        bool isReleased; // Flag indicating if the funds have been released
    }

    mapping(uint256 => EscrowData) private escrows;
    mapping(string => uint256) public escrowCodeToId;
    uint256 private escrowIdCounter = 0;

    event Deposited(string indexed escrowCode, uint256 indexed escrowId, address indexed depositor, uint256 amount);
    event Released(string indexed escrowCode, uint256 indexed escrowId, address indexed recipient, uint256 amount);
    event Refunded(string indexed escrowCode, uint256 indexed escrowId, address indexed depositor, uint256 amount);
    event RecipientSet(string indexed escrowCode, uint256 indexed escrowId, address indexed recipient);

    /**
     * @dev Generates a unique campaign code.
     * @return A unique campaign code as a string.
     */
    function generateEscrowCode() internal view returns (string memory) {
        uint256 randomNumber = uint256(keccak256(abi.encodePacked(block.timestamp, block.prevrandao, msg.sender))) % 1000000;
        return string(abi.encodePacked("ESCROW-", block.timestamp.toString(), "-", randomNumber.toString()));
    }

    /**
     * @dev Deposits funds into the escrow and generates a unique code for the deposit.
     * This is used when a prompt is created and funds are added for the competition.
     */
    function deposit() external payable whenNotPaused {
        string memory escrowCode = generateEscrowCode();
        uint256 newEscrowId = ++escrowIdCounter;
        escrows[newEscrowId] = EscrowData({
            escrowCode: escrowCode,
            depositor: payable(msg.sender),
            recipient: payable(address(0)),
            amount: msg.value,
            isRefunded: false,
            isReleased: false
        });
        escrowCodeToId[escrowCode] = newEscrowId;

        emit Deposited(escrowCode, newEscrowId, msg.sender, msg.value);
    }

    /**
     * @dev Allows the depositor to set the recipient of the escrow after the competition ends.
     * This should be called once the winner of the prompt competition is decided.
     * @param escrowCode The unique code of the escrow.
     * @param recipient The address of the recipient (winner).
     */
    function setRecipient(string memory escrowCode, address payable recipient) external whenNotPaused {
        uint256 escrowId = escrowCodeToId[escrowCode];
        EscrowData storage escrow = escrows[escrowId];
        require(msg.sender == escrow.depositor, "Only the depositor can set the recipient.");
        require(!escrow.isReleased, "Funds already released.");
        require(!escrow.isRefunded, "Funds have been refunded.");
        require(escrow.recipient == address(0), "Recipient already set.");
        require(recipient != address(0), "Recipient address cannot be zero address.");

        escrow.recipient = recipient;
        emit RecipientSet(escrowCode, escrowId, recipient);
    }

    /**
     * @dev Allows the recipient to release the funds.
     * @param escrowCode The unique code of the escrow.
     */
    function release(string memory escrowCode) external nonReentrant whenNotPaused {
        uint256 escrowId = escrowCodeToId[escrowCode];
        EscrowData storage escrow = escrows[escrowId];
        require(!escrow.isReleased, "Funds already released.");
        require(!escrow.isRefunded, "Funds have been refunded.");
        require(escrow.recipient != address(0), "Recipient not set.");
        require(escrow.recipient == msg.sender, "Only the recipient can release the funds.");

        (bool success, ) = escrow.recipient.call{value: escrow.amount}("");
        require(success, "Transfer failed.");
        escrow.isReleased = true;

        emit Released(escrowCode, escrowId, escrow.recipient, escrow.amount);
    }

    /**
     * @dev Allows the depositor to refund the deposited funds back to themselves.
     * This can be used if the competition is cancelled or if no winner is selected.
     * @param escrowCode The unique code of the escrow.
     */
    function refund(string memory escrowCode) external nonReentrant whenNotPaused {
        uint256 escrowId = escrowCodeToId[escrowCode];
        EscrowData storage escrow = escrows[escrowId];
        require(msg.sender == escrow.depositor, "Only the depositor can refund the funds.");
        require(!escrow.isReleased, "Funds already released.");
        require(!escrow.isRefunded, "Funds have been refunded.");

        (bool success, ) = escrow.depositor.call{value: escrow.amount}("");
        require(success, "Transfer failed.");
        escrow.isRefunded = true;

        emit Refunded(escrowCode, escrowId, escrow.depositor, escrow.amount);
    }

    /**
     * @dev Pauses the contract, preventing certain actions from being performed.
     * This function can only be called by the contract owner.
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @dev Unpauses the contract, allowing actions to be performed again.
     * This function can only be called by the contract owner.
     */
    function unpause() external onlyOwner {
        _unpause();
    }
}