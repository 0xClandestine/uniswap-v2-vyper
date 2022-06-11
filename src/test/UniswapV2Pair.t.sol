// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

import "../../lib/ds-test/test.sol";
import "../../lib/utils/Console.sol";
import "../../lib/utils/VyperDeployer.sol";
import "../IUniswapV2Pair.sol";
import "./Console.sol";
import "./VM.sol";

import "../../node_modules/@rari-capital/solmate/src/tokens/ERC20.sol";

contract MockERC20 is ERC20 {

    constructor(
        string memory _name,
        string memory _symbol
    ) ERC20(_name, _symbol, 18) {}

    function mint(address guy, uint256 wad) external {
        _mint(guy, wad);
    }
}

contract UniswapV2PairTest is DSTest {
    ///@notice create a new instance of VyperDeployer
    VyperDeployer vyperDeployer = new VyperDeployer();

    VM vm = VM(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);

    IUniswapV2Pair pair;
    MockERC20 WETH;
    MockERC20 DAI;

    function setUp() public {
        WETH = new MockERC20("WETH token", "WETH");
        DAI = new MockERC20("DAI token", "DAI");
        pair = IUniswapV2Pair(vyperDeployer.deployContract("UniswapV2Pair"));
        pair.initialize(address(WETH), address(DAI));
        WETH.mint(address(this), 1e27);
        DAI.mint(address(this), 1e27);
    }

    function test_sanityCheck() public {
        require(pair.factory() == address(this));
        require(pair.token0() == address(WETH));
        require(pair.token1() == address(DAI));
        require(pair.totalSupply() == 0);
    }

    function addLiquidity(uint wethAmount, uint daiAmount) internal {
        WETH.transfer(address(pair), wethAmount);
        DAI.transfer(address(pair), daiAmount);
        pair.mint(address(this));
    }

    function testMint() public {
        uint wethAmount = 1e18;
        uint daiAmount = 4e18;
        uint expectedLiquidity = 2000000000000000000; // should be 2e18

        addLiquidity(wethAmount, daiAmount);

        (uint wethReserves, uint daiReserves,) = pair.getReserves();
        require(pair.totalSupply() == expectedLiquidity, Console.log("make sure pair supply is equal to expected liquidity", pair.totalSupply()));
        require(pair.balanceOf(address(this)) == expectedLiquidity - 1000, Console.log("make sure pair balance of this contract is equal to expected liquidity minus MIN_LIQ", pair.balanceOf(address(this))));
        require(WETH.balanceOf(address(pair)) == wethAmount, "make sure ETH token balance of pair is equal to ETH amount");
        require(DAI.balanceOf(address(pair)) == daiAmount, "make sure DAI token balance of pair is equal to DAI amount");
        require(wethReserves == wethAmount, "make sure ETH reserves equal ETH amount");
        require(daiReserves == daiAmount, "make sure DAI reserves equal DAI amount");
    }

    function testSwapWETH() public {
        uint wethAmount = 5e18;
        uint daiAmount = 10e18;
        uint swapAmount = 1e18;
        uint expectedOutputAmount = 1662497915624478906;

        addLiquidity(wethAmount, daiAmount);

        WETH.transfer(address(pair), swapAmount);
        
        pair.swap(0, expectedOutputAmount, address(this), "");

        (uint wethReserves, uint daiReserves,) = pair.getReserves();
        require(wethReserves == wethAmount + swapAmount, "make sure ETH reserves equal ETH amount + swap amount");
        require(daiReserves == daiAmount - expectedOutputAmount, "make sure DAI reserves equal DAI amount - expected output");
        require(WETH.balanceOf(address(pair)) == wethAmount + swapAmount, "make sure ETH token balance of this contract equals ETH amount + swap amount");
        require(DAI.balanceOf(address(pair)) == daiAmount - expectedOutputAmount, "make sure DAI token balance of this contract equals DAI amount - expected output");
        // // expect(await token0.balanceOf(wallet.address)).to.eq(totalSupplyToken0.sub(token0Amount).sub(swapAmount))
        // // expect(await token1.balanceOf(wallet.address)).to.eq(totalSupplyToken1.sub(token1Amount).add(expectedOutputAmount))
    }

    function testSwapDAI() public {
        uint wethAmount = 5e18;
        uint daiAmount = 10e18;
        uint swapAmount = 1e18;
        uint expectedOutputAmount = 453305446940074565;

        addLiquidity(wethAmount, daiAmount);

        DAI.transfer(address(pair), swapAmount);

        pair.swap(expectedOutputAmount, 0, address(this), "");

        (uint wethReserves, uint daiReserves,) = pair.getReserves();
        require(wethReserves == wethAmount - expectedOutputAmount);
        require(daiReserves == daiAmount + swapAmount);
        require(WETH.balanceOf(address(pair)) == wethAmount - expectedOutputAmount);
        require(DAI.balanceOf(address(pair)) == daiAmount + swapAmount);
        // expect(await token0.balanceOf(wallet.address)).to.eq(totalSupplyToken0.sub(token0Amount).add(expectedOutputAmount))
        // expect(await token1.balanceOf(wallet.address)).to.eq(totalSupplyToken1.sub(token1Amount).sub(swapAmount))
    }

    function testBurn() public {

        uint wethAmount = 3e18;
        uint daiAmount = 3e18;
        uint expectedLiquidity = 3e18;

        addLiquidity(wethAmount, daiAmount);

        pair.transfer(address(pair), expectedLiquidity - 1000);

        pair.burn(address(this));

        require(pair.balanceOf(address(this)) == 0, Console.log("", pair.balanceOf(address(this))));
        require(pair.totalSupply() == 1000);
        require(WETH.balanceOf(address(pair)) == 1000);
        require(DAI.balanceOf(address(pair)) == 1000);
        uint totalSupplyToken0 = WETH.totalSupply();
        uint totalSupplyToken1 = DAI.totalSupply();
        require(WETH.balanceOf(address(this)) == totalSupplyToken0 - 1000);
        require(DAI.balanceOf(address(this)) == totalSupplyToken1 - 1000);
    }

    function testPriceCumulativeLast() public {
        uint256 wethAmount = 3e18;
        uint256 daiAmount = 3e18;
        uint256 elapsed = 1;

        addLiquidity(wethAmount, daiAmount);

        vm.warp(block.timestamp + elapsed);
        pair.sync();

        uint256 initialPriceETH = (daiAmount * 2**112 / wethAmount) * elapsed; 
        uint256 initialPriceDAI = (wethAmount * 2**112 / daiAmount) * elapsed;

        (,, uint32 lastUpdate) = pair.getReserves();
        require(pair.price0CumulativeLast() == initialPriceETH, Console.log("make sure ETH cl is equal to initial ETH price", pair.price0CumulativeLast()));
        require(pair.price1CumulativeLast() == initialPriceDAI, Console.log("make sure ETH cl is equal to initial DAI price", pair.price1CumulativeLast()));
        require(lastUpdate == block.timestamp, "make sure last update is equal to current timestamp");
    }
}