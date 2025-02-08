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

// contract TestFacet {
//     constructor() {}

//     function addDex(address _dex) external {
//         LibAllowList.addAllowedContract(_dex);
//     }

//     function setFunctionApprovalBySignature(bytes4 _signature) external {
//         LibAllowList.addAllowedSelector(_signature);
//     }
// }

contract ReentrancyChecker {
    address private _facetAddress;
    bytes private _callData;

    constructor(address facetAddress) {
        _facetAddress = facetAddress;
        ERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48).approve(
            _facetAddress,
            type(uint256).max
        ); // approve USDC max to facet
        ERC20(0x6B175474E89094C44Da98b954EedeAC495271d0F).approve(
            _facetAddress,
            type(uint256).max
        ); // approve DAI max to facet
    }

    // must be called with abi.encodePacked(selector, someParam)
    // selector = function selector of the to-be-checked function
    // someParam = valid arguments for the function call
    function callFacet(bytes calldata callData) public {
        _callData = callData;
        (bool success, bytes memory data) = _facetAddress.call{
            value: 10 ether
        }(callData);
        if (!success) {
            if (
                keccak256(data) ==
                keccak256(abi.encodePacked(NativeAssetTransferFailed.selector))
            ) {
                revert ReentrancyError();
            } else {
                revert("Reentrancy Attack Test: initial call failed");
            }
        }
    }

    receive() external payable {
        (bool success, bytes memory data) = _facetAddress.call{
            value: 10 ether
        }(_callData);
        if (!success) {
            if (
                keccak256(data) ==
                keccak256(abi.encodePacked(ReentrancyError.selector))
            ) {
                revert ReentrancyError();
            } else {
                revert("Reentrancy Attack Test: reentrant call failed");
            }
        }
    }
}

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
