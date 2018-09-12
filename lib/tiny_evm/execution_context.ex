defmodule TinyEVM.ExecutionContext do
  @moduledoc """
  Representation of all state the EVM needs to execute.
  Note: Machine State, Substate, Machine Code, Storage, and intermediate execution results are conflated into one
  data structure for convenience, and unused fields are not listed. These can be separated, and missing fields can
  be added as op codes are added that require them to be.
  """
  defstruct [:gas_remaining, :gas_refund, :program_counter, :machine_code, :stack, :storage, :execution_state]
end