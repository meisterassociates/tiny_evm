defmodule TinyEVM.OperationExecutor do
  @moduledoc """
  Façade executor for Operations, allowing the appropriate Operation to be used based on Op Code.
  """

  alias TinyEVM.Operation
  alias TinyEVM.ExecutionContext

  @operations [
    TinyEVM.Operation.MultiplyThenModuloOperation,
    TinyEVM.Operation.PushOperation,
    TinyEVM.Operation.StoreToStorageOperation,
    TinyEVM.Operation.SwapOperation,
    TinyEVM.Operation.XorOperation
  ]

  @op_code_to_operation @operations
                        |> Enum.map(fn operation ->
                          Enum.map(operation.get_ordered_op_codes(), fn op -> {op, operation} end)
                        end)
                        |> Enum.reduce([], fn tuple_list, agg_list -> agg_list ++ tuple_list end)
                        |> Map.new()

  @spec execute_operation(op_code :: byte, context :: ExecutionContext) :: ExecutionContext
  def execute_operation(op_code, context) do
    if context.gas_remaining <= 0 do
      Operation.error("Out of Gas!", context.gas_remaining, context)
    else
      operation = Map.get(@op_code_to_operation, op_code)

      if operation == nil do
        Operation.error(
          "Sorry, we don't support the [#{op_code}] op code yet!",
          context.gas_remaining,
          context
        )
      else
        case operation.get_gas_cost(op_code, context) do
          {:error, _} ->
            Operation.error(
              "Error calculating gas costs for operation [#{op_code}}]",
              context.gas_remaining,
              context
            )

          _ ->
            operation.execute(op_code, context)
        end
      end
    end
  end
end
