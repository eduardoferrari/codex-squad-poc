using CodexSquadPoc;
using Xunit;

namespace CodexSquadPoc.Tests;

public class CalculatorTests
{
    [Fact]
    public void Add_returns_sum() => Assert.Equal(5, Calculator.Add(2, 3));

    [Fact]
    public void Multiply_handles_zero_and_negative_values()
    {
        Assert.Equal(0, Calculator.Multiply(0, 10));
        Assert.Equal(-6, Calculator.Multiply(-2, 3));
    }

    [Fact]
    public void Subtract_returns_difference() => Assert.Equal(2, Calculator.Subtract(5, 3));

    [Fact]
    public void Divide_returns_quotient()
        => Assert.Equal(2, Calculator.Divide(6, 3));

    [Fact]
    public void Divide_by_zero_throws()
        => Assert.Throws<DivideByZeroException>(() => Calculator.Divide(1, 0));

    [Fact]
    public void Power_supports_zero_and_negative_exponents()
    {
        Assert.Equal(8, Calculator.Power(2, 3));
        Assert.Equal(1, Calculator.Power(5, 0));
        Assert.Equal(0.25, Calculator.Power(2, -2));
    }

    [Fact]
    public void Square_returns_the_square() => Assert.Equal(16, Calculator.Square(4));

    [Fact]
    public void Modulo_matches_python_for_negative_operands()
    {
        Assert.Equal(1, Calculator.Modulo(7, 3));
        Assert.Equal(2, Calculator.Modulo(-7, 3));
    }
}
