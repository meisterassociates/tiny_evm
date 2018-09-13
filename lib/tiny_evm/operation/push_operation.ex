defmodule TinyEVM.Operation.PushOperation do
  @moduledoc """
  Operation capable of executing and pricing the PUSH1..PUSH32 EVM operations.
  """
  @behaviour TinyEVM.Operation
  alias TinyEVM.Util
  alias TinyEVM.Gas
  alias TinyEVM.Operation
  alias TinyEVM.ExecutionContext

  @push1_op 96
  @push32_op 127

  @doc """
  Gets an ordered list of all of the Op Codes this OperationFactory is capable of supporting.

  ## Examples
    iex> TinyEVM.Operation.OperationFactory.PushOperationFactory.get_ordered_op_codes()
    [96, 97, 98, 99, 100, 101, 102, 103, 104, 105, 106, 107, 108, 109, 110, 111, 112, 113, 114, 115, 116, 117, 118, 119, 120, 121, 122, 123, 124, 125, 126, 127]
  """
  @spec get_ordered_op_codes() :: [byte]
  def get_ordered_op_codes() do
    @push1_op..@push32_op
  end

  @doc """
  Executes the PUSH operation for the provided `op_code`. This will read between 1 and 32 bytes starting from
  `:binary.at(context.machine_code, context.program_counter)` and create a single value from it by concatenating the
  bytes. The resulting value will be pushed onto the stack.
  """
  @spec execute(op_code :: byte, context :: ExecutionContext) :: ExecutionContext
  def execute(op_code, context) do
    num_bytes_to_push = (op_code - @push1_op) + 1
    bytes_pc = context.program_counter + 1
    pc_end_value = min(bytes_pc + num_bytes_to_push, byte_size(context.machine_code))
    bytes_from_code = :binary.part(context.machine_code, bytes_pc, pc_end_value - bytes_pc)
    value_to_push = Util.get_binary_as_int(bytes_from_code, num_bytes_to_push)

    {:ok, gas_cost} = get_gas_cost(op_code, context)
    gas_remaining = context.gas_remaining - gas_cost

    case Util.push_stack(context.stack, value_to_push) do
      {:error, message} ->
        Operation.error(message, gas_remaining, context)
      {:ok, stack} ->
        %ExecutionContext{
          gas_remaining: gas_remaining,
          gas_refund: context.gas_refund,
          program_counter: pc_end_value,
          machine_code: context.machine_code,
          stack: stack,
          storage: context.storage,
          execution_state: :continue
        }
    end
  end

  @doc """
  Gets gas costs for the PUSH function specified in the provided Op Code.
  """
  @spec get_gas_cost(op_code :: byte, context :: ExecutionContext) :: {(:ok | :error), integer}
  def get_gas_cost(_op_code, _context) do
    {:ok, Gas.push()}
  end
end