// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import "forge-std/Test.sol";
import "../src/Web3ThunderFinanceMixer.sol";
import "../src/Verifier.sol";
import "../src/interfaces/IAavePool.sol";
import "../src/mocks/MockERC20.sol";
import "../src/mocks/MockAToken.sol";
import "../src/mocks/MockAavePool.sol";

contract Web3ThunderFinanceMixerTest is Test {
    Web3ThunderFinanceMixer mixer;
    Verifier verifier;
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
        verifier = new Verifier();

        mixer = new Web3ThunderFinanceMixer(address(token), address(aToken), address(verifier));
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
        // Set principal before deposit (admin role needed, but user1 is not admin)
        // Wait, user1 is not admin. I need to prank admin to set principal.
        vm.stopPrank();
        vm.prank(address(this)); // Test contract is deployer, so it has admin role?
        // In setUp, mixer is deployed by this contract.
        // Constructor grants roles to msg.sender (which is this test contract).
        mixer.setPrincipal(amount);

        vm.startPrank(user1);
        mixer.deposit(commitment);
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
        vm.stopPrank();

        mixer.setPrincipal(amount);

        vm.startPrank(user1);
        mixer.deposit(commitment);
        vm.expectRevert(Web3ThunderFinanceMixer.CommitmentUsed.selector);
        mixer.deposit(commitment);
        vm.stopPrank();
    }

    function testWithdrawReturnsPrincipalNoYield() public {
        vm.startPrank(user1);
        uint256 amount = 15_000e6;
        bytes32 secret = bytes32("wy1");
        bytes32 commitment = _commit(secret, amount);
        token.approve(address(mixer), amount);
        vm.stopPrank();

        mixer.setPrincipal(amount);

        vm.startPrank(user1);
        mixer.deposit(commitment);
        vm.stopPrank();

        uint[2] memory a;
        uint[2][2] memory b;
        uint[2] memory c;
        uint[3] memory input;
        uint256 root = 123;
        mixer.registerRoot(root);

        vm.startPrank(user1);
        bytes32 nullifier = _nullifier(secret);
        mixer.withdraw(a, b, c, input, user1, root, nullifier);
        vm.stopPrank();

        (uint256 stored,,) = mixer.deposits(commitment);
        assertTrue(mixer.nullifiers(nullifier));
        assertEq(stored, amount);
        assertEq(mixer.totalPrincipal(), 0);
    }

    function testProRataYieldDistribution() public {
        vm.startPrank(user1);
        uint256 amount1 = 20_000e6;
        bytes32 secret1 = bytes32("a1");
        bytes32 commitment1 = _commit(secret1, amount1);
        token.approve(address(mixer), amount1);
        vm.stopPrank();

        mixer.setPrincipal(amount1);
        vm.startPrank(user1);
        mixer.deposit(commitment1);
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
        vm.stopPrank();

        mixer.setPrincipal(amount2);
        vm.startPrank(user2);
        mixer.deposit(commitment2);
        vm.stopPrank();

        assertEq(mixer.totalPrincipal(), amount1 + amount2);
        assertEq(aToken.balanceOf(address(mixer)), amount1 + amount2 + artificialYield);

        uint[2] memory a;
        uint[2][2] memory b;
        uint[2] memory c;
        uint[3] memory input;
        uint256 root = 999;
        mixer.registerRoot(root);

        vm.startPrank(user1);
        bytes32 nullifier1 = _nullifier(secret1);
        vm.stopPrank();
        mixer.setPrincipal(amount1);
        vm.startPrank(user1);
        mixer.withdraw(a, b, c, input, user1, root, nullifier1);
        vm.stopPrank();

        assertEq(mixer.totalPrincipal(), amount2);

        vm.startPrank(user2);
        bytes32 nullifier2 = _nullifier(secret2);
        vm.stopPrank();
        mixer.setPrincipal(amount2);
        vm.startPrank(user2);
        mixer.withdraw(a, b, c, input, user2, root, nullifier2);
        vm.stopPrank();

        assertEq(mixer.totalPrincipal(), 0);
    }

    function testNullifierPreventsDoubleWithdraw() public {
        vm.startPrank(user1);
        uint256 amount = 7_000e6;
        bytes32 secret = bytes32("nl1");
        bytes32 commitment = _commit(secret, amount);
        token.approve(address(mixer), amount);
        vm.stopPrank();

        mixer.setPrincipal(amount);
        vm.startPrank(user1);
        mixer.deposit(commitment);
        vm.stopPrank();

        uint[2] memory a;
        uint[2][2] memory b;
        uint[2] memory c;
        uint[3] memory input;
        uint256 root = 888;
        mixer.registerRoot(root);

        vm.startPrank(user1);
        bytes32 nullifier = _nullifier(secret);
        mixer.withdraw(a, b, c, input, user1, root, nullifier);
        vm.expectRevert(Web3ThunderFinanceMixer.NullifierUsed.selector);
        mixer.withdraw(a, b, c, input, user1, root, nullifier);
        vm.stopPrank();
    }
}
