defmodule Extreme.Conn do
	use GenServer

	defmodule State do
		defstruct 	socket: nil, 
					connection_config: { :host, '127.0.0.1', 1113 }, 
				  	settings: %{ 
						heartbeat_timeout: 1000,
						heartbeat_period: 500,
						connection_timout: 2000,
						reconnect_delay: 500,
						max_retries: 10
					}
	end


	def start_link() do
		GenServer.start_link(__MODULE__, %State{})
	end

	def init(state) do
		{:ok, socket} = connect(state.connection_config)
		{:ok, %State{state | socket: socket} }
	end
	@doc """
	Streams binary data to Event Store connection
	"""
	def store(pid, bin) do
		raise "Not Implemented Yet!"
	end
	@doc """
	Reads binary data from eventstore
	"""
	def read(pid, opts\\[]) do
		raise "Not Implemented Yet!"
	end

	defp connect({type, ip , port}) when type == :host do
		opts = [:binary, active: false]
		:gen_tcp.connect(ip, port, opts)
	end
	
	defp connect({type, ip , port}) when type == :gossip do
		raise ":gossip is not yet supported"
	end

	defp connect(cfg) do
		raise "The :#{elem(cfg, 0)} connection type is not supported yet! Please use :host !"
	end

	

	def send_pkg(socket, package) do
	    bin = Extreme.BinSerializer.to_binary(package)
	    pkg_len = byte_size(bin)
	    :gen_tcp.send(socket, <<pkg_len:32/unsigned-little-integer>>)
	    :gen_tcp.send(socket, bin)
	end
end