defmodule Engine do
  @moduledoc """
  Documentation for TwitterEngine.
  """
 use GenServer

    # -----------------------------------------------------
    # Client APIs
    # -----------------------------------------------------

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

  def followUser(pid, userName, searchName) do
    GenServer.cast(pid, {:follow, userName, searchName})
  end

  def lookupTag(pid, tag, sender_id) do
    GenServer.cast(pid, {:lookupTag, tag, sender_id})
  end

  def lookupMention(pid, userName, sender_id) do
    GenServer.cast(pid, {:lookupMention, userName, sender_id})
  end
  
  def lookupTweets(pid, userName, sender_id) do
    GenServer.cast(pid, {:lookupTweet, userName, sender_id})
  end

  def deregister(pid, userName) do
    GenServer.cast(pid, {:deregister, userName})
  end

   # -----------------------------------------------------
   # Server Callback
   # -----------------------------------------------------

  def init(dbPID) do
    {:ok, [dbPID, %{}]}
  end

  def handle_call({:loggedUsers}, from, list) do
    {:reply, Enum.at(list,1), list}
  end

  def handle_cast({:register, userName, userPID}, list) do
    db = Enum.at(list,0)
    userData = Database.lookup(db, :users, userName, self)
    if userData == [] do
      Database.registerUser(db, userName)
    end
    Database.login(db, userName, userPID)
    IO.puts "User Logged In: " <> userName
    {:noreply, [Enum.at(list,0), Map.put(Enum.at(list, 1), userName, userPID)]}
  end

  def handle_cast({:deregister, userName}, list) do
    Database.logout(Enum.at(list,0), userName)
    IO.puts "User Logged Out: " <> userName
    {:noreply, [Enum.at(list,0), Map.delete(Enum.at(list, 1), userName)]}
  end

  def handle_cast({:tweet, userName, tweetMessage}, list) do
    db = Enum.at(list,0)
    {tweetID, [tUser, tRT, tMessage, tTime]} = Database.tweet(db, [userName, nil, tweetMessage], self)
    displayTweet = "#{tUser} -> #{tMessage}"
    # loggedInUsers = Enum.at(list, 1)
    [{_user, pid}] = Database.lookup(db, :loggedInUsers, tUser, self)
    Client.displayTweet(pid, displayTweet)
    
    mentionedUsers = Regex.scan(~r/@[a-z|A-Z|0-9|.|_]*/, tweetMessage)
    for x <- mentionedUsers do
        [user] = x
        user = String.replace_leading(user, "@", "")
        m = Database.lookup(db, :mentions, user, self)
        if (m == []) do
            Database.insert(db, :mentions, {user, [tweetID]}, self)
        else
            [{_userName, mentionList}] = m 
            Database.insert(db, :mentions, {user, [tweetID] ++ mentionList}, self)
        end
        if user != tUser and Database.lookup(db, :loggedInUsers, user, self) != [] do
          [{_user, pid}] = Database.lookup(db, :loggedInUsers, user, self)
          Client.displayTweet(pid, displayTweet)
        end
    end

    followers = Database.lookup(db, :follows, userName, self)
    [{_user, followers}] = followers
    for {k, v} <- followers do
      if (Database.lookup(db, :loggedInUsers, k, self) != []) do 
        [{_user, pid}] = Database.lookup(db, :loggedInUsers, k, self)
        Client.displayTweet(pid, displayTweet)
      end
    end
    {:noreply, list}
  end

  def handle_cast({:follow, userName, searchName}, list) do
    db = Enum.at(list, 0)
    userData = Database.lookup(db, :users, searchName, self)
    if userData != [] do
      Database.follow(db, userName, searchName)  
    end
    {:noreply, list}
  end

  def handle_cast({:retweet, userName, tweetID}, list) do
    db = Enum.at(list, 0)
    [{_key, [tOwner, srcTweetID, tweetMessage, _time]}] = Database.lookup(db, :tweets, tweetID, self)
    if (srcTweetID != nil) do
      tweetID = srcTweetID
    end
    Database.tweet(db, [userName, tweetID, tweetMessage], self)
    # loggedInUsers = Enum.at(list, 1)
    displayTweet = "#{tOwner} -> #{tweetMessage} [Retweeted by #{userName}]"
    [{_user, pid}] = Database.lookup(db, :loggedInUsers, userName, self)
    Client.displayTweet(pid, displayTweet)

    followers = Database.lookup(db, :follows, userName, self)
    [{_user, followers}] = followers
    for {k, v} <- followers do
      if (Database.lookup(db, :loggedInUsers, k, self) != []) do  
        [{_user, pid}] = Database.lookup(db, :loggedInUsers, k, self)
        Client.displayTweet(pid, displayTweet)
      end
    end
    {:noreply, list}
  end

  def handle_cast({:lookupTag, tagName, caller}, list) do
    db = Enum.at(list,0)
    tweets = Database.lookup(db, :hashtags, tagName, self)
    [{_tagname, tweets}] = tweets
    for each <- tweets do
      [{_tweetID, [tUser, tRT, tMessage, _tTime]}] = Database.lookup(db, :tweets, each, self)
      if tRT != nil do
        [{_tweetID, [tOwner, tRT, tMessage, _tTime]}] = Database.lookup(db, :tweets, tRT, self)
        displayTweet = "#{tOwner} -> #{tMessage} [Retweeted by #{tUser}]"
      else
        displayTweet = "#{tUser} -> #{tMessage}"  
      end
      Client.displayTweet(caller, displayTweet)
    end
    {:noreply, list}
  end

  def handle_cast({:lookupMention, userName, caller}, list) do
    db = Enum.at(list,0)
    tweets = Database.lookup(db, :mentions, userName, self)
    [{_userName, tweets}] = tweets
    for each <- tweets do
      [{_tweetID, [tUser, tRT, tMessage, _tTime]}] = Database.lookup(db, :tweets, each, self)
      if tRT != nil do
        [{_tweetID, [tOwner, tRT, tMessage, _tTime]}] = Database.lookup(db, :tweets, tRT, self)
        displayTweet = "#{tOwner} -> #{tMessage} [Retweeted by #{tUser}]"
      else
        displayTweet = "#{tUser} -> #{tMessage}"  
      end
      Client.displayTweet(caller, displayTweet)
    end
    {:noreply, list}
  end

  def handle_cast({:lookupTweet, userName, caller}, list) do
    db = Enum.at(list, 0)
    [{_username, following}] = Database.lookup(db, :following, userName, self)
    h = Heap.min()
    
    h = List.flatten(for {k, v} <- following do
      [{_user, tweets}] = Database.lookup(db, :users, k, self)
      for x <- tweets do
        [{_tweetID, [tUser, tRT, tMessage, tTime]}] = Database.lookup(db, :tweets, x, self)
        if tRT != nil do
          [{_tweetID, [tOwner, tRT, tMessage, _tTime]}] = Database.lookup(db, :tweets, tRT, self)
          displayTweet = "#{tOwner} -> #{tMessage} [Retweeted by #{tUser}]"
        else
          displayTweet = "#{tUser} -> #{tMessage}"  
        end
        {tTime, displayTweet}
      end
    end) |> Enum.into(h)

    sendBackTweets(h, caller)
    {:noreply, list}
  end

  defp sendBackTweets(h, caller) do 
    if h.size() > 0 do
      {_id, text} = h |> Heap.root()
      Client.displayTweet(caller, text)
      sendBackTweets(h |> Heap.pop(), caller)  
    end
  end 
end
