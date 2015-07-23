defmodule Extreme do

	def connect(:node, {ip, port}) when is_integer(port) and port >= 0 and port < 65536 do
		IO.puts "connecting"
	end

	def connect(:cluster, {}) do
		
	end

end

defmodule R do
  def reload! do
    Mix.Task.reenable "compile.elixir"
    Application.stop(Mix.Project.config[:app])
    Mix.Task.run "compile.elixir"
    Application.start(Mix.Project.config[:app], :permanent)
  end
end	