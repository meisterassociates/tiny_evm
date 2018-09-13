defmodule TinyEVM.Operation.SwapOperation do
  @moduledoc """
  Operation capable of executing and pricing the SWAP1..SWAP16 EVM operations.
  """
  @behaviour TinyEVM.Operation
  alias TinyEVM.Util
  alias TinyEVM.Gas
  alias TinyEVM.Operation
  alias TinyEVM.ExecutionContext

  @swap1_op 144
  @swap16_op 159

  @doc """
  Gets an ordered list of all of the Op Codes this OperationFactory is capable of supporting.

  ## Examples
    iex> TinyEVM.Operation.OperationFactory.SwapOperationFactory.get_ordered_op_codes()
    [144, 145, 146, 147, 148, 149, 150, 151, 152, 153, 154, 155, 156, 157, 158, 159]
  """
  @spec get_ordered_op_codes() :: [byte]
  def get_ordered_op_codes() do
    @swap1_op..@swap16_op
  end

  @doc """
  Executes the SWAP operation, swapping `Enum.at(context.stack, 0)` with index 1-15 depending on the provided `op_code`.
  """
  @spec execute(op_code :: byte, context :: ExecutionContext) :: ExecutionContext
  def execute(op_code, context) do
    {:ok, gas_cost} = get_gas_cost(op_code, context)
    gas_remaining = context.gas_remaining - gas_cost
    swap_index = (op_code - @swap1_op) + 1

    case Util.swap_list_indexes(context.stack, 0, swap_index) do
      {:error, _} ->
        Operation.error("Stack Underflow!", gas_remaining, context)
      {:ok, swapped_stack} ->
        %ExecutionContext{
          gas_remaining: gas_remaining,
          gas_refund: context.gas_refund,
          program_counter: context.program_counter + 1,
          machine_code: context.machine_code,
          stack: swapped_stack,
          storage: context.storage,
          execution_state: :continue
        }
    end
  end

  @doc """
  Gets the gas cost for the SWAP operations.
  """
  @spec get_gas_cost(op_code :: byte, contest :: ExecutionContext) :: {(:ok | :error), integer}
  def get_gas_cost(_op_code, _context) do
    {:ok, Gas.swap()}
  end
end