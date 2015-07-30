defmodule Extreme.Tools do
  def gen_uuid do
    Keyword.get(UUID.info!(UUID.uuid1()), :binary, :undefined)
  end
end
