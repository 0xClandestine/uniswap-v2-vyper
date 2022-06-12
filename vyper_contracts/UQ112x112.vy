Q112: constant(uint256) = 5192296858534827628530496329220096 # type(uint112).max not supported in vyper :(

@external
def encode(y: uint112) -> uint224:
    return convert(unsafe_mul(convert(y, uint256), Q112), uint224)

@external
def uqdiv(x: uint224, y: uint112) -> uint256:
    return unsafe_div(convert(x, uint256), convert(y, uint256))