defmodule SQ.Store do
  alias SQ.Message

  @callback all() :: [Message.t()]

  @callback queued() :: [Message.t()]

  @callback get(id :: non_neg_integer) :: Message.t() | {:error, :not_found}

  @callback insert(message :: Message.t()) :: Message.t()

  @callback update(id :: non_neg_integer, updates :: keyword) ::
              Message.t() | {:error, :not_found}

  @callback delete(message_or_id :: Message.t() | non_neg_integer) :: :ok

  @callback mark_as_last(id :: non_neg_integer) :: Message.t() | {:error, :not_found}

  @callback purge() :: :ok

  # returns messages in asc order (by id), order should be configurable
  def all(config \\ []) do
    store(config).all()
  end

  # returns messages in desc order (by id), order should be configurable
  def queued(config \\ []) do
    store(config).queued()
  end

  def get(id, config \\ []) do
    store(config).get(id)
  end

  def insert(message, config \\ []) do
    store(config).insert(message)
  end

  def update(id, updates, config \\ []) do
    store(config).update(id, updates)
  end

  def delete(message_or_id, config \\ []) do
    store(config).delete(message_or_id)
  end

  def purge(config \\ []) do
    store(config).purge()
  end

  # This could be accomplished with update, unfortunately mnesia is not a
  # regular RDBMS and we opted in to use autoincremented ID as our primary key
  # that mnesia uses to sort by (ordered_set). This is implementation detail
  # that leaked into our abstraction.
  def mark_as_last(id, config \\ []) do
    store(config).mark_as_last(id)
  end

  @default_store SQ.Mnesia
  defp store(config) do
    Keyword.get(config, :store, @default_store)
  end
end
