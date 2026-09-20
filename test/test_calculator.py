import pytest

from src.calculator import add, divide, modulo, multiply, power, subtract


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


def test_divide():
    assert divide(6, 3) == 2


def test_divide_by_zero_raises_zero_division_error():
    with pytest.raises(ZeroDivisionError):
        divide(1, 0)


def test_power():
    assert power(2, 3) == 8


def test_power_with_zero_and_negative_exponent():
    assert power(5, 0) == 1
    assert power(2, -2) == 0.25


def test_modulo():
    assert modulo(7, 3) == 1


def test_modulo_with_negative_operand():
    assert modulo(-7, 3) == 2
