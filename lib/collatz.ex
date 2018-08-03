defmodule Collatz do
  @moduledoc """
  From https://en.wikipedia.org/wiki/Collatz_conjecture:

      The [Collatz] conjecture can be summarized as follows.
      Take any natural number n. If n is even, divide it by
      2 to get n / 2. If n is odd, multiply it by 3 and add
      1 to obtain 3n + 1. Repeat the process indefinitely.
      The conjecture is that, no matter what number you
      start with, you will always eventually reach 1.
  """

  defmacro is_even(n) do
    quote do
      rem(unquote(n), 2) == 0 and unquote(n) != 0
    end
  end

  defmacro is_odd(n) do
    quote do
      abs(rem(unquote(n), 2)) == 1
    end
  end

  defmacro is_natural(n) do
    quote do
      is_integer(unquote n) and unquote(n) > 0
    end
  end


### API ###

  @doc """
    Given a positive integer n:
      if n is even => n/2
      if n is odd  => 3n + 1
  """
  @spec step(pos_integer)
    :: pos_integer
  def step(n) when is_natural(n) and is_even(n),
    do: div(n, 2)

  def step(n) when is_natural(n) and is_odd(n),
    do: 3*n + 1


  defp _run_odd(1, acc),
    do: Enum.reverse [1|acc]

  defp _run_odd(n, acc) when is_odd(n),
    do: _run_odd(step(n), [n|acc])

  defp _run_odd(n, acc) when is_even(n),
    do: _run_odd(step(n), acc)

  @doc """
  Produces a hailstone sequence containing only the odd
  numbers.

  ## Example
    iex> Collatz.run 7
    [7, 11, 17, 13, 5, 1]
  """
  @spec run_odd(pos_integer)
    :: [pos_integer]
  def run_odd(n) when is_natural(n),
    do: _run_odd(n, [])


  @spec run(pos_integer)
    :: [pos_integer]
  def run(n) when is_natural n do
    sequence =
      n
      |> Stream.iterate(&step/1)
      |> Enum.take_while(& &1 > 1)

    sequence ++ [1]
  end


  @doc """
  Remove repeating 0b01 from end of `n` by subtracting one
  and dividing by four recursively.
  """
  @spec collapse(pos_integer)
    :: pos_integer
  def collapse(0),
    do: 1

  def collapse(n)
      when is_natural(n)
       and rem(n - 1, 4) == 0,
    do: collapse div(n - 1, 4)

  def collapse(n)
      when is_natural(n)
       and is_odd(n),
    do: n

  def collapse(n)
      when is_natural(n)
       and is_even(n),
    do: 4*n + 1


  def base_orbit(1) do
    # 0b1,
    # 0b101,
    # 0b10101,
    # 0b1010101,
    # ...
    #
    Stream.unfold({1, 0}, fn {i, sum} ->
      new_sum =
        sum + trunc :math.pow(4, i - 1)

      {new_sum, {i + 1, new_sum}}
    end)
    |> Stream.drop(1)
  end

  def base_orbit(2) do
    # 0b1,
    # 0b11,
    # 0b1110001,
    # 0b11100011,
    # 0b1110001110001,
    # ...
    #
    Stream.iterate(1, fn sum ->
      new_sum = 2*sum + 1

      if rem(new_sum, 7) == 0
      do
        16*new_sum + 1
      else
        new_sum
      end
    end)
    |> Stream.drop(1)
  end

  def base_orbit(_) do
    nil
  end

  defp _sequence(1, {seq, e}),
    do: Enum.reverse [e|seq]

  defp _sequence(n, {seq, e}) do
    next_n = div(n, 2)

    case rem(n, 2) do
      0 ->
        _sequence(next_n, {seq, e + 1})

      1 ->
        next_seq =
          if e == 0 do
            seq
          else
            [e|seq]
          end

        _sequence(3*n + 1, {next_seq, 0})
    end
  end

  def sequence(n),
    do: _sequence(n, {[], 0})

  defp _unsequence([], acc),
    do: acc

  defp _unsequence([h|t], acc) do
    multiply = &(&1 * &2)
    subtract = &(&1 - &2)
    divide   = &(&1 / &2)

    candidate =
      acc
      |> multiply.(:math.pow(2, h))
      |> subtract.(1)
      |> divide.(3)

    next_acc = trunc candidate

    if candidate == next_acc do
      _unsequence(t, next_acc)
    else
      raise "Sequence does not produce a hailstone number"
    end
  end

  def unsequence(seq) do
    seq
    |> Enum.reverse
    |> _unsequence(1)
  end

  defp edge_to_dot({v1, v2}),
    do: "  #{v1} -> #{v2};"


  @doc """
  Break hailstone sequences into pairs of subsequent
  numbers. Add the pairs from each sequence to a dictionary,
  thereby storing only unique pairs. Output each pair of
  numbers as a graph edge in dot. For example,

      [7, 11, 17, 13, 5, 1] -> %{7 => 11, 11 => 17, 17 => 13, 13 => 5, 5 => 1}

  It is not obvious that adding pairs of subsequent numbers
  to a dictionary will produce a unique list without missing
  pairs. Because the resulting digraph is a rooted tree, and
  because the dictionary key is always the number furthest
  from the tree's root, we are assured that there may be
  many identical dictionary values but only unique keys
  corresponding to unique key-value pairs.

  Consider the directed graph A--B rooted at node A.
                              |\
                              D C

  Attempting to store the edges as
  `%{A => B, A => C, A => D}` will clearly result in
  collision. However `%{B => A, C => A, D => A}` works just
  fine, and so it must be for any graph that is a rooted
  (directed) tree.
  """
  @spec graph(Range.t)
    :: String.t
  def graph(range \\ 1..256) do
    edges =
      Enum.reduce range, %{}, fn(n, acc) ->
        n
        |> run_odd
        |> Stream.map(&collapse/1)
        |> Stream.chunk(2, 1)
        |> Stream.map(&List.to_tuple(&1))
        |> Enum.into(%{})
        |> Map.merge(acc)
      end

    dot_edges =
      edges
      |> Enum.map(&edge_to_dot(&1))
      |> Enum.join("\n")

    """
    digraph G {
    #{dot_edges}
    }
    """
  end
end

