defmodule TinyEVM.Operation do
  @moduledoc """
  Defines the Operation behavior and provides common functions for it. Operations are to be used to implement
  grouping of one or more EVM instructions and calculate their gas prices.
  """
  alias TinyEVM.ExecutionContext

  @callback get_ordered_op_codes() :: [byte]
  @callback execute(op_code :: byte, context :: ExecutionContext) :: ExecutionContext
  @callback get_gas_cost(op_code :: byte, context :: ExecutionContext) :: {:ok | :error, integer}

  @doc """
  Creates an operation result for an Operation that erred with the provided amount of gas remaining and ExecutionContext.
  """
  @spec error(message :: String.t(), gas_remaining :: integer, context :: ExecutionContext) ::
          ExecutionContext
  def error(message, gas_remaining, context) do
    IO.puts(:stderr, message)

    %ExecutionContext{
      gas_remaining: max(gas_remaining, 0),
      gas_refund: 0,
      program_counter: context.program_counter,
      machine_code: context.machine_code,
      stack: [],
      storage: %{},
      execution_state: :error
    }
  end
end
