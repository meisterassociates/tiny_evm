defmodule TinyEVM.Operation.OperationFactory do
  @moduledoc """
  Defines the contract for an EVM Operation, which may have many different variants with different Op Codes.
  """
  alias TinyEVM.ExecutionContext

  @callback get_ordered_op_codes() :: [byte]
  @callback get_op_function(op_code :: byte) :: ( ExecutionContext -> ExecutionContext)
  @callback get_op_gas_cost_function(op_code :: byte) :: (ExecutionContext -> {(:ok | :error), integer})
end