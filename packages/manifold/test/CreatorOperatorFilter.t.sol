// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../contracts/operatorfilterer/CreatorOperatorFilterer.sol";
import "@manifoldxyz/creator-core-solidity/contracts/ERC1155Creator.sol";
import "@manifoldxyz/creator-core-solidity/contracts/ERC721Creator.sol";

import "../contracts/mocks/Mock.sol";

contract OperatorFilterTest is Test {

    CreatorOperatorFilterer public example;
    ERC1155Creator public creatorCore1155;
    ERC721Creator public creatorCore721;

    MockRegistry public registry;

    address public owner = 0x6140F00e4Ff3936702E68744f2b5978885464cbB;
    address public operator = 0xc78Dc443c126af6E4f6Ed540c1e740C1b5be09cd;
    address public operator2 = 0x80AAC46bbd3C2FcE33681541a52CacBEd14bF425;
    address public operator3 = 0x5174cD462b60c536eb51D4ceC1D561D3Ea31004F;

    address public zeroAddress = address(0);
    address public deadAddress = 0x000000000000000000000000000000000000dEaD;

    function setUp() public {
        vm.startPrank(owner);
        creatorCore1155 = new ERC1155Creator("Token", "NFT");
        creatorCore721 = new ERC721Creator("Token", "NFT");

        registry = new MockRegistry();
        example = new CreatorOperatorFilterer();

        creatorCore721.setApproveTransfer(address(example));
        creatorCore1155.setApproveTransfer(address(example));

        vm.deal(owner, 10 ether);
        vm.deal(operator, 10 ether);
        vm.deal(operator2, 10 ether);
        vm.deal(operator3, 10 ether);
        vm.stopPrank();
    }

    function testAccess() public {
      vm.startPrank(operator);

      vm.expectRevert("Wallet is not an admin");
      example.configureBlockedOperators(
        address(creatorCore721),
        new address[](0),
        new bool[](0)
      );

      vm.expectRevert("Wallet is not an admin");
      example.configureBlockedOperatorHashes(
        address(creatorCore721),
        new bytes32[](0),
        new bool[](0)
      );

      vm.expectRevert("Wallet is not an admin");
      example.configureBlockedOperatorsAndHashes(
        address(creatorCore721),
        new address[](0),
        new bool[](0),
        new bytes32[](0),
        new bool[](0)
      );

      vm.stopPrank();
    }

    function testAllowOperatorsNotOnList721() public {
      vm.startPrank(owner);
      creatorCore721.mintBase(owner);
      creatorCore721.setApprovalForAll(operator, true);
      vm.stopPrank();
      vm.startPrank(operator);
      creatorCore721.safeTransferFrom(owner, operator2, 1);
      vm.stopPrank();
    }

    function testAllowOperatorThatOwnsToken721() public {
      vm.startPrank(owner);
      creatorCore721.mintBase(operator);
      vm.stopPrank();
      vm.startPrank(operator);
      creatorCore721.safeTransferFrom(operator, operator2, 1);
      vm.stopPrank();
    }

    function testShouldBlockFilteredOperators721() public {
      vm.startPrank(owner);

      creatorCore721.mintBase(owner);
      creatorCore721.setApprovalForAll(operator, true);

      address[] memory blockedOperators = new address[](1);
      blockedOperators[0] = operator;
      bool[] memory blockedOperatorsValues = new bool[](1);
      blockedOperatorsValues[0] = true;

      example.configureBlockedOperators(
        address(creatorCore721),
        blockedOperators,
        blockedOperatorsValues
      );

      vm.stopPrank();
      vm.startPrank(operator);
      vm.expectRevert();
      creatorCore721.safeTransferFrom(owner, operator2, 1);
      vm.expectRevert();
      creatorCore721.transferFrom(owner, operator2, 1);
      vm.stopPrank();
      vm.startPrank(owner);
      creatorCore721.safeTransferFrom(owner, operator2, 1);

      vm.stopPrank();
    }

    function testAllowOperatorsNotOnList1155() public {
      vm.startPrank(owner);
      address[] memory recipients = new address[](1);
      recipients[0] = owner;
      uint[] memory amounts = new uint[](1);
      amounts[0] = 1;
      string[] memory uris = new string[](1);
      uris[0] = "";

      creatorCore1155.mintBaseNew(recipients, amounts, uris);
      creatorCore1155.setApprovalForAll(operator, true);
      vm.stopPrank();
      vm.startPrank(operator);
      creatorCore1155.safeTransferFrom(owner, operator2, 1, 1, "0x0");
      vm.stopPrank();
    }

    function testAllowOperatorOwnsToken1155() public {
      vm.startPrank(owner);
      address[] memory recipients = new address[](1);
      recipients[0] = operator;
      uint[] memory amounts = new uint[](1);
      amounts[0] = 1;
      string[] memory uris = new string[](1);
      uris[0] = "";

      creatorCore1155.mintBaseNew(recipients, amounts, uris);
      vm.stopPrank();
      vm.startPrank(operator);
      creatorCore1155.safeTransferFrom(operator, operator2, 1, 1, "0x0");
      vm.stopPrank();
    }

    function testBlockFilteredOperators() public {
      vm.startPrank(owner);
      address[] memory recipients = new address[](1);
      recipients[0] = owner;
      uint[] memory amounts = new uint[](1);
      amounts[0] = 1;
      string[] memory uris = new string[](1);
      uris[0] = "";

      creatorCore1155.mintBaseNew(recipients, amounts, uris);
      creatorCore1155.setApprovalForAll(operator, true);
      address[] memory blockedOperators = new address[](1);
      blockedOperators[0] = operator;
      bool[] memory blockedOperatorsValues = new bool[](1);
      blockedOperatorsValues[0] = true;

      example.configureBlockedOperators(
        address(creatorCore1155),
        blockedOperators,
        blockedOperatorsValues
      );
      vm.stopPrank();
      vm.startPrank(operator);
      vm.expectRevert();
      creatorCore1155.safeTransferFrom(owner, operator2, 1, 1, "0x0");
      vm.stopPrank();
      vm.startPrank(owner);
      creatorCore1155.safeTransferFrom(owner, operator2, 1, 1, "0x0");
      vm.stopPrank();
    }
}