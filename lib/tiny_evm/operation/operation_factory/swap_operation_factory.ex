defmodule TinyEVM.Operation.OperationFactory.SwapOperationFactory do
  @moduledoc """
  Factory for the SWAP1..SWAP16 `TinyEVM.Operation`s.
  """
  @behaviour TinyEVM.Operation.OperationFactory
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
  @spec get_ordered_op_codes() :: list(byte)
  def get_ordered_op_codes() do
    @swap1_op..@swap16_op
  end

  @doc """
  Gets the execute function for the provided Op Code.
  """
  @spec get_op_function(op_code :: byte) :: ( ExecutionContext -> {[:ok | :error], ExecutionContext})
  def get_op_function(op_code) do
    fn context ->
      {:ok, gas_cost} = get_op_gas_cost_function(op_code).(context)
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
  end

  @doc """
  Gets the function that calculates net gas for the the provided op code.
  """
  @spec get_op_gas_cost_function(_op_code :: byte) :: (ExecutionContext -> {(:ok | :error), integer})
  def get_op_gas_cost_function(_op_code) do
    fn _context ->
      {:ok, Gas.swap()}
    end
  end
end