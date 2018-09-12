defmodule TinyEVM.OperationExecutor do
  alias TinyEVM.Operation
  alias TinyEVM.ExecutionContext

  @operation_factories [
    TinyEVM.Operation.OperationFactory.MultiplyThenModuloOperationFactory,
    TinyEVM.Operation.OperationFactory.PushOperationFactory,
    TinyEVM.Operation.OperationFactory.StoreToStorageOperationFactory,
    TinyEVM.Operation.OperationFactory.SwapOperationFactory,
    TinyEVM.Operation.OperationFactory.XorOperationFactory
  ]

  @op_code_to_operation @operation_factories
                        |> Enum.map(fn factory ->
                              Enum.map(factory.get_ordered_op_codes(), fn op ->
                                {op,
                                  %Operation{
                                    get_execute_function: factory.get_op_function(op),
                                    get_gas_cost_function: factory.get_op_gas_cost_function(op)
                                  }
                                }
                              end)
                            end)
                        |> Enum.reduce([], fn tuple_list, agg_list -> agg_list ++ tuple_list  end)
                        |> Map.new


  @spec execute_operation(op_code :: byte, context :: ExecutionContext) :: ExecutionContext
  def execute_operation(op_code, context) do
    op_code_to_operation = @operation_factories
    |> Enum.map(fn factory ->
      Enum.map(factory.get_ordered_op_codes(), fn op ->
        {op,
          %Operation{
            get_execute_function: factory.get_op_function(op),
            get_gas_cost_function: factory.get_op_gas_cost_function(op)
          }
        }
      end)
    end)
    |> Enum.reduce([], fn tuple_list, agg_list -> agg_list ++ tuple_list  end)
    |> Map.new

    if context.gas_remaining <= 0 do
      Operation.error("Out of Gas!", context.gas_remaining, context)
    else
      operation = Map.get(op_code_to_operation, op_code)
      if operation == nil do
        Operation.error("Sorry, we don't support the [#{op_code}] op code yet!", context.gas_remaining, context)
      else
        case operation.get_gas_cost_function().(context) do
          {:error, _} ->
            Operation.error("Error calculating gas costs for operation [#{op_code}}]", context.gas_remaining, context)
          _ ->
            operation.get_execute_function().(context)
        end
      end
    end
  end
end
