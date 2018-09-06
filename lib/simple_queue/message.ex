defmodule SQ.Message do
  defstruct [:id, :message, :status]

  @type t :: %SQ.Message{id: non_neg_integer, message: term, status: atom}

  def build(message, status \\ :queued), do: %SQ.Message{message: message, status: status}
end
