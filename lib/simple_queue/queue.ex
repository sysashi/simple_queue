defmodule SQ.Queue do
  use GenServer

  alias SQ.{Store, Message}

  def start_link(opts) do
    GenServer.start_link(__MODULE__, :ok, opts)
  end

  def init(_opts) do
    {:ok, :queue.new(), {:continue, :init}}
  end

  ## API

  @type queue :: pid | atom

  @typep id :: non_neg_integer

  @typep message :: {id, message :: term}

  @spec add(queue, arg :: term) :: :ok
  def add(queue, message) do
    GenServer.call(queue, {:add, message})
  end

  @spec get(queue) :: message | :empty
  def get(queue) do
    GenServer.call(queue, :get)
  end

  @spec ack(queue, id) :: :ok | {:error, :not_found}
  def ack(queue, id) do
    GenServer.call(queue, {:ack, id})
  end

  @spec reject(queue, id) :: :ok | {:error, :not_found}
  def reject(queue, id) do
    GenServer.call(queue, {:reject, id})
  end

  @spec purge(queue, opts :: keyword) :: :ok
  def purge(queue, opts \\ []) do
    GenServer.call(queue, {:purge, opts})
  end

  ## Implementation

  def handle_continue(:init, _) do
    {:noreply, Store.queued() |> Enum.reverse() |> :queue.from_list()}
  end

  def handle_call({:add, message}, _from, queue) do
    message = Message.build(message) |> Store.insert()
    {:reply, :ok, enqueue(queue, message)}
  end

  def handle_call(:get, _from, queue) do
    case dequeue(queue) do
      {%Message{id: id, message: message}, queue} ->
        {:reply, {id, message}, queue}

      {:empty, queue} ->
        {:reply, :empty, queue}
    end
  end

  def handle_call({:ack, id}, _from, queue) do
    {:reply, handle_ack(id, queue_config()), queue}
  end

  def handle_call({:reject, id}, _from, queue) do
    case handle_reject(id, queue, queue_config()) do
      {%Message{}, queue} ->
        {:reply, :ok, queue}

      {error, queue} ->
        {:reply, error, queue}
    end
  end

  def handle_call({:purge, opts}, _from, _queue) do
    if Keyword.get(opts, :table, false) do
      :ok = Store.purge(queue_config())
    end

    {:reply, :ok, :queue.new()}
  end

  def enqueue(queue, message) do
    :queue.in(message, queue)
  end

  def dequeue(queue) do
    case :queue.out(queue) do
      {{:value, message}, queue} ->
        {message, queue}

      {:empty, queue} ->
        {:empty, queue}
    end
  end

  def handle_ack(message_id, opts) do
    with {:mark, status} <- action(opts),
         %Message{} <- Store.update(message_id, [status: status], opts) do
      :ok
    else
      :delete ->
        Store.delete(message_id, opts)

      error ->
        error
    end
  end

  def handle_reject(message_id, queue, opts) do
    case Store.mark_as_last(message_id, opts) do
      %SQ.Message{} = message ->
        {message, enqueue(queue, message)}

      error ->
        {error, queue}
    end
  end

  defp action(opts) do
    if opts[:mark_completed] do
      {:mark, Keyword.get(opts, :mark_with, :completed)}
    else
      :delete
    end
  end

  defp queue_config(), do: Application.get_env(:simple_queue, :queue, [])
end
