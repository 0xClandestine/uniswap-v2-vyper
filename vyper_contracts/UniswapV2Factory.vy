interface IUniswapV2Pair:
    def initialize(token0: address, token1: address): nonpayable

event PairCreated:
    token0: indexed(address)
    token1: indexed(address)
    pair: address

exchangeTemplate:   public(address)
feeTo:              public(address)
feeToSetter:        public(address)
getPair:            public(HashMap[address, HashMap[address, address]])
allPairs:           public(DynArray[address, 2**32])

@external
@view
def allPairsLength() -> uint256:
    return len(self.allPairs)

@external
def createPair(tokenA: address, tokenB: address):
    assert tokenA != tokenB, "UniswapV2: IDENTICAL_ADDRESSES"
    token0: address = ZERO_ADDRESS
    token1: address = ZERO_ADDRESS

    if convert(tokenA, uint256) < convert(tokenB, uint256):
        token0 = tokenA
        token1 = tokenB
    else:
        token0 = tokenB
        token1 = tokenA

    assert token0 != ZERO_ADDRESS, "UniswapV2: ZERO_ADDRESS"
    assert self.getPair[token0][token1] == ZERO_ADDRESS, "UniswapV2: PAIR_EXISTS"
    salt: bytes32 = keccak256(concat(convert(token0, bytes32), convert(token1, bytes32)))
    pair: address = create_forwarder_to(self.exchangeTemplate, salt = salt)
    IUniswapV2Pair(pair).initialize(token0, token1)
    self.getPair[token0][token1] = pair
    self.getPair[token1][token0] = pair
    self.allPairs.append(pair)
    log PairCreated(token0, token1, pair)

@external
def setFeeTo(_feeTo: address):
    assert msg.sender == self.feeToSetter, "UniswapV2: FORBIDDEN"
    self.feeTo = _feeTo

@external
def setFeeToSetter(_feeToSetter: address):
    assert msg.sender == self.feeToSetter, "UniswapV2: FORBIDDEN"
    self.feeToSetter = _feeToSetter