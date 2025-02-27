# AcrossFacetV3

## How it works

The AcrossFacetV3 works by forwarding Across specific calls to one of [Across SpokePools](https://github.com/across-protocol/contracts-v2/tree/master/contracts). All bridging is done by calling the `depositV3` method.

```mermaid
graph LR;
    D{LiFiDiamond}-- DELEGATECALL -->AcrossFacet;
    AcrossFacet -- CALL --> C(Across)
```

## Public Methods

- `function startBridgeTokensViaAcrossV3(BridgeData memory _bridgeData, AcrossData calldata _acrossData)`
  - Simply bridges tokens using Across
- `swapAndStartBridgeTokensViaAcrossV3(BridgeData memory _bridgeData, SwapData[] calldata _swapData, AcrossData calldata _acrossData)`
  - Performs swap(s) before bridging tokens using Across

## Across Specific Parameters

The methods listed above take a variable labeled `_acrossData`. This data is specific to Across and is represented as the following struct type:

```solidity
/// @param receiverAddress The address that will receive the token on dst chain (our Receiver contract or the user-defined receiver address)
/// @param refundAddress The address that will be used for potential bridge refunds
/// @param receivingAssetId The address of the token to be received at destination chain
/// @param outputAmount The amount to be received at destination chain (after fees)
/// @param outputAmountPercent The percentage of the output amount with 18 decimal precision (0.7550e18 = 75.50%, 0.99e18 = 99.00%)
/// @param exclusiveRelayer This is the exclusive relayer who can fill the deposit before the exclusivity deadline.
/// @param quoteTimestamp The timestamp of the Across quote that was used for this transaction
/// @param fillDeadline The destination chain timestamp until which the order can be filled
/// @param exclusivityDeadline The timestamp on the destination chain after which any relayer can fill the deposit
/// @param message Arbitrary data that can be used to pass additional information to the recipient along with the tokens
struct AcrossV3Data {
  address receiverAddress;
  address refundAddress;
  address receivingAssetId;
  uint256 outputAmount;
  uint64 outputAmountPercent;
  address exclusiveRelayer;
  uint32 quoteTimestamp;
  uint32 fillDeadline;
  uint32 exclusivityDeadline;
  bytes message;
}
```

The `outputAmountPercent` field allows specifying the desired output amount as a percentage of the input amount, with 18 decimal places of precision. For example:
- 0.8500e18 represents 85.00%
- 0.9375e18 represents 93.75%
- 0.9900e18 represents 99.00%

When using `swapAndStartBridgeTokensViaAcrossV3`, the `outputAmount` will be automatically calculated using the specified percentage.

## Swap Data

Some methods accept a `SwapData _swapData` parameter.

Swapping is performed by a swap specific library that expects an array of calldata to can be run on various DEXs (i.e. Uniswap) to make one or multiple swaps before performing another action.

The swap library can be found [here](../src/Libraries/LibSwap.sol).

## LiFi Data

Some methods accept a `BridgeData _bridgeData` parameter.

This parameter is strictly for analytics purposes. It's used to emit events that we can later track and index in our subgraphs and provide data on how our contracts are being used. `BridgeData` and the events we can emit can be found [here](../src/Interfaces/ILiFi.sol).

## Getting Sample Calls to interact with the Facet

In the following some sample calls are shown that allow you to retrieve a populated transaction that can be sent to our contract via your wallet.

All examples use our [/quote endpoint](https://apidocs.li.fi/reference/get_quote) to retrieve a quote which contains a `transactionRequest`. This request can directly be sent to your wallet to trigger the transaction.

The quote result looks like the following:

```javascript
const quoteResult = {
  id: '0x...', // quote id
  type: 'lifi', // the type of the quote (all lifi contract calls have the type "lifi")
  tool: 'across', // the bridge tool used for the transaction
  action: {}, // information about what is going to happen
  estimate: {}, // information about the estimated outcome of the call
  includedSteps: [], // steps that are executed by the contract as part of this transaction, e.g. a swap step and a cross step
  transactionRequest: {
    // the transaction that can be sent using a wallet
    data: '0x...',
    to: '0x...',
    value: '0x00',
    from: '{YOUR_WALLET_ADDRESS}',
    chainId: 100,
    gasLimit: '0x...',
    gasPrice: '0x...',
  },
}
```

A detailed explanation on how to use the /quote endpoint and how to trigger the transaction can be found [here](https://docs.li.fi/products/more-integration-options/li.fi-api/transferring-tokens-example).

**Hint**: Don't forget to replace `{YOUR_WALLET_ADDRESS}` with your real wallet address in the examples.

### Cross Only

To get a transaction for a transfer from 30 USDC.e on Avalanche to USDC on Binance you can execute the following request:

```shell
curl 'https://li.quest/v1/quote?fromChain=AVA&fromAmount=30000000&fromToken=USDC&toChain=BSC&toToken=USDC&slippage=0.03&allowBridges=across&fromAddress={YOUR_WALLET_ADDRESS}'
```

### Swap & Cross

To get a transaction for a transfer from 30 USDT on Avalanche to USDC on Binance you can execute the following request:

```shell
curl 'https://li.quest/v1/quote?fromChain=AVA&fromAmount=30000000&fromToken=USDT&toChain=BSC&toToken=USDC&slippage=0.03&allowBridges=across&fromAddress={YOUR_WALLET_ADDRESS}'
```
