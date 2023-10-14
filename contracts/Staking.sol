//SPDX-License-Identifier: MIT

pragma solidity 0.8.21;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

error StakingNeedsMoreThanZero();
/**
 * @title Staking
 * @dev Stake an ERC20 token, withdraw it and claim rewards.
 */
contract Staking is ReentrancyGuard {
    using SafeERC20 for IERC20;

    IERC20 public stakingToken;
    IERC20 public rewardToken;

    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping (address => uint256) public rewards;

    mapping (address => uint256) private _balances;
    
    uint256 public constant REWARD_RATE = 100;
    uint256 private _totalSupply;
    uint256 public rewardPerTokensStaked;
    uint256 public lastUpdateTime;

    modifier updateReward(address account) {
        rewardPerTokensStaked = rewardPerToken();
        lastUpdateTime = block.timestamp;
        rewards[account] = earned(account);
        _;
    }

    modifier moreThanZero(uint256 amount) {
        if (amount == 0) {
            revert StakingNeedsMoreThanZero();
        }
        _;
    }

    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 amount);

    /**
     * @param _stakingToken The address of a token to stake in the contract.
     */
    constructor (address _stakingToken, address _rewardToken) {
        stakingToken = IERC20(_stakingToken);
        rewardToken = IERC20(_rewardToken);
    }

    /**
     * @dev Calculates the reward per token
     */
    function rewardPerToken() public view returns (uint256) {
        if (_totalSupply == 0) {
            return rewardPerTokensStaked;
        }        
        return rewardPerTokensStaked + (((block.timestamp - lastUpdateTime) * REWARD_RATE * 1e18) / _totalSupply);
    }

    /**
     * @dev Calculates the reward per account
     * @param account The account to calculate the rewards.
     */
    function earned(address account) public view returns(uint256) {
        return (_balances[account] * (rewardPerToken() - userRewardPerTokenPaid[account]))/1e18 + rewards[account];
    }

    /**
     * @dev Stakes the `amount`of token
     * @param amount The amount of token to stake.
     */
    function stake(uint256 amount) external moreThanZero(amount) nonReentrant updateReward(msg.sender) {
        _balances[msg.sender] += amount;
        _totalSupply += amount; 
        stakingToken.safeTransferFrom(msg.sender, address(this), amount);
        emit Staked(msg.sender, amount);
    }

    /**
     * @dev Withdraws the `amount`of token
     * @param amount The amount of token to withdraw.
     */
    function withdraw(uint256 amount) external moreThanZero(amount) nonReentrant  updateReward(msg.sender) {
        _balances[msg.sender] -= amount;
        _totalSupply -= amount; 
        stakingToken.safeTransfer(msg.sender, amount);
        emit Withdrawn(msg.sender, amount);
    }

    /**
     * @dev A user claims rewards from the contract, if it has them.
     */
    function claimRewards() external nonReentrant updateReward(msg.sender) {
        uint256 reward = rewards[msg.sender];
        if (reward > 0) {
            rewards[msg.sender] = 0;
            rewardToken.safeTransfer(msg.sender, reward);
            emit RewardPaid(msg.sender, reward);
        }
    }

    /**
     * @dev Returns the total supply of staked tokens
     */
    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev Returns the balance of `account`
     * @param account The account to check the balance. 
     */
    function balanceOf(address account) external view returns (uint256) {
        return _balances[account];
    }
}
