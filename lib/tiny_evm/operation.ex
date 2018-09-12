defmodule TinyEVM.Operation do
  alias TinyEVM.ExecutionContext

  @type get_execute_function :: (ExecutionContext -> {[:ok | :error], ExecutionContext})
  @type get_gas_cost_function :: (ExecutionContext -> integer)
  @enforce_keys [:get_execute_function, :get_gas_cost_function]
  defstruct [:get_execute_function, :get_gas_cost_function]

  @doc """
  Creates an operation result for an Operation that erred with the provided amount of gas remaining and ExecutionContext.
  """
  @spec error(message :: String.t, gas_remaining :: integer, context :: ExecutionContext) :: ExecutionContext
  def error(message, gas_remaining, context) do
    IO.puts :stderr, message
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
