defmodule TinyEVM.Operation.MultiplyThenModuloOperation do
  @moduledoc """
  Operation capable of executing and pricing the MULMOD EVM operation.
  """
  @behaviour TinyEVM.Operation
  alias TinyEVM.Util
  alias TinyEVM.Gas
  alias TinyEVM.Operation
  alias TinyEVM.ExecutionContext

  @mulmod_op 9

  @doc """
  Gets an ordered list of all of the Op Codes this Operation is capable of supporting.

  ## Examples
    iex> TinyEVM.Operation.MultiplyThenModuloOperation.get_ordered_op_codes()
    [9]
  """
  @spec get_ordered_op_codes() :: [byte]
  def get_ordered_op_codes() do
    [@mulmod_op]
  end

  @doc """
  Executes the Multiply Then Mod operation, which pops 3 items off of the stack in the provided context
  and pushes (item[0] * item[1]) % item[2] onto the stack.
  """
  @spec execute(op_code :: byte, context :: ExecutionContext) :: ExecutionContext
  def execute(op_code, context) when op_code == @mulmod_op do
    {:ok, gas_cost} = get_gas_cost(op_code, context)
    gas_remaining = context.gas_remaining - gas_cost

    case Util.pop_stack(context.stack, 3) do
      {:error, message} ->
        Operation.error(message, gas_remaining, context)

      {:ok, [factor1, factor2, mod_by], stack} ->
        value_to_push = rem(factor1 * factor2, mod_by)

        %ExecutionContext{
          gas_remaining: gas_remaining,
          gas_refund: context.gas_refund,
          program_counter: context.program_counter + 1,
          machine_code: context.machine_code,
          stack: [value_to_push | stack],
          storage: context.storage,
          execution_state: :continue
        }
    end
  end

  @doc """
  Calculates Gas costs for the Multiply Then Mod operation.
  """
  @spec get_gas_cost(op_code :: byte, context :: ExecutionContext) :: {:ok | :error, integer}
  def get_gas_cost(op_code, _context) when op_code == @mulmod_op do
    {:ok, Gas.mulmod()}
  end
end
