defmodule Sequence do
    
    """
    ---------------------------------------------------------------------------
    This module provides a sequence number generator.
    ---------------------------------------------------------------------------
    """

    def start do
        spawn(fn -> loop(1) end)
    end

    def loop(seq) do
        receive do
            message -> process(message, seq)    
        end
        loop(seq+1)
    end

    def next(pid, caller) do
        send(pid, {:getNext, caller})
        receive do
          {:response, value} -> value
        end
    end

    def process({:getNext, caller}, seq) do
        send caller, {:response, seq}
    end

end