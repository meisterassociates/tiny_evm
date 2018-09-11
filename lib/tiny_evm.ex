defmodule TinyEVM do
  use Bitwise
  alias TinyEVM.{ExecutionContext}

  @stack_limit 1024

  # Operations
  @mulmod_op 09
  @push1_op 96
  @push32_op 127
  @sstore_op 85
  @swap1_op 144
  @swap16_op 159
  @xor_op 24

  # Operations' gas cost / refund
  @gas %{
    mulmod: 8,
    push: 3,
    sclear: 15000,
    sreset: 5000,
    sset: 20000,
    swap: 3,
    xor: 3
  }

  defmodule ExecutionContext do
     @moduledoc """
     Representation of all state the EVM needs to execute.
     Note: Machine State, Substate, Machine Code, Storage, and intermediate execution results are conflated into one
     data structure for convenience, and unused fields are not listed. These can be separated, and missing fields can
     be added as op codes are added that require them to be.
     """
    defstruct [:gas_remaining, :gas_refund, :program_counter, :machine_code, :stack, :storage, :execution_state]
  end

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

  defp execute(context) do
    # Recursively execute steps, returning when success or failure is detected
    cond do
      context.execution_state == :error ->
        # Execution Error
        context
      context.execution_state == :stop or context.program_counter >= byte_size(context.machine_code) ->
        # Successful execution
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
        # Still recursively processing
        op_code = :binary.at(context.machine_code, context.program_counter)
        execute(execute_instruction(op_code, context))
    end
  end

  defp execute_instruction(op_code, context) do
    # Just wraps execute_instruction!(...), catching any exceptions thrown, and reverting state if one is caught.
    try do
      execute_instruction!(op_code, context)
    catch
      {remaining_gas, error_message} ->
        IO.puts :stderr, "Execution Error: [#{error_message}]. Remaining gas: [#{remaining_gas}]."
        %ExecutionContext{
          gas_remaining: context.gas_remaining,
          gas_refund: 0,
          program_counter: context.program_counter,
          machine_code: context.machine_code,
          stack: [],
          storage: %{},
          execution_state: :error
        }
    end
  end

  defp execute_instruction!(@mulmod_op, context) do
    gas_remaining = subtract_gas!(context.gas_remaining, @gas.mulmod)
    {[factor1, factor2, mod_by], stack} = pop_stack!(context.stack, context.gas_remaining, 3)

    value_to_push = rem (factor1 * factor2), mod_by

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

  defp execute_instruction!(push_op, context) when @push1_op <= push_op and push_op <= @push32_op do
    gas_remaining = subtract_gas!(context.gas_remaining, @gas.push)
    num_bytes_to_push = (push_op - @push1_op) + 1

    {value_to_push, program_counter} = get_push_val_from_code(num_bytes_to_push, context.program_counter + 1, context.machine_code)

    %ExecutionContext{
      gas_remaining: gas_remaining,
      gas_refund: context.gas_refund,
      program_counter: program_counter,
      machine_code: context.machine_code,
      stack: push_stack!(context.stack, value_to_push, gas_remaining),
      storage: context.storage,
      execution_state: :continue
    }
  end

  defp execute_instruction!(@sstore_op, context) do
    {[key, value], stack} = pop_stack!(context.stack, context.gas_remaining, 2)

    {gas_cost, gas_refund} = calculate_storage_gas_cost_and_refund(context.storage, key, value)
    gas_remaining = subtract_gas!(context.gas_remaining, gas_cost)

    storage = Map.put(context.storage, key, value)
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

  defp execute_instruction!(swap_code, context) when @swap1_op <= swap_code and swap_code <= @swap16_op do
    gas_remaining = subtract_gas!(context.gas_remaining, @gas.swap)

    swap_index = (swap_code - @swap1_op) + 1
    if length(context.stack) <= swap_index do
      throw({gas_remaining, "Stack Overflow!"})
    end

    swapped_stack =
      context.stack
      |> Enum.with_index
      |> Enum.map(fn({value, index}) ->
        case index do
          0 -> Enum.at(context.stack, swap_index)
          ^swap_index -> Enum.at(context.stack, 0)
          _ -> value
        end
      end)

    %ExecutionContext{
      gas_remaining: gas_remaining,
      gas_refund: context.gas_refund,
      program_counter: context.program_counter + 1,
      machine_code: context.machine_code,
      stack: swapped_stack,
      storage: context.storage,
      execution_state: :continue
    }
  end

  defp execute_instruction!(@xor_op, context) do
    gas_remaining = subtract_gas!(context.gas_remaining, @gas.xor)

    {[xor_first, xor_second], stack} = pop_stack!(context.stack, gas_remaining, 2)
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

  defp execute_instruction!(op, context) do
    IO.puts("Sorry, we don't support operation [#{op}] yet!")
    throw({context.gas_remaining, "Unsupported Op Code Received [#{op}]."})
  end

  def calculate_storage_gas_cost_and_refund(storage, key, value) do
    cond do
      !Map.has_key?(storage, key) or storage[key] == 0 ->
        cond do
          value == 0 ->
            # Value is unchanged, so is gas
            {0, 0}
          true ->
            # We are setting from 0 to non-zero
            {@gas.sset, 0}
        end
      true ->
        cond do
          # We're clearing the value from non-zero to 0
          value == 0 ->
            {0, @gas.sclear}
          # We're simply changing from one non-zero value to another
          true ->
            {@gas.sreset, 0}
        end
    end
  end

  defp subtract_gas!(gas_remaining, amount) when gas_remaining - amount < 0 do
    throw({0, "Ran out of gas!"})
  end

  defp subtract_gas!(gas_remaining, amount) do
    gas_remaining - amount
  end

  defp pop_stack!(stack, gas_remaining, number_to_pop) do
    {popped, stack} = Enum.split(stack, number_to_pop)
    if length(popped) != number_to_pop do
      throw({gas_remaining, "Stack Underflow!"})
    else
      {popped, stack}
    end
  end

  defp push_stack!(stack, item, gas_remaining) do
    if length(stack) >= @stack_limit do
      throw({gas_remaining, "Stack Overflow! Attempted to push [#{item}] on the stack at max height [#{@stack_limit}]"})
    else
      [item | stack]
    end
  end

  # num_bytes_to_push, context.program_counter, context.machine_code
  defp get_push_val_from_code(bytes_to_push, program_counter, code) do
    get_push_val_from_code(bytes_to_push, program_counter, code, 0)
  end

  defp get_push_val_from_code(bytes_to_push, program_counter, _code, current_value) when bytes_to_push == 0 do
    {current_value, program_counter}
  end

  defp get_push_val_from_code(bytes_to_push, program_counter, code, current_value) when program_counter >= byte_size(code) do
    get_push_val_from_code(bytes_to_push - 1, program_counter, code, (current_value <<< 8))
  end

  defp get_push_val_from_code(bytes_to_push, program_counter, code, current_value) do
    get_push_val_from_code(bytes_to_push - 1, program_counter + 1, code, (current_value <<< 8) + :binary.at(code, program_counter))
  end

end
