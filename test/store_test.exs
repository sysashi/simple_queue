defmodule SQ.StoreTest do
  use SQ.DataCase

  setup do
    create_store!()

    on_exit(fn ->
      destroy_store()
    end)
  end

  test "insert message" do
    messages = ~w(foo bar baz)a |> Enum.map(&Message.build/1)

    Enum.each(messages, &Store.insert/1)

    assert Enum.map(Store.all(), & &1.message) == Enum.map(messages, & &1.message)

    # all messages have 'queued' status when inserted and retrieved in desc order
    assert Store.all() == Enum.reverse(Store.queued())
  end

  test "delete message" do
    assert %Message{id: id} = message = Message.build("test") |> Store.insert()

    assert Store.get(id) == message

    assert :ok = Store.delete(id)

    assert {:error, :not_found} = Store.get(id)

    assert {:error, :not_found} = Store.delete(id)
  end

  test "update message" do
    message = Message.build("test") |> Store.insert()

    assert Store.get(message.id) == message

    assert %Message{} = updated_message = Store.update(message.id, message: "updated")

    assert updated_message.id == message.id && updated_message.message == "updated"

    assert {:error, :not_found} = Store.update(100, status: :foo)
  end

  test "mark message as last" do
    message = Message.build("test") |> Store.insert()

    assert %Message{} = new_message = Store.mark_as_last(message.id)

    refute new_message.id == message.id

    assert new_message.message == message.message && new_message.status == message.status
  end
end
