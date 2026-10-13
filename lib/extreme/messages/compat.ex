defmodule Extreme.Messages.Compat do
  @moduledoc "Keeps exprotobuf's API on the generated messages: `new/0,1`, and iodata in `NewEvent`."

  @behaviour Protobuf.TransformModule

  defmacro __using__(_opts) do
    quote do
      @doc "Builds the message from a keyword list or map of its fields."
      @spec new(fields :: Enumerable.t()) :: struct()
      def new(fields \\ []), do: struct(__MODULE__, fields)

      unquote(_transform(__CALLER__.module))
    end
  end

  @impl Protobuf.TransformModule
  def encode(%{data: data, metadata: metadata} = event, Extreme.Messages.NewEvent),
    do: %{event | data: _to_binary(data), metadata: _to_binary(metadata)}

  @impl Protobuf.TransformModule
  def decode(message, _module), do: message

  defp _transform(Extreme.Messages.NewEvent) do
    quote do
      @impl Protobuf
      def transform_module(), do: unquote(__MODULE__)
    end
  end

  defp _transform(_module), do: nil

  defp _to_binary(iodata) when is_list(iodata), do: IO.iodata_to_binary(iodata)
  defp _to_binary(value), do: value
end
