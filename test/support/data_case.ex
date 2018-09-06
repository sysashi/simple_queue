defmodule SQ.DataCase do
  use ExUnit.CaseTemplate

  using do
    quote do
      import SQ.DataCase

      alias SQ.{
        Store, 
        Queue, 
        Message,
        Mnesia.Database
      }
    end
  end

  setup_all do
    Amnesia.Schema.create()
    Amnesia.start()

    on_exit fn -> 
      Amnesia.stop
      Amnesia.Schema.destroy
      :ok
    end

    :ok
  end

  def create_store!() do
    SQ.Mnesia.Database.create!()
  end

  def destroy_store() do
    SQ.Mnesia.Database.destroy
  end
end
