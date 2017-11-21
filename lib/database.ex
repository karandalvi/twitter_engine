defmodule Database do
    
    """
    ---------------------------------------------------------------------------
    @author: Karan Dalvi

    This module provides the central database process for our twitter project. 
    It makes use of the Erlang Term Storage (ETS) to provide large data stora-
    ge with constant time lookups.
    ---------------------------------------------------------------------------
    """

    def start do
        spawn(fn -> init() end)
    end

    def init do
        :ets.new(:tweets, [:set, :protected, :named_table])
        :ets.new(:users,  [:set, :protected, :named_table])
        loop()
    end 

    def loop do
        receive do
            message -> process(message)
        end
        loop()
    end

    def insert(pid, table, key, value) do
        send(pid, {:insert, table, key, value})
    end
     
    def insert_new(pid, table, key, value) do
        send(pid, {:insert_new, table, key, value})
    end

    def lookup(pid, table, key, caller) do
        send(pid, {:lookup, table, key, self})
     
        receive do
          {:response, value} -> value
        end
      end

    defp process({:insert, table, key, value}) do
        :ets.insert(table, {key, value})
    end

    defp process({:insert_new, table, key, value}) do
        :ets.insert_new(table, {key, value})
    end

    defp process({:lookup, table, key, caller}) do
        send(caller, {:response, :ets.lookup(table, key)})
    end

end