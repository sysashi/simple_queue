defmodule SQ.Mnesia do
  use Amnesia

  @behaviour SQ.Store

  defdatabase Database do
    deftable Message, [{:id, autoincrement}, :message, :status],
      type: :ordered_set,
      index: [:status] do
      def read_for_update(id) when is_integer(id) do
        Message.read(id, :write)
      end

      def insert(%Message{} = message) do
        Message.write(message)
      end
    end
  end

  @impl true
  def all() do
    Amnesia.transaction!(fn -> Database.Message.match([]) end)
    |> coerce()
    |> Enum.map(&convert/1)
  end

  @impl true
  def queued() do
    Amnesia.transaction!(fn -> Database.Message.match(status: :queued) end)
    |> coerce()
    |> Enum.map(&convert/1)
  end

  @impl true
  def get(id) do
    Amnesia.transaction!(fn ->
      case Database.Message.read(id) |> wrap_result() do
        {:ok, message} -> convert(message)
        error -> error
      end
    end)
  end

  @impl true
  def insert(%SQ.Message{} = message) do
    Amnesia.transaction!(fn ->
      message
      |> convert()
      |> Database.Message.insert()
      |> convert()
    end)
  end

  @impl true
  def update(id, updates) when is_integer(id) and is_list(updates) do
    Amnesia.transaction!(fn ->
      case id |> Database.Message.read_for_update() |> wrap_result() do
        {:ok, message} ->
          message
          |> struct(updates)
          |> Database.Message.insert()
          |> convert()

        error ->
          error
      end
    end)
  end

  @impl true
  def delete(%SQ.Message{} = message) do
    Amnesia.transaction!(fn ->
      message |> convert() |> Database.Message.delete()
    end)
  end

  def delete(id) when is_integer(id) and id > 0 do
    Amnesia.transaction!(fn ->
      case id |> Database.Message.read() |> wrap_result() do
        {:ok, message} ->
          Database.Message.delete(message)

        error ->
          error
      end
    end)
  end

  @impl true
  def mark_as_last(id) do
    Amnesia.transaction!(fn ->
      case id |> Database.Message.read() |> wrap_result() do
        {:ok, message} ->
          :ok = Database.Message.delete(message)

          %{message | id: nil}
          |> Database.Message.insert()
          |> convert()

        error ->
          error
      end
    end)
  end

  @impl true
  def purge() do
    Amnesia.Table.clear(Database.Message)
  end

  defp convert(%SQ.Message{} = message) do
    struct!(Database.Message, Map.from_struct(message))
  end

  defp convert(%Database.Message{} = message) do
    struct!(SQ.Message, Map.from_struct(message))
  end

  # not sure if amnesia provides built-in solution for building structs out of
  # match / select values
  defp coerce(nil), do: []

  defp coerce(%{values: values}) do
    Enum.map(values, &coerce/1)
  end

  defp coerce({Database.Message, id, message, status}) do
    %Database.Message{
      id: id,
      message: message,
      status: status
    }
  end

  defp wrap_result(nil), do: {:error, :not_found}
  defp wrap_result(res), do: {:ok, res}
end
