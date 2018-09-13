defmodule TinyEVM.Operation.XorOperation do
  @moduledoc """
  Operation capable of executing and pricing the XOR EVM operation.
  """
  @behaviour TinyEVM.Operation
  use Bitwise
  alias TinyEVM.Util
  alias TinyEVM.Gas
  alias TinyEVM.Operation
  alias TinyEVM.ExecutionContext

  @xor_op 24

  @doc """
  Gets an ordered list of all of the Op Codes this Operation is capable of supporting.

  ## Examples
    iex> TinyEVM.Operation.XorOperation.get_ordered_op_codes()
    [24]
  """
  @spec get_ordered_op_codes() :: [byte]
  def get_ordered_op_codes() do
    [@xor_op]
  end

  @doc """
  Executes the XOR EVM operation, popping 2 items off of the stack, executing item1 XOR item2, and pushes the
  result on the stack.
  """
  @spec execute(op_code :: byte, context :: ExecutionContext) :: ExecutionContext
  def execute(op_code, context) when op_code == @xor_op do
    {:ok, gas_cost} = get_gas_cost(op_code, context)
    gas_remaining = context.gas_remaining - gas_cost

    case Util.pop_stack(context.stack, 2) do
      {:error, message} ->
        Operation.error(message, gas_remaining, context)
      {:ok, [xor_first, xor_second], stack} ->
        to_push = xor_first ^^^ xor_second

        %ExecutionContext{
          gas_remaining: gas_remaining,
          gas_refund: context.gas_refund,
          program_counter: context.program_counter + 1,
          machine_code: context.machine_code,
          stack: [to_push | stack],
          storage: context.storage,
          execution_state: :continue
        }
    end
  end

  @doc """
  Gets the gas cost for the XOR operation.
  """
  @spec get_gas_cost(op_code :: byte, context :: ExecutionContext) :: {(:ok | :error), integer}
  def get_gas_cost(op_code, _context) when op_code == @xor_op do
    {:ok, Gas.xor()}
  end
end