// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;
pragma abicoder v2;

/*
@title The manager contract interface for multiple markets and the pools in them
*/
interface IPoolKeeper {
  // #### Structs

  struct Upkeep {
    int256 cumulativePrice; // The sum of all the samples for the current interval.
    int256 lastSamplePrice; // The last price added to the cumulative price
    int256 executionPrice; // The price for the current execution
    int256 lastExecutionPrice; // The last price executed on.
    uint32 count; // The number of samples taken during the current interval.
    uint32 updateInterval;
    uint32 roundStart;
  }

  // #### Events
  /**
  @notice Creates a notification when a pool is created
  @param poolAddress The pool address of the newly created pool. This is deterministic and utilizes create2 and the pool code as the salt.
  @param firstPrice The price of the market oracle when the pool was created. 
  @param updateInterval The pool's update interval. This is used for upkeep
  @param market The market the pool was created for. This combined with the updateInterval provide the upkeep details.
   */
  event CreatePool(
    address indexed poolAddress,
    int256 indexed firstPrice,
    uint32 indexed updateInterval,
    string market
  );

  /**
  @notice Creates a notification when a market is created
  @param marketCode The market identifier for the new market
  @param oracle The oracle that will be used for price updates
   */
  event CreateMarket(string marketCode, address oracle);

  /**
    @notice Creates notification of a new round for a market/update interval pair
    @param oldPrice The average price for the penultimate round
    @param newPrice The average price for the round that's just ended
    @param updateInterval The length of the round
    @param market The market that's being updated
   */
  event NewRound(
    int256 indexed oldPrice,
    int256 indexed newPrice,
    uint32 indexed updateInterval,
    string market
  );
  /**
    @notice Creates a notification of a price sample being taken
    @param cumulativePrice The sum of all samples taken for this round
    @param count The number of samples inclusive
    @param updateInterval The length of the round
    @param market The market that's being updated
   */
  event PriceSample(
    int256 indexed cumulativePrice,
    int256 indexed count,
    uint32 indexed updateInterval,
    string market
  );
  /**
    @notice Creates notification of a price execution for a set of pools
    @param oldPrice The average price for the penultimate round
    @param newPrice The average price for the round that's just ended
    @param updateInterval The length of the round
    @param market The market that's being updated
    @param pools The pools that are being updated
   */
  event ExecutePriceChange(
    int256 indexed oldPrice,
    int256 indexed newPrice,
    uint32 indexed updateInterval,
    string market,
    string[] pools
  );

  // #### Functions
  // /**
  //   @notice Checks for a price update for the pools specified. Several pools can be updated with a single call to the oracle. For instance, a market code of TSLA/USD+aDAI can be used to update TSLA/USD^2+aDAI, TSLA/USD^5+aDAI, and TSLA/USD^10+aDAI
  //   @dev This should remain open. It should only cause a change in the pools if the price has actually changed.
  //   @param marketCode The market to get a quote for. Should be in the format BASE/QUOTE-DIGITAL_ASSET, eg TSLA/USD+aDAI
  //  */
  // function triggerPriceUpdate(
  //   string memory marketCode,
  //   string[] memory poolCodes
  // ) external;

  /**
    @notice Updates the address of the oracle wrapper.
    @dev Should be restricted to authorised users with access controls
    @param oracle The new OracleWrapper to use
    */
  function updateOracleWrapper(address oracle) external;

  /**
    @notice Creates a new market and sets the oracle to use for it.
    @dev This cannot be used to update a market's oracle, and will revert if attempted.
    @param marketCode The market code to identify this market
 */
  function createMarket(string memory marketCode, address oracle) external;

  /**
    @notice Creates a new pool in a given market
    @dev Should throw an error if the market code is invalid/doesn't exist or if the pool code is already in use.
    @param marketCode The market to create the pool in. The current price will be read and used to set the pool's lastPrice field.
    @param poolCode The pool's identifier
    @param updateInterval The minimum amount of time that must elapse before a price update can occur. If the interval is 5 minutes, then the price cannot be updated until 5 minutes after the last update has elapsed.
    @param frontRunningInterval The amount of time that must elapse between a commit and the next update interval before a commit can be executed. Must be shorter than the update interval to prevent deadlock.
    @param fee The percentage fee that will be charged to the pool's capital on a successful price update
    @param leverageAmount The leverage that the pool will expose it's depositors to
    @param feeAddress The address that fees will be sent to on every price change
    @param quoteToken The address of the digital asset that this pool contains
   */
  function createPool(
    string memory marketCode,
    string memory poolCode,
    uint32 updateInterval,
    uint32 frontRunningInterval,
    bytes16 fee,
    uint16 leverageAmount,
    address feeAddress,
    address quoteToken
  ) external;

  /**
  @notice Returns the base contract that new pools are created from
  @dev This is a convenience definition for the autogenerated getter
   */
  function poolBase() external view returns (address);

  /**
  @notice Returns the address for the given pool code
  @dev This is a convenience definition for the autogenerated getter
   */
  function pools(string memory poolCode) external view returns (address);
}
