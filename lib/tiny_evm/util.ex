defmodule TinyEVM.Util do
  @moduledoc """
  Contains common utility functions used within the TinyEVM.
  """
  use Bitwise

  @stack_limit 1024

  @doc """
  Pops the specified number of items off of the provided stack and returns a tuple.

  ## Examples
    iex> TinyEVM.Util.pop_stack([1, 2], 2)
    {:ok, [1, 2], []}

    iex> TinyEVM.Util.pop_stack([1, 2], 3)
    {:error, "Stack Underflow!"}
  """
  @spec pop_stack(stack :: list, number_to_pop :: integer) ::
          {:ok, list, list} | {:error | String.t()}
  def pop_stack(stack, number_to_pop) do
    {popped, stack} = Enum.split(stack, number_to_pop)

    if length(popped) != number_to_pop do
      {:error, "Stack Underflow!"}
    else
      {:ok, popped, stack}
    end
  end

  @doc """
  Pushes the provided item onto the provided stack and returns the updated stack.

  ## Examples
    iex> TinyEVM.Util.push_stack([1,2], 3)
    {:ok, [1, 2, 3]}

    iex> TinyEVM.Util.push_stack(1..1024, 3)
    {:error, "Stack Overflow! Attempted to push [3] on the stack at max height [1024]."}
  """
  @spec push_stack(stack :: list, item :: any) :: {:ok, list} | {:error | String.t()}
  def push_stack(stack, item) do
    if length(stack) >= @stack_limit do
      {:error,
       "Stack Overflow! Attempted to push [#{item}] on the stack at max height [#{@stack_limit}]."}
    else
      {:ok, [item | stack]}
    end
  end

  @doc """
  Returns the provided binary as an integer where all of its bytes are concatenated to create an integer of the
  specified number of bytes. If the provided binary has fewer bytes than the resulting int, zero bytes will be used for
  for the remaining bytes.
  For example `<<3, 4>>` would become `772` because 3 = 00000011, 4 = 00000100, and 0000001100000100 = 772.

  ## Examples
    iex> TinyEVM.Util.get_binary_as_int(<<3, 4>>, 2)
    772

    iex> TinyEVM.Util.get_binary_as_int(<<3, 4>>, 3)
    197632
  """
  @spec get_binary_as_int(binary :: binary, int_bytes :: integer) :: integer
  def get_binary_as_int(binary, int_bytes) do
    0..(int_bytes - 1)
    |> Enum.reduce(0, fn index, value ->
      (value <<< 8) + if index < byte_size(binary), do: :binary.at(binary, index), else: 0
    end)
  end

  @doc """
  Returns a list equal to the provided list but with the values at the two provided indexes swapped.

  ## Examples
  iex> TinyEVM.Util.swap_list_indexes([1, 2, 3, 4], 1, 3)
  {:ok, [1, 4, 3, 2]}

  iex> TinyEVM.Util.swap_list_indexes([1, 2, 3, 4], 1, 6)
  {:error, []}
  """
  @spec swap_list_indexes(list :: list, index1 :: integer, index2 :: integer) :: list
  def swap_list_indexes(list, index1, index2) do
    list_length = length(list)

    if index1 >= list_length or index2 >= list_length or index1 < 0 or index2 < 0 do
      {:error, []}
    else
      swapped_stack =
        list
        |> Enum.with_index()
        |> Enum.map(fn {value, index} ->
          case index do
            ^index1 -> Enum.at(list, index2)
            ^index2 -> Enum.at(list, index1)
            _ -> value
          end
        end)

      {:ok, swapped_stack}
    end
  end
end
