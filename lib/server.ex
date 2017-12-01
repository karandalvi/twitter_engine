defmodule Server do
   
    def start() do
        spawn(fn -> init end)
    end

    def init do
        db = Database.start
        seq = Sequence.start
        engines = (for x <- 0..255 do
            {:ok, engine} = Engine.start_link(seq)    
            engine
        end)
        loop(engines)
    end

    def loop(engine) do
        receive do
            message -> process(message, engine)
        end
        loop(engine)
    end

    defp process({:connect, caller, username}, engine) do
        hash = Base.encode16(:crypto.hash(:sha256, username))
        {:ok, <<id>>} = Base.decode16(String.at(hash,0) <> String.at(hash, 1))
        send caller, {:response, Enum.at(engine, id)}
    end
    
end