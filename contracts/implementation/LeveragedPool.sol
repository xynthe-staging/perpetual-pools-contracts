// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;
pragma abicoder v2;

import "../abstract/AbstractLeveragedPool.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "./PoolToken.sol";

/*
@title The pool controller contract
*/
contract LeveragedPool is AbstractLeveragedPool, AccessControl {
  // #### Roles
  /**
  @notice The Updater role is for addresses that can update a pool's price
   */
  bytes32 public constant UPDATER = keccak256("UPDATER");

  /**
  @notice The Fee holder role is for addresses that can change the address that fees go to.
   */
  bytes32 public constant FEE_HOLDER = keccak256("FEE_HOLDER");

  // #### Functions
  /**
  @notice Sets up the contract. Sets the parameters, and creates the two ERC20 tokens for the pool.
  @param _poolCode The pool's identifier. This will be appended onto a position code (-SHORT, and -LONG) to create the token names.
  @param _firstPrice The current price for the market
  @param _updateInterval The minimum amount of time that must elapse before a price update can occur. If the interval is 5 minutes, then the price cannot be updated until 5 minutes after the last update has elapsed.
  @param _frontRunningInterval The amount of time that must elapse between a commit and the next update interval before a commit can be executed. Must be shorter than the update interval to prevent deadlock.
  @param _fee The percentage fee that will be charged to the pool's capital on a successful price update
  @param _leverageAmount The leverage that the pool will expose it's depositors to
  @param _feeAddress The address that fees will be sent to on every price change
  @param _quoteToken The address of the digital asset that this pool contains
   */
  constructor(
    string memory _poolCode,
    uint256 _firstPrice,
    uint32 _updateInterval,
    uint32 _frontRunningInterval,
    uint16 _fee,
    uint16 _leverageAmount,
    address _feeAddress,
    address _quoteToken
  )
    AbstractLeveragedPool(
      _poolCode,
      _firstPrice,
      _updateInterval,
      _frontRunningInterval,
      _fee,
      _leverageAmount,
      _feeAddress,
      _quoteToken
    )
  {}

  function commit(
    bytes2 commitType,
    uint256 maxImbalance,
    uint256 amount
  ) external override {}

  function uncommit(uint256 commitID) external override {}

  function executeCommitment(uint256[] memory commitID) external override {}

  function executePriceChange(uint256 endPrice) external override {}

  function updateFeeAddress(address account) external override {}

  // #### Modifiers
  /**
    @notice Requires caller to have been granted the UPDATER role. Use this for functions that should be restricted to the PoolKeeper
     */
  modifier onlyUpdater {
    require(hasRole(UPDATER, msg.sender));
    _;
  }

  /** 
  @notice Requires caller to have been granted the FEE_HOLDER role.
  */
  modifier onlyFeeHolder {
    require(hasRole(FEE_HOLDER, msg.sender));
    _;
  }
}
