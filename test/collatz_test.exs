defmodule CollatzTest do
  use ExUnit.Case

  require Collatz

  test "-1 is not natural" do 
    assert Collatz.is_natural(-1) == false
  end

  test "0 is not natural" do 
    assert Collatz.is_natural(0) == false
  end

  test "0.2 is not natural" do 
    assert Collatz.is_natural(0.2) == false
  end

  test "1 is natural" do 
    assert Collatz.is_natural(1) == true
  end

  test "2 is natural" do 
    assert Collatz.is_natural(2) == true
  end

  test "123456789 is natural" do 
    assert Collatz.is_natural(123456789) == true
  end

  test "0 is not odd" do
    assert Collatz.is_odd(0) == false
  end

  test "0 is not even" do
    assert Collatz.is_even(0) == false
  end

  test "1 is odd" do
    assert Collatz.is_odd(1) == true
  end

  test "2 is even" do
    assert Collatz.is_even(2) == true
  end

  test "3 is not even" do
    assert Collatz.is_even(3) == false
  end

  test "4 is not odd" do
    assert Collatz.is_odd(4) == false
  end

  test "-1 is odd" do
    assert Collatz.is_odd(-1) == true
  end

  test "-2 is even" do
    assert Collatz.is_even(-2) == true
  end

  test "2^1023 is even" do
    assert Collatz.is_even(trunc(:math.pow(2, 1023))) == true
  end

  test "step returns 4, given 1" do
    assert Collatz.step(1) == 4
  end

  test "step returns 2, given 4" do
    assert Collatz.step(4) == 2
  end

  test "step returns 1, given 2" do
    assert Collatz.step(2) == 1
  end

  test "step fails for a negative input" do
    assert_raise FunctionClauseError, fn ->
      Collatz.step -1
    end
  end

  test "step fails for a floating-point input" do
    assert_raise FunctionClauseError, fn ->
      Collatz.step 0.2
    end
  end

  test "run fails for a negative input" do
    assert_raise FunctionClauseError, fn ->
      Collatz.run -1
    end
  end

  test "run fails for a floating-point input" do
    assert_raise FunctionClauseError, fn ->
      Collatz.run 0.2
    end
  end

  test "run returns [7, 11, 17, 13, 5, 1], given 7" do
    assert Collatz.run(7) == [7, 11, 17, 13, 5, 1]
  end

  test "run returns [1] for a large power of 2" do
    assert Collatz.run(trunc(:math.pow(2, 1023))) == [1]
  end
end
