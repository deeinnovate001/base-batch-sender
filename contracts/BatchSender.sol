// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract BatchSender is Ownable {
    event ETHTransferred(address indexed sender, address[] recipients, uint256[] amounts, uint256 feeCharged);
    event TokenTransferred(address indexed sender, address token, address[] recipients, uint256[] amounts, uint256 feeCharged);
    
    address public constant FEE_WALLET = 0x75F387d2351785174f20474308C71E578feFCFF6;
    uint256 public feePercentage = 10; // 0.1% fee (10 basis points)
    
    constructor() Ownable(msg.sender) {}
    
    function sendETH(address[] calldata recipients, uint256[] calldata amounts) external payable {
        require(recipients.length == amounts.length, "Arrays must be same length");
        require(recipients.length > 0, "No recipients provided");
        require(recipients.length <= 100, "Max 100 recipients per batch");
        
        uint256 totalAmount = calculateTotal(amounts);
        uint256 fee = calculateFee(totalAmount);
        uint256 totalRequired = totalAmount + fee;
        
        require(msg.value >= totalRequired, "Insufficient ETH sent");
        
        // Transfer fee to fee wallet
        if (fee > 0) {
            (bool feeSuccess, ) = FEE_WALLET.call{value: fee}("");
            require(feeSuccess, "Fee transfer failed");
        }
        
        // Transfer to recipients
        for (uint256 i = 0; i < recipients.length; i++) {
            require(recipients[i] != address(0), "Invalid recipient address");
            require(amounts[i] > 0, "Amount must be greater than 0");
            
            (bool success, ) = recipients[i].call{value: amounts[i]}("");
            require(success, "ETH transfer failed");
        }
        
        // Refund excess ETH
        if (msg.value > totalRequired) {
            payable(msg.sender).transfer(msg.value - totalRequired);
        }
        
        emit ETHTransferred(msg.sender, recipients, amounts, fee);
    }
    
    function sendToken(address token, address[] calldata recipients, uint256[] calldata amounts) external payable {
        require(recipients.length == amounts.length, "Arrays must be same length");
        require(recipients.length > 0, "No recipients provided");
        require(recipients.length <= 100, "Max 100 recipients per batch");
        
        uint256 totalAmount = calculateTotal(amounts);
        uint256 fee = calculateFee(totalAmount);
        
        // Require ETH for fee payment
        require(msg.value >= fee, "Insufficient ETH for fee");
        
        // Transfer fee to fee wallet
        if (fee > 0) {
            (bool feeSuccess, ) = FEE_WALLET.call{value: fee}("");
            require(feeSuccess, "Fee transfer failed");
        }
        
        // Transfer tokens to recipients
        for (uint256 i = 0; i < recipients.length; i++) {
            require(recipients[i] != address(0), "Invalid recipient address");
            require(amounts[i] > 0, "Amount must be greater than 0");
            
            bool success = IERC20(token).transferFrom(msg.sender, recipients[i], amounts[i]);
            require(success, "Token transfer failed");
        }
        
        // Refund excess ETH
        if (msg.value > fee) {
            payable(msg.sender).transfer(msg.value - fee);
        }
        
        emit TokenTransferred(msg.sender, token, recipients, amounts, fee);
    }
    
    function setFeePercentage(uint256 _feePercentage) external onlyOwner {
        require(_feePercentage <= 100, "Fee cannot exceed 1%"); // Max 1%
        feePercentage = _feePercentage;
    }
    
    function withdrawStuckETH() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }
    
    function calculateTotal(uint256[] calldata amounts) public pure returns (uint256) {
        uint256 total = 0;
        for (uint256 i = 0; i < amounts.length; i++) {
            total += amounts[i];
        }
        return total;
    }
    
    function calculateFee(uint256 amount) public view returns (uint256) {
        return (amount * feePercentage) / 10000; // Basis points (10000 = 100%)
    }
    
    function getFeeDetails(uint256 totalAmount) public view returns (uint256 fee, uint256 totalWithFee) {
        fee = calculateFee(totalAmount);
        totalWithFee = totalAmount + fee;
    }
    
    // Function to receive ETH (fallback)
    receive() external payable {}
}
