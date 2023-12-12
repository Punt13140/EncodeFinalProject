// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/// @title Simple Launchpad Factory
/// @notice You can use this contract to create new Launchpad contracts
contract LaunchpadFactory is Ownable {

    event LaunchpadCreated(
        address indexed owner,
        address indexed launchpad,
        address indexed token
    );

    /// @notice Creates a new Launchpad contract
    function createLaunchpad(
        address token,
        uint256 totalAmount,
        uint256 saleStart,
        uint256 saleEnd,
        uint256 vestingStart,
        uint256 vestingEnd,
        uint256 ratio
    ) payable external returns (address) {
        require(msg.value == 0.01 ether, "0.01 ETH Fee is required");
        require(saleStart < saleEnd, "Invalid sale period");
        require(vestingStart < vestingEnd, "Invalid vesting period");
        Launchpad launchpad = new Launchpad(
            token,
            totalAmount,
            saleStart,
            saleEnd,
            vestingStart,
            vestingEnd,
            ratio
        );
        emit LaunchpadCreated(msg.sender, address(launchpad), token);
        return address(launchpad);
    }

    /// @notice Owner can use this to withdraw fees
    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        address payable _owner = payable(owner());
        payable(_owner).transfer(balance);
    }
}

/// @title ERC-20 Interface
interface IERC20 {
    function transfer(
        address recipient,
        uint256 amount
    ) external returns (bool);
}

/// @title A simple Launchpad contract
/// @notice You can use this contract to run a token sale with vesting
contract Launchpad is Ownable{
    IERC20 public token;
    uint256 public totalAmount;
    uint256 public saleStart;
    uint256 public saleEnd;
    uint256 public vestingStart;
    uint256 public vestingEnd;
    uint256 public ratio;
    mapping(address => uint256) public amountSold;
    mapping(address => uint256) public claimed;

    modifier saleActive() {
        require(
            block.timestamp >= saleStart && block.timestamp <= saleEnd,
            "Sale period invalid"
        );
        _;
    }

    modifier vestingStarted() {
        require(block.timestamp >= vestingStart, "Vesting not started");
        _;
    }

    /// @notice Constructor function
    /// @param _token launching token
    /// @param _totalAmount Total amount sold
    /// @param _saleStart sale start timestamp
    /// @param _saleEnd sale start timestamp
    /// @param _vestingStart vesting start timestamp
    /// @param _vestingEnd vesting end timestamp
    /// @param _ratio Amount of tokens given per ETH paid
    constructor(
        address _token,
        uint256 _totalAmount,
        uint256 _saleStart,
        uint256 _saleEnd,
        uint256 _vestingStart,
        uint256 _vestingEnd,
        uint256 _ratio
    ) {
        token = IERC20(_token);
        totalAmount = _totalAmount;
        saleStart = _saleStart;
        saleEnd = _saleEnd;
        vestingStart = _vestingStart;
        vestingEnd = _vestingEnd;
        ratio = _ratio;
    }

    /// @notice Owner can use this to withdraw ETH
    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        address payable _owner = payable(owner());
        payable(_owner).transfer(balance);
    }

    /// @notice Amount of claimable tokens
    function _claimable(address address_) internal view returns (uint256) {
        return _released(address_) - claimed[address_];
    }

    /// @notice Amount of released tokens
    function _released(address address_) internal view returns (uint256) {
        if (block.timestamp < vestingStart) {
            return 0;
        } else {
            if (block.timestamp > vestingEnd) {
                return amountSold[address_];
            } else {
                return (amountSold[address_] * (block.timestamp - vestingStart)) / (vestingEnd - vestingStart);
            }
        }
    }

    /// @notice Amount of outstanding tokens
    function outstanding(address address_) external view returns (uint256) {
        return amountSold[address_] - _released(address_);
    }

    /// @notice Users can buy token during active sale
    /// @dev no whale protection or allocations to not complicate things
    function buy(uint256 desiredTokens) external payable saleActive {
        require(desiredTokens > 0, "Token amount must be > 0");
        require(totalAmount >= desiredTokens, "Not enough tokens left");
        uint256 ethRequired = desiredTokens / ratio;
        require(
            ethRequired > 0 && ethRequired <= msg.value,
            "Insufficient ETH sent"
        );
        amountSold[msg.sender] += desiredTokens;
        totalAmount -= desiredTokens;
    }

    /// @notice Users can claim unlocked tokens
    function claim() external vestingStarted {
        uint256 claimableAmount = _claimable(msg.sender);
        claimed[msg.sender] += claimableAmount;
        token.transfer(msg.sender, claimableAmount);
    }
}