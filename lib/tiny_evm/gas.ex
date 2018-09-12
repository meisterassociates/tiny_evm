defmodule TinyEVM.Gas do
  @moduledoc """
  Exposes gas costs / credits for different EVM instructions.
  """

  @very_low 3
  @mid 8

  def mulmod do
    @mid
  end

  def push do
    @very_low
  end

  def sclear do
    15000
  end

  def sreset do
    5000
  end

  def sset do
    20000
  end

  def swap do
    @very_low
  end

  def xor do
    @very_low
  end

end
