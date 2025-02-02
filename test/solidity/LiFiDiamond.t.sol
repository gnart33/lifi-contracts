// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.17;

import {LiFiDiamond} from "lifi/LiFiDiamond.sol";
import {LibDiamond} from "lifi/Libraries/LibDiamond.sol";
import {DiamondCutFacet} from "lifi/Facets/DiamondCutFacet.sol";
import {DiamondLoupeFacet} from "lifi/Facets/DiamondLoupeFacet.sol";
import {OwnershipFacet} from "lifi/Facets/OwnershipFacet.sol";
import {IDiamondCut} from "lifi/Interfaces/IDiamondCut.sol";
import {DSTest} from "ds-test/test.sol";
import {Vm} from "forge-std/Vm.sol";
import {console2} from "forge-std/console2.sol";

contract LiFiDiamondTest is DSTest {
    Vm internal immutable vm = Vm(HEVM_ADDRESS);
    // LiFiDiamond
    LiFiDiamond public diamond;
    DiamondCutFacet public diamondCutFacet;
    OwnershipFacet public ownershipFacet;

    address public diamondOwner;

    event DiamondCut(
        LibDiamond.FacetCut[] _diamondCut,
        address _init,
        bytes _calldata
    );

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    error FunctionDoesNotExist();
    error ShouldNotReachThisCode();

    function setUp() public {
        // Set the diamond owner to a specific address for testing
        diamondOwner = address(123456);

        // Deploy the core facets needed for diamond functionality
        diamondCutFacet = new DiamondCutFacet(); // Handles adding/replacing/removing facets
        ownershipFacet = new OwnershipFacet(); // Handles ownership management

        // Step 1: Create an array of function selectors to be added to the diamond
        // In this case, we're only adding the 'owner()' function from OwnershipFacet
        bytes4[] memory functionSelectors = new bytes4[](1);
        functionSelectors[0] = ownershipFacet.owner.selector;

        // Log the function selector for debugging purposes
        // console2.log("function selector");
        // console2.logBytes4(functionSelectors[0]);

        // Step 2: Create a FacetCut array that specifies how to modify the diamond
        // This structure defines which functions from which facets should be added/removed
        LibDiamond.FacetCut[] memory cut = new LibDiamond.FacetCut[](1);

        // Configure the facet cut:
        // - facetAddress: the contract address of the facet (OwnershipFacet)
        // - action: Add = adding new functions to the diamond
        // - functionSelectors: array of function selectors to be added
        cut[0] = LibDiamond.FacetCut({
            facetAddress: address(ownershipFacet),
            action: LibDiamond.FacetCutAction.Add,
            functionSelectors: functionSelectors
        });

        // Log facet details for debugging
        // console2.log("facetAddress", cut[0].facetAddress);
        // console2.log("action", uint256(cut[0].action));

        // Finally, deploy the main Diamond contract with:
        // - diamondOwner: the address that will own the diamond
        // - diamondCutFacet: the address of the facet that handles diamond modifications
        diamond = new LiFiDiamond(diamondOwner, address(diamondCutFacet));
    }

    function test_DeploysWithoutErrors() public {
        diamond = new LiFiDiamond(diamondOwner, address(diamondCutFacet));
        console2.log("diamond", address(diamond));
    }

    function test_ForwardsCallsViaDelegateCall() public {
        // only one facet with one selector is registered (diamondCut)
        vm.startPrank(diamondOwner);

        DiamondLoupeFacet diamondLoupe = new DiamondLoupeFacet();

        // make sure that this call fails (without ending the test)
        bool failed = false;
        try DiamondLoupeFacet(address(diamond)).facetAddresses() returns (
            address[] memory
        ) {} catch {
            failed = true;
        }
        if (!failed) revert("InvalidDiamondSetup");

        // prepare function selectors
        bytes4[] memory functionSelectors = new bytes4[](4);
        functionSelectors[0] = diamondLoupe.facets.selector;
        functionSelectors[1] = diamondLoupe.facetFunctionSelectors.selector;
        functionSelectors[2] = diamondLoupe.facetAddresses.selector;
        functionSelectors[3] = diamondLoupe.facetAddress.selector;

        // prepare diamondCut
        LibDiamond.FacetCut[] memory cuts = new LibDiamond.FacetCut[](1);
        cuts[0] = LibDiamond.FacetCut({
            facetAddress: address(diamondLoupe),
            action: LibDiamond.FacetCutAction.Add,
            functionSelectors: functionSelectors
        });

        DiamondCutFacet(address(diamond)).diamondCut(cuts, address(0), "");
    }

    function test_RevertsOnUnknownFunctionSelector() public {
        // call random function selectors
        bytes memory callData = hex"a516f0f3"; // getPeripheryContract(string)

        vm.expectRevert(FunctionDoesNotExist.selector);
        (bool success, ) = address(diamond).call(callData);
        if (!success) revert("ShouldNotReachThisCode"); // was only added to silence a compiler warning
    }

    function test_CanReceiveETH() public {
        (bool success, ) = address(diamond).call{value: 1 ether}("");
        if (!success) revert("ExternalCallFailed");

        assertEq(address(diamond).balance, 1 ether);
    }
}
