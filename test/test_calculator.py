from src.calculator import add, multiply, subtract


def test_add():
    assert add(2, 3) == 5


def test_multiply():
    assert multiply(2, 3) == 6


def test_multiply_with_zero_and_negative_number():
    assert multiply(0, 10) == 0
    assert multiply(-2, 3) == -6


def test_subtract():
    assert subtract(5, 3) == 2


def test_subtract_with_zero_and_negative_number():
    assert subtract(0, 10) == -10
    assert subtract(-2, 3) == -5
