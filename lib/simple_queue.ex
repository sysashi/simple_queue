defmodule SQ do
  @moduledoc false

  alias SQ.Queue

  @name SQ

  def create!() do
    {:ok, _} = GenServer.start_link(Queue, [], name: @name)
    :ok
  end

  def add(message), do: Queue.add(@name, message)

  def get(), do: Queue.get(@name)

  def ack(id), do: Queue.ack(@name, id)

  def reject(id), do: Queue.reject(@name, id)

  def purge(opts \\ []), do: Queue.purge(@name, opts)
end
