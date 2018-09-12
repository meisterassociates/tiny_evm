defmodule TinyEVM.Operation.OperationFactory.StoreToStorageOperationFactory do
  @moduledoc """
  Factory for the SSTORE `TinyEVM.Operation`.
  """
  @behaviour TinyEVM.Operation.OperationFactory
  alias TinyEVM.Util
  alias TinyEVM.Gas
  alias TinyEVM.Operation
  alias TinyEVM.ExecutionContext

  @sstore_op 85

  @doc """
  Gets an ordered list of all of the Op Codes this OperationFactory is capable of supporting.

  ## Examples
    iex> TinyEVM.Operation.OperationFactory.StoreToStorageOperationFactory.get_ordered_op_codes()
    [85]
  """
  @spec get_ordered_op_codes() :: list(byte)
  def get_ordered_op_codes() do
    [@sstore_op]
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
        {:ok, [key, value], stack} ->
          storage = Map.put(context.storage, key, value)
          {_gas_cost, gas_refund} = calculate_storage_gas_cost_and_refund(storage, key, value)

          %ExecutionContext{
            gas_remaining: gas_remaining,
            gas_refund: context.gas_refund + gas_refund,
            program_counter: context.program_counter + 1,
            machine_code: context.machine_code,
            stack: stack,
            storage: storage,
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
    fn context ->
      cond do
        length(context.stack) < 2 ->
          {:error, 0}
        true ->
          [storage_key, storage_value] = Enum.slice(context.stack, 0, 2)
          {gas_cost, _refund} = calculate_storage_gas_cost_and_refund(context.storage, storage_key, storage_value)
          {:ok, gas_cost}
      end
    end
  end

  defp calculate_storage_gas_cost_and_refund(storage, storage_key, storage_value) do
    cond do
      !Map.has_key?(storage, storage_key) or storage[storage_key] == 0 ->
        case storage_value do
          0 -> {0, 0}
          _ -> {Gas.sset(), 0}
        end
      true ->
        case storage_value do
          0 -> {0, Gas.sclear()}
          _ -> {Gas.sreset(), 0}
        end
    end
  end
end