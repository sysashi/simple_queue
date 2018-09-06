defmodule SQ.QueueTest do
  use SQ.DataCase

  setup_all do
    [values: ~w(foo bar baz)a]
  end

  setup do
    create_store!()

    on_exit fn -> 
      destroy_store()
    end
  end

  setup do
    [queue: start_supervised!(Queue)]
  end

  test "add messages to the queue", c do
    Enum.each(c.values, &(Queue.add(c.queue, &1)))

    Enum.each(c.values, fn val -> 
      assert {_, ^val} = Queue.get(c.queue)
    end)

    assert :empty = Queue.get(c.queue)
  end

  test "make sure messages persist across process restart", c do
    Enum.each(c.values, &(Queue.add(c.queue, &1)))

    Enum.each(c.values, fn val -> 
      assert {_, ^val} = Queue.get(c.queue)
    end)

    assert :empty = Queue.get(c.queue)

    stop_supervised(Queue)

    queue = start_supervised!(Queue)

    Enum.each(c.values, fn val -> 
      assert {_, ^val} = Queue.get(queue)
    end)
  end

  test "rejected messages gets enqueued again", c do
    :ok = Queue.add(c.queue, :foo)
    :ok = Queue.add(c.queue, :bar)

    assert {id, :foo} = Queue.get(c.queue)

    assert {_, :bar} = Queue.get(c.queue)

    assert :empty = Queue.get(c.queue)

    assert :ok = Queue.reject(c.queue, id)

    assert {_, :foo} = Queue.get(c.queue)
  end

  test "acked messages are not persisted", c do
    :ok = Queue.add(c.queue, :foo)

    assert {id, :foo} = Queue.get(c.queue)

    assert :ok = Queue.ack(c.queue, id)

    stop_supervised(Queue)

    queue = start_supervised!(Queue)

    assert :empty = Queue.get(queue)
  end
end
