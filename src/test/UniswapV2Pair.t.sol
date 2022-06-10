// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

import "../../lib/ds-test/test.sol";
import "../../lib/utils/Console.sol";
import "../../lib/utils/VyperDeployer.sol";
import "../IUniswapV2Pair.sol";
import "./Console.sol";

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
        uint expectedLiquidity = 2000000000000000999; // should be 2e18

        addLiquidity(wethAmount, daiAmount);

        (uint wethReserves, uint daiReserves,) = pair.getReserves();
        require(pair.totalSupply() == expectedLiquidity, Console.log("make sure pair supply is equal to expected liquidity", pair.totalSupply()));
        require(pair.balanceOf(address(this)) == expectedLiquidity - 10**3, Console.log("make sure pair balance of this contract is equal to expected liquidity minus MIN_LIQ", pair.balanceOf(address(this))));
        require(WETH.balanceOf(address(pair)) == wethAmount, "make sure base token balance of pair is equal to base amount");
        require(DAI.balanceOf(address(pair)) == daiAmount, "make sure quote token balance of pair is equal to quote amount");
        require(wethReserves == wethAmount, "make sure base reserves equal base amount");
        require(daiReserves == daiAmount, "make sure quote reserves equal quote amount");
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
        require(wethReserves == wethAmount + swapAmount, "make sure base reserves equal base amount + swap amount");
        require(daiReserves == daiAmount - expectedOutputAmount, "make sure quote reserves equal quote amount - expected output");
        require(WETH.balanceOf(address(pair)) == wethAmount + swapAmount, "make sure base token balance of this contract equals base amount + swap amount");
        require(DAI.balanceOf(address(pair)) == daiAmount - expectedOutputAmount, "make sure quote token balance of this contract equals quote amount - expected output");
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

        // require(pair.balanceOf(address(this)) == 0);
        // require(pair.totalSupply() == 1000);
        // require(WETH.balanceOf(address(pair)) == 1000);
        // require(DAI.balanceOf(address(pair)) == 1000);
        // uint totalSupplyToken0 = WETH.totalSupply();
        // uint totalSupplyToken1 = DAI.totalSupply();
        // require(WETH.balanceOf(address(this)) == totalSupplyToken0 - 1000);
        // require(DAI.balanceOf(address(this)) == totalSupplyToken1 - 1000);
    }
}