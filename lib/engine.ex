defmodule Engine do
  @moduledoc """
  Documentation for TwitterEngine.
  """
 use GenServer

  # Client API

  def start_link(dbPID) do
    GenServer.start_link(__MODULE__, dbPID, [])
  end

  def loggedUsers(pid) do
    GenServer.call(pid, {:loggedUsers})
  end

  def register(pid, userName, userPID) do
    GenServer.cast(pid, {:register, userName, userPID})
  end

  def tweet(pid, userName, tweetMessage) do
    GenServer.cast(pid, {:tweet, userName, tweetMessage})
  end

  def retweet(pid, userName, tweetID) do
    GenServer.cast(pid, {:retweet, userName, tweetID})
  end

  def followUser(pid, userName, searchName, sender_id) do
    GenServer.cast(pid, {:follow, userName, searchName})
  end

  def lookupTag(pid, tag, sender_id) do
    GenServer.call(pid, {:lookupTag, tag, sender_id})
  end

  def lookupMention(pid, userName) do
    GenServer.call(pid, {:lookupMention, userName})
  end

  def deregister(pid, userName) do
    GenServer.cast(pid, {:deregister, userName})
  end

  # Server Callbacks

  def init(dbPID) do
    {:ok, [dbPID, %{}]}
  end

  def handle_call({:loggedUsers}, from, list) do
    {:reply, Enum.at(list,1), list}
  end

  def handle_cast({:register, userName, userPID}, list) do
    userData = Database.lookup(Enum.at(list,0), :users, userName, self)
    if userData == [] do
      Database.registerUser(Enum.at(list,0), userName)
    end
    IO.puts "User Logged In: " <> userName
    {:noreply, [Enum.at(list,0), Map.put(Enum.at(list, 1), userName, userPID)]}
  end

  def handle_cast({:deregister, userName}, list) do
    IO.puts "User Logged Out: " <> userName
    {:noreply, [Enum.at(list,0), Map.delete(Enum.at(list, 1), userName)]}
  end

  def handle_cast({:tweet, userName, tweetMessage}, list) do
    Database.insert(Enum.at(list, 0), :tweets, [userName, nil, tweetMessage], self)
    receive do
      {:tweetStored, tweetID, tweet} -> 
        {_id, tweet} = tweet
        tMsg = "#{Enum.at(tweet,0)}: #{Enum.at(tweet,1)}: #{Enum.at(tweet,2)}: #{Enum.at(tweet,3)}"
        mentionedUsers = Regex.scan(~r/@[a-z|A-Z|0-9|.|_]*/, tweetMessage)
        loggedInUsers = Enum.at(list, 1)
        Client.displayTweet(Map.get(loggedInUsers, userName), tMsg)
        for x <- mentionedUsers do
            [user] = x
            user = String.replace_leading(user, "@", "") 
            if (Map.get(loggedInUsers, user) != nil) do  
              Client.displayTweet(Map.get(loggedInUsers, user), tMsg)
            end
        end
        
        followers = Database.lookup(Enum.at(list, 0), :follows, userName, self)
        [{_user, followers}] = followers
        for {k, v} <- followers do
          if (Map.get(loggedInUsers, k) != nil) do  
            Client.displayTweet(Map.get(loggedInUsers, k), tMsg)
          end
        end

    end
    {:noreply, list}
  end

  def handle_cast({:follow, userName, searchName}, list) do
    db = Enum.at(list, 0)
    Database.follow(db, userName, searchName)
    {:noreply, list}
  end

  def handle_cast({:retweet, userName, tweetID}, list) do
    db = Enum.at(list, 0)
    [{_key, [_user, _tweetID, tweetMessage, _time]}] = Database.lookup(db, :tweets, tweetID, self)
    Database.insert(db, :tweets, [userName, tweetID, tweetMessage], self)
    {:noreply, list}
  end

  # def handle_call({:lookup, key, sender_id}, from, list) do
  #   lookupValue = Database.lookup(Enum.at(list, 0), :tweets, key, sender_id)
  #   {:reply, lookupValue, list}
  # end

end
