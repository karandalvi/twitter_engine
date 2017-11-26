defmodule Server do
    
    def start() do
        spawn(fn -> init end)
    end

    def init do
        db = Database.start
        {:ok, engine} = Engine.start_link(db)
        loop(engine)
    end

    def loop(engine) do
        receive do
            message -> process(message, engine)
        end
        loop(engine)
    end

    defp process({:connect, caller}, engine) do
        send caller, {:response, engine}
    end

end