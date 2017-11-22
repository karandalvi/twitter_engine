defmodule TwitterEngine do
  @moduledoc """
  Documentation for TwitterEngine.
  """
 use GenServer
 
  # Client API
 
  def start_link do
    GenServer.start_link(__MODULE__, :ok, [])
  end
 
  def lookup(pid, key, sender_id) do
    GenServer.call(pid, {:lookup, key, sender_id})
  end
 
  def tweet(pid, userName, tweetMessage) do
    GenServer.cast(pid, {:tweet, userName, tweetMessage})
  end
 
  # Server Callbacks
 
  def init(:ok) do
    {:ok, []}
  end
 
  def handle_call({:lookup, key, sender_id}, from, list) do
    lookupValue = Database.lookup(DBpid, :tweet, key, sender_id)
    {:reply, lookupValue, lookupValue}
  end
 
  def handle_cast({:tweet, userName, tweetMessage}, list) do
    Database.insert(DBpid, :tweet, userName, tweetMessage)
  end
end
