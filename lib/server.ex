defmodule Server do
    
    def start() do
        spawn(fn -> init end)
    end

    def init do
        db = Database.start
        engines = (for x <- 0..31 do
            {:ok, engine} = Engine.start_link(db)    
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

    defp process({:connect, caller}, engine) do
        id = :rand.uniform(32)
        send caller, {:response, Enum.at(engine, id-1)}
    end

end