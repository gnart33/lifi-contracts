// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

import { Test } from "forge-std/Test.sol";
import { DSTest } from "ds-test/test.sol";
import { Vm } from "forge-std/Vm.sol";
import { ILiFi } from "lifi/Interfaces/ILiFi.sol";
import { DiamondTest, LiFiDiamond } from "../utils/DiamondTest.sol";
import { ERC20 } from "solmate/tokens/ERC20.sol";
// import { LibAllowList } from "lifi/Libraries/LibAllowList.sol";
import { LibAccess } from "lifi/Libraries/LibAccess.sol";

import { console } from "test/solidity/utils/Console.sol";
import { NoSwapDataProvided, InformationMismatch, NativeAssetTransferFailed, ReentrancyError, InsufficientBalance, CannotBridgeToSameNetwork, InvalidReceiver, InvalidAmount, InvalidConfig, InvalidSendingToken, AlreadyInitialized, NotInitialized, UnAuthorized } from "src/Errors/GenericErrors.sol";

//common utilities for forge tests
abstract contract TestBase is Test, DiamondTest, ILiFi {
    LiFiDiamond internal diamond;

    uint256 internal defaultDAIAmount;
    uint256 internal defaultUSDCAmount;
    uint256 internal defaultNativeAmount;

    string internal logFilePath;

    address internal constant USER_SENDER = address(0xabc123456); // initially funded with 100,000 DAI, USDC, USDT, WETH & ETHER

    address internal constant USER_PAUSER = address(0xdeadbeef);

    address internal constant USER_DIAMOND_OWNER =
        0x5042255A3F3FD7727e419CeA387cAFDfad3C3aF8;

    function initTestBase() internal {
        diamond = createDiamond(USER_DIAMOND_OWNER, USER_PAUSER);
    }
}
