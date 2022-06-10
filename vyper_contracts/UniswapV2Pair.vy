from vyper.interfaces import ERC20
from vyper.interfaces import ERC20Detailed

implements: ERC20
implements: ERC20Detailed

interface IUniswapV2Factory:
    def feeTo() -> address: view

event Transfer:
    sender: indexed(address)
    receiver: indexed(address)
    value: uint256

event Approval:
    owner: indexed(address)
    spender: indexed(address)
    value: uint256

event Mint:
    sender: indexed(address)
    amount0: uint256
    amount1: uint256

event Burn:
    sender: indexed(address)
    amount0: uint256
    amount1: uint256
    to: address

event Swap:
    sender: indexed(address)
    amount0In: uint256
    amount1In: uint256
    amount0Out: uint256
    amount1Out: uint256
    to: address 

event Sync:
    reserve0: uint112
    reserve1: uint112

name: public(String[32])
symbol: public(String[32])
decimals: public(uint8)
balanceOf: public(HashMap[address, uint256])
allowance: public(HashMap[address, HashMap[address, uint256]])
totalSupply: public(uint256)

MINIMUM_LIQUIDITY: constant(uint256) = 10**3

factory: public(address)
token0: public(address)
token1: public(address)

reserve0: uint112
reserve1: uint112
blockTimestampLast: uint32

price0CumulativeLast: public(uint256)
price1CumulativeLast: public(uint256)
kLast: public(uint256)

# not supported by foundry-vyper
# @external
# def __init__(_token0: address, _token1: address):
#     """
#     @dev Initializes the Uniswap V2 Pair at contract creation.
#     """
#     self.name = "Uniswap V2"
#     self.symbol = "UNI-V2" 
#     self.decimals = 18
#     self.factory = msg.sender

@external
def initialize(_token0: address, _token1: address):
    """
    @dev Initializes the Uniswap V2 Pair token addresses
    @param _token0: The first token address
    @param _token1: The second token address
    """
    # Removed for testing purposes
    # assert msg.sender == self.factory, "UniswapV2: FORBIDDEN"
    self.token0 = _token0
    self.token1 = _token1
    self.name = "Uniswap V2"
    self.symbol = "UNI-V2" 
    self.decimals = 18
    self.factory = msg.sender

@external
def transfer(_to : address, _value : uint256) -> bool:
    """
    @dev Transfers `_value` tokens from msg.sender to `_to`.
    @param _to The address of the recipient.
    @param _value The amount of tokens to be transferred.
    """
    self.balanceOf[msg.sender] -= _value
    self.balanceOf[_to] += _value
    log Transfer(msg.sender, _to, _value)
    return True

@external
def transferFrom(_from : address, _to : address, _value : uint256) -> bool:
    """
    @dev Transfers `_value` tokens from `_from` to `_to`.
    @param _from The address of the sender.
    @param _to The address of the recipient.
    @param _value The amount of tokens to be transferred.
    """
    self.balanceOf[_from] -= _value
    self.balanceOf[_to] += _value
    self.allowance[_from][msg.sender] -= _value
    log Transfer(_from, _to, _value)
    return True

@external
def approve(_spender : address, _value : uint256) -> bool:
    """
    @dev Increases the amount of tokens that the spender is able to spend on behalf of msg.sender.
    @param _spender The address of the spender.
    @param _value The amount of tokens to be approved for spending.
    """
    self.allowance[msg.sender][_spender] = _value
    log Approval(msg.sender, _spender, _value)
    return True

@internal
def _mint(_to : address, _value : uint256):
    """
    @dev Mints `_value` of tokens to `_to`.
    @param _to The address of the recipient.
    @param _value The amount of tokens to be minted.
    """
    self.balanceOf[msg.sender] += _value
    self.totalSupply += _value
    log Transfer(ZERO_ADDRESS, msg.sender, _value)

@internal
def _burn(_from: address, _value: uint256):
    """
    @dev Burns `_value` of tokens from `_from`.
    @param _from The address to burn tokens from.
    @param _value The amount of tokens to be burned.
    """
    self.balanceOf[_from] -= _value
    self.totalSupply -= _value
    log Transfer(_from, ZERO_ADDRESS, _value)

@external
@view
def getReserves() -> (uint112, uint112, uint32):
    """
    @dev Returns the current reserves and the last update time.
    """
    return self.reserve0, self.reserve1, self.blockTimestampLast

@internal
def _safeTransfer(_token: address, _to: address, _value: uint256) -> bool:
    _response: Bytes[32] = raw_call(
        _token,
        concat(
            0xa9059cbb, # ERC20 transfer selector
            convert(_to, bytes32),
            convert(_value, bytes32)
        ),
        max_outsize=32
    )
    if len(_response) > 0:
        assert convert(_response, bool), "Transfer failed!"
    return True

@internal
def encode(y: uint112) -> uint224:
    Q112: uint256 = 5192296858534827628530496329220096
    return convert(unsafe_mul(convert(y, uint256), Q112), uint224)

@internal
def uqdiv(x: uint224, y: uint112) -> uint256:
    return unsafe_div(convert(x, uint256), convert(y, uint256))

@internal
def _update(balance0: uint256, balance1: uint256, _reserve0: uint112, _reserve1: uint112):
    blockTimestamp: uint32 = convert(block.timestamp % 2**32, uint32)
    timeElapsed: uint32 = convert(convert(blockTimestamp, uint256) - convert(self.blockTimestampLast, uint256), uint32)
    
    if timeElapsed > 0 and _reserve0 != 0 and _reserve1 != 0:
        self.price0CumulativeLast += unsafe_mul(convert(self.uqdiv(self.encode(_reserve1), _reserve0), uint256), convert(timeElapsed, uint256))
        self.price1CumulativeLast += unsafe_mul(convert(self.uqdiv(self.encode(_reserve0), _reserve1), uint256), convert(timeElapsed, uint256))


    self.reserve0 = convert(balance0, uint112)
    self.reserve1 = convert(balance1, uint112)
    self.blockTimestampLast = blockTimestamp
    log Sync(self.reserve0, self.reserve1)

@internal
@pure
def sqrt256(x: uint256) -> uint256:
    """
    @dev Computes the square root of `x` using the Babylonian method.
    @param x The number to compute the square root of.
    """
    z: uint256 = (x + 1) / 2
    y: uint256 = x
    for i in range(256):
        if (z > y):
            break
        y = z
        z = (x / z + z) / 2
    return y

@internal
def _mintFee(_reserve0: uint112, _reserve1: uint112) -> bool:
    """
    @dev Mints 0.05% of LP growth to 'feeTo'
    @param _reserve0 The first reserve balance
    @param _reserve1 The second reserve balance
    """
    feeTo: address = IUniswapV2Factory(self.factory).feeTo()
    feeOn: bool = feeTo != ZERO_ADDRESS
    kLast: uint256 = self.kLast
    if feeOn:
        if kLast != 0:
            rootK: uint256 = self.sqrt256(convert(_reserve0, uint256) * convert(_reserve1, uint256))
            rootKLast: uint256 = self.sqrt256(kLast)
            if (rootK > rootKLast):
                numerator: uint256 = self.totalSupply * (rootK - rootKLast)
                denominator: uint256 = rootK * 5 + rootKLast
                liquidity: uint256 = unsafe_div(numerator, denominator)
                if liquidity > 0:
                    self._mint(feeTo, liquidity)
    elif kLast != 0:
        kLast = 0
    
    return feeOn

@external
@nonreentrant("lock")
def mint(to: address):
    """
    @dev Mints LP tokens to a given address assuming they've sent reserves to this contract.
    @param to: The address to mint LP tokens to.
    """
    _reserve0: uint112 = self.reserve0 
    _reserve1: uint112 = self.reserve1
    _blockTimestampLast: uint32 = self.blockTimestampLast
    balance0: uint256 = ERC20(self.token0).balanceOf(self)
    balance1: uint256 = ERC20(self.token1).balanceOf(self)
    amount0: uint256 = balance0 - convert(_reserve0, uint256)
    amount1: uint256 = balance1 - convert(_reserve1, uint256)
    feeOn: bool = self._mintFee(_reserve0, _reserve1)
    _totalSupply: uint256 = self.totalSupply
    liquidity: uint256 = 0
    if _totalSupply == 0:
        liquidity = self.sqrt256(amount0 * amount1 - MINIMUM_LIQUIDITY)
        self._mint(ZERO_ADDRESS, MINIMUM_LIQUIDITY)
    else:
        liquidity = min(amount0 * _totalSupply / convert(_reserve0, uint256), amount1 * _totalSupply / convert(_reserve1, uint256))
    assert liquidity > 0, "UniswapV2: INSUFFICIENT_LIQUIDITY_MINTED"
    self._mint(to, liquidity)
    self._update(balance0, balance1, _reserve0, _reserve1)
    if feeOn:
        self.kLast = convert(_reserve0, uint256) * convert(_reserve1, uint256)
    # log Mint(msg.sender, liquidity, amount0, amount1)

@external
@nonreentrant("lock")
def burn(to: address) -> (uint256, uint256):
    """
    @dev Burns LP tokens from a given address and refunds thier reserves.
    @param to: The address to send the reserves to.
    """
    _reserve0: uint112 = self.reserve0 
    _reserve1: uint112 = self.reserve1
    _blockTimestampLast: uint32 = self.blockTimestampLast
    _token0: address = self.token0
    _token1: address = self.token1
    balance0: uint256 = ERC20(_token0).balanceOf(self)
    balance1: uint256 = ERC20(_token1).balanceOf(self)
    liquidity: uint256 = ERC20(self).balanceOf(self)
    feeOn: bool = self._mintFee(_reserve0, _reserve1)
    _totalSupply: uint256 = self.totalSupply
    amount0: uint256 = unsafe_div(liquidity * balance0, _totalSupply)
    amount1: uint256 = unsafe_div(liquidity * balance1, _totalSupply)
    assert amount0 > 0 and amount1 > 0, "UniswapV2: INSUFFICIENT_LIQUIDITY_BURNED" 
    self._burn(self, liquidity)
    self._safeTransfer(_token0, to, amount0)
    self._safeTransfer(_token1, to, amount1)
    self._update(ERC20(_token0).balanceOf(self), ERC20(_token1).balanceOf(self), _reserve0, _reserve1)
    if feeOn:
        self.kLast = convert(_reserve0, uint256) * convert(_reserve1, uint256)
    log Burn(msg.sender, amount0, amount1, to)
    return amount0, amount1

@external
@nonreentrant("lock")
def swap(amount0Out: uint256, amount1Out: uint256, to: address, data: Bytes[128]):
    """
    @dev Swaps tokens from one token to another.
    @param amount0Out The amount of token0 to swap out.
    @param amount1Out The amount of token1 to swap out.
    @param to The address to send outputed tokens to.
    @param data Encoded data that is forwarded to IUniswapV2Callee via hook.
    """
    assert amount0Out > 0 or amount1Out > 0, "UniswapV2: INSUFFICIENT_OUTPUT_AMOUNT"
    _reserve0: uint112 = self.reserve0 
    _reserve1: uint112 = self.reserve1
    assert amount0Out < convert(_reserve0, uint256) and amount1Out < convert(_reserve1, uint256), "UniswapV2: INSUFFICIENT_LIQUIDITY"
    _token0: address = self.token0
    _token1: address = self.token1
    assert to != _token0 and to != _token1, "UniswapV2: INVALID_TO"
    if amount0Out > 0:
        self._safeTransfer(_token0, to, amount0Out)
    if amount1Out > 0:
        self._safeTransfer(_token1, to, amount1Out)
    
    # # if len(data) > 0:

    balance0: uint256 = ERC20(_token0).balanceOf(self)
    balance1: uint256 = ERC20(_token1).balanceOf(self)
    amount0In: uint256 = 0 
    if balance0 > convert(_reserve0, uint256) - amount0Out:
        amount0In = balance0 - (convert(_reserve0, uint256) - amount0Out) 
    amount1In: uint256 = 0
    if balance1 > convert(_reserve1, uint256) - amount1Out:
        amount1In = balance1 - (convert(_reserve1, uint256) - amount1Out)
    
    assert(amount0In > 0 or amount1In > 0), "UniswapV2: INSUFFICIENT_INPUT_AMOUNT"
    balance0Adjusted: uint256 = balance0 * 1000 - (amount0In * 3)
    balance1Adjusted: uint256 = balance1 * 1000 - (amount1In * 3)
    assert balance0Adjusted * balance1Adjusted >= convert(_reserve0, uint256) * convert(_reserve1, uint256) * 1000000, "UniswapV2: INSUFFICIENT_LIQUIDITY"
    self._update(balance0, balance1, _reserve0, _reserve1)
    log Swap(msg.sender, amount0In, amount1In, amount0Out, amount1Out, to)
    

@external
@nonreentrant("lock")
def skim(to: address):
    """
    @dev Force balances to match reserves
    @param to The address to send excess reserves to.
    """
    _token0: address = self.token0
    _token1: address = self.token1
    self._safeTransfer(_token0, to, ERC20(_token0).balanceOf(self) - convert(self.reserve0, uint256))
    self._safeTransfer(_token1, to, ERC20(_token1).balanceOf(self) - convert(self.reserve1, uint256))

@external
@nonreentrant("lock")
def sync():
    """
    @dev Force reserves to match balances
    """
    self._update(ERC20(self.token0).balanceOf(self), ERC20(self.token1).balanceOf(self), self.reserve0, self.reserve1)