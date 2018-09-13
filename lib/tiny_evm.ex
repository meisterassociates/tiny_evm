defmodule TinyEVM do
  use Bitwise

  alias TinyEVM.ExecutionContext
  alias TinyEVM.OperationExecutor

  @doc """
  Entrypoint for all TinyEVM execution.
  Runs the provided code and returns the tuple `{gas_remaining_after_execution, address_storage_after_code_execution}`

  ## Success
    Upon successful execution, the following tuple will be returned:
    `{gas_remaining_after_execution_including_resulting_refunds), storage_resulting_from_execution}`

  ## Error
    If code execution results in an error, including running out of gas, this will return a tuple of:
    `{gas_remaining_at_time_of_error, %{address => %{}}}`.

  ## Examples
    iex> TinyEVM.execute(0x0f572e5295c57f15886f9b263e2f6d2d6c7b5ec6, 100000, <<96, 1, 96, 3, 24, 96, 0, 85>>)
    {79988, %{0x0f572e5295c57f15886f9b263e2f6d2d6c7b5ec6 => %{0 => 2}}}
  """
  @spec execute(address :: String.t, gas :: integer, code :: binary) :: {integer, %{String.t => map}}
  def execute(address, gas, code) do
    context = %ExecutionContext{
                gas_remaining: gas,
                gas_refund: 0,
                program_counter: 0,
                machine_code: code,
                stack: [],
                storage: %{},
                execution_state: :continue
    }

    ending_context = execute(context)
    {ending_context.gas_remaining, %{address => ending_context.storage}}
  end

  @doc """
  Recursively executes the operation at the context.program_counter index of context.machine_code for the provided
  context, exiting when the program counter has reached the end of the code or an error or stop instruction is detected.
  """
  @spec execute(context :: ExecutionContext) :: ExecutionContext
  def execute(context) do
    cond do
      context.execution_state == :error ->
        context
      context.execution_state == :stop or context.program_counter >= byte_size(context.machine_code) ->
        %ExecutionContext{
          gas_remaining: context.gas_remaining - context.gas_refund, # Process refund on success
          gas_refund: context.gas_refund, # Leaving this in for visibility on the refund applied
          program_counter: context.program_counter,
          machine_code: context.machine_code,
          stack: context.stack,
          storage: context.storage,
          execution_state: :completed
        }
      true ->
        op_code = :binary.at(context.machine_code, context.program_counter)
        execute(OperationExecutor.execute_operation(op_code, context))
    end
  end
  end
