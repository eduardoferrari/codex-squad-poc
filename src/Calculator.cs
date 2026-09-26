namespace CodexSquadPoc;

public static class Calculator
{
    public static double Add(double a, double b) => a + b;

    public static double Multiply(double a, double b) => a * b;

    public static double Subtract(double a, double b) => a - b;

    public static double Divide(double a, double b)
    {
        if (b == 0)
        {
            throw new DivideByZeroException("The divisor cannot be zero.");
        }

        return a / b;
    }

    public static double Power(double a, double b) => Math.Pow(a, b);

    public static double Square(double a) => Power(a, 2);

    // Python's remainder has the sign of the divisor, unlike C#'s % operator.
    public static double Modulo(double a, double b)
    {
        if (b == 0)
        {
            throw new DivideByZeroException("The divisor cannot be zero.");
        }

        return a - (Math.Floor(a / b) * b);
    }
}
