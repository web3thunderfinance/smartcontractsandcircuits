// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "forge-std/Test.sol";
import "../src/Web3ThunderFinanceMixer.sol";
import "../src/interfaces/IAavePool.sol";
import "../src/mocks/MockERC20.sol";
import "../src/mocks/MockAToken.sol";
import "../src/mocks/MockAavePool.sol";

contract Web3ThunderFinanceMixerTest is Test {
    Web3ThunderFinanceMixer mixer;
    MockERC20 token; // underlying
    MockAToken aToken; // interest-bearing token
    MockAavePool pool; // mock pool

    address user1 = address(0x111);
    address user2 = address(0x222);

    uint256 constant INIT = 1_000_000e6; // assuming 6 decimals underlying

    function setUp() public {
        token = new MockERC20("Mock USD", "mUSD", 6);
        aToken = new MockAToken("Mock aUSD", "amUSD");
        pool = new MockAavePool(address(token), address(aToken));
        aToken.setPool(address(pool));

        mixer = new Web3ThunderFinanceMixer(address(token), address(aToken));
        mixer.setPool(address(pool));

        token.mint(user1, INIT);
        token.mint(user2, INIT);
    }

    function _commit(bytes32 secret, uint256 amount) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(secret, amount));
    }

    function _nullifier(bytes32 secret) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(secret));
    }

    function testDepositStoresPrincipal() public {
        vm.startPrank(user1);
        uint256 amount = 10_000e6;
        bytes32 secret = bytes32("s1");
        bytes32 commitment = _commit(secret, amount);

        token.approve(address(mixer), amount);
        mixer.deposit(commitment, amount);
        vm.stopPrank();

        (uint256 stored,,bool withdrawn) = mixer.deposits(commitment);
        assertEq(stored, amount);
        assertFalse(withdrawn);
        assertEq(mixer.totalPrincipal(), amount);
    }

    function testCannotReuseCommitment() public {
        vm.startPrank(user1);
        uint256 amount = 5_000e6;
        bytes32 secret = bytes32("dup");
        bytes32 commitment = _commit(secret, amount);
        token.approve(address(mixer), amount);
        mixer.deposit(commitment, amount);
        vm.expectRevert(Web3ThunderFinanceMixer.CommitmentUsed.selector);
        mixer.deposit(commitment, amount);
        vm.stopPrank();
    }

    function testWithdrawReturnsPrincipalNoYield() public {
        vm.startPrank(user1);
        uint256 amount = 15_000e6;
        bytes32 secret = bytes32("wy1");
        bytes32 commitment = _commit(secret, amount);
        token.approve(address(mixer), amount);
        mixer.deposit(commitment, amount);
        vm.stopPrank();

        vm.startPrank(user1);
        bytes32 nullifier = _nullifier(secret);
        mixer.withdraw(commitment, nullifier, user1);
        vm.stopPrank();

        (uint256 stored,,bool withdrawn) = mixer.deposits(commitment);
        assertTrue(withdrawn);
        assertEq(stored, amount);
        assertEq(mixer.totalPrincipal(), 0);
    }

    function testProRataYieldDistribution() public {
        vm.startPrank(user1);
        uint256 amount1 = 20_000e6;
        bytes32 secret1 = bytes32("a1");
        bytes32 commitment1 = _commit(secret1, amount1);
        token.approve(address(mixer), amount1);
        mixer.deposit(commitment1, amount1);
        vm.stopPrank();

        uint256 artificialYield = 5_000e6;
        vm.prank(address(pool));
        aToken.mint(address(mixer), artificialYield);
        // Simulate underlying accrual in pool reserves matching the artificial aToken yield
        token.mint(address(pool), artificialYield);

        vm.startPrank(user2);
        uint256 amount2 = 10_000e6;
        bytes32 secret2 = bytes32("b2");
        bytes32 commitment2 = _commit(secret2, amount2);
        token.approve(address(mixer), amount2);
        mixer.deposit(commitment2, amount2);
        vm.stopPrank();

        assertEq(mixer.totalPrincipal(), amount1 + amount2);
        assertEq(aToken.balanceOf(address(mixer)), amount1 + amount2 + artificialYield);

        vm.startPrank(user1);
        bytes32 nullifier1 = _nullifier(secret1);
        mixer.withdraw(commitment1, nullifier1, user1);
        vm.stopPrank();

        assertEq(mixer.totalPrincipal(), amount2);

        vm.startPrank(user2);
        bytes32 nullifier2 = _nullifier(secret2);
        mixer.withdraw(commitment2, nullifier2, user2);
        vm.stopPrank();

        assertEq(mixer.totalPrincipal(), 0);
    }

    function testNullifierPreventsDoubleWithdraw() public {
        vm.startPrank(user1);
        uint256 amount = 7_000e6;
        bytes32 secret = bytes32("nl1");
        bytes32 commitment = _commit(secret, amount);
        token.approve(address(mixer), amount);
        mixer.deposit(commitment, amount);
        vm.stopPrank();

        vm.startPrank(user1);
        bytes32 nullifier = _nullifier(secret);
        mixer.withdraw(commitment, nullifier, user1);
        vm.expectRevert(Web3ThunderFinanceMixer.NullifierUsed.selector);
        mixer.withdraw(commitment, nullifier, user1);
        vm.stopPrank();
    }
}
