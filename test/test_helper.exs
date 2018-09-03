ExUnit.start()

defmodule TestConn do
  use Extreme, otp_app: :extreme
end

TestConn.start_link()
