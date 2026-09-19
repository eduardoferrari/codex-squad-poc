from src.calculator import add, multiply


def test_add():
    assert add(2, 3) == 5


def test_multiply():
    assert multiply(2, 3) == 6


def test_multiply_with_zero_and_negative_number():
    assert multiply(0, 10) == 0
    assert multiply(-2, 3) == -6
