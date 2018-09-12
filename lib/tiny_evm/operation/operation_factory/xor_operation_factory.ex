defmodule TinyEVM.Operation.OperationFactory.XorOperationFactory do
  @moduledoc """
  Factory for the XOR `TinyEVM.Operation`.
  """
  @behaviour TinyEVM.Operation.OperationFactory
  use Bitwise
  alias TinyEVM.Util
  alias TinyEVM.Gas
  alias TinyEVM.Operation
  alias TinyEVM.ExecutionContext

  @xor_op 24

  @doc """
  Gets an ordered list of all of the Op Codes this OperationFactory is capable of supporting.

  ## Examples
    iex> TinyEVM.Operation.OperationFactory.XorOperationFactory.get_ordered_op_codes()
    [24]
  """
  @spec get_ordered_op_codes() :: list(byte)
  def get_ordered_op_codes() do
    [@xor_op]
  end

  @doc """
  Gets the execute function for the provided Op Code.
  """
  @spec get_op_function(op_code :: byte) :: ( ExecutionContext -> {[:ok | :error], ExecutionContext})
  def get_op_function(op_code) do
    fn context ->
      {:ok, gas_cost} = get_op_gas_cost_function(op_code).(context)
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
  end

  @doc """
  Gets the function that calculates net gas for the the provided op code.
  """
  @spec get_op_gas_cost_function(op_code :: byte) :: (ExecutionContext -> {(:ok | :error), integer})
  def get_op_gas_cost_function(_op_code) do
    fn _context -> {:ok, Gas.xor()} end
  end
end