defmodule Extreme.MessageEncoder do

	def decode(:pong, data) do 
		data
	end
	

	def encode(:write_events, data) do
		Extreme.Messages.WriteEvents.encode(data)
	end

	def decode(:write_events_completed, data) do 
		Extreme.Messages.WriteEventsCompleted.decode(data)
	end


end
