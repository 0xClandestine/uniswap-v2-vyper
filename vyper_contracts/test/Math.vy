

@external
def sqrt256(y: uint256) -> uint256:
    """
    @dev babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
    """
    z: uint256 = 0
    if y > 3:
        z = y
        x: uint256 = unsafe_add(shift(y, -1), 1)
        for i in range(256):
            if (z > y):
                break
            z = x
            x = shift(unsafe_add(unsafe_div(y, x), x), -1)
    elif y != 0:  
        z = 1
    return z