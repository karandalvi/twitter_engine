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
  
    def init(seq) do
      {:ok, [seq]}
    end
  
    def handle_cast({:register, userName, userPID}, list) do
      userData = :ets.lookup(:users, userName)
      if userData == [] do
        :ets.insert_new(:users, {userName, []})
        :ets.insert_new(:follows, {userName, %{}})
        :ets.insert_new(:following, {userName, %{}})
        :ets.insert_new(:mentions, {userName, []})
      end
      :ets.insert(:loggedInUsers, {userName, userPID})
      # IO.puts "User Logged In: " <> userName
      {:noreply, list}
    end
  
    def handle_cast({:deregister, userName}, list) do
        :ets.delete(:loggedInUsers, userName)
      # IO.puts "User Logged Out: " <> userName
      {:noreply, list}
    end
  

    def handle_cast({:tweet, userName, tweetMessage}, list) do
        
        tweetID = Sequence.next(hd(list), self)
        if rem(tweetID,10000) == 0 do
          IO.puts "#{:os.system_time(:millisecond)} : #{tweetID}"
        end
        tweetTime = :os.system_time()
        tweet =  [userName, nil, tweetMessage, tweetTime]
        tweetList = :ets.lookup(:tweets, userName)
        if tweetList != [] do
            [{_user, tweetList}] = tweetList
            :ets.insert(:users, {userName, [tweetID | tweetList]})
        else
            :ets.insert(:users, {userName, [tweetID]})
        end
        :ets.insert(:tweets, {tweetID, tweet})
        

        # ---------------------------------------------------------

        hashTags = Regex.scan(~r/#[a-z|A-Z|0-9]*/, tweetMessage)
        for x <- hashTags do
            [tag] = x
            tag = String.replace_leading(tag, "#", "")
            list = :ets.lookup(:hashtags, tag)
            if list == [] do
                :ets.insert(:hashtags, {tag, [tweetID]})
            else
                [{_tagName, tagList}] = list
                :ets.insert(:hashtags, {tag, [tweetID | tagList]})
            end
        end        
        
        # ----------------------------------------------------------

        displayTweet = "#{userName} -> #{tweetMessage}"
        [{_user, pid}] = :ets.lookup(:loggedInUsers, userName)
        Client.displayTweet(pid, displayTweet)
      
        mentionedUsers = Regex.scan(~r/@[a-z|A-Z|0-9|.|_]*/, tweetMessage)
        for x <- mentionedUsers do
            [user] = x
            user = String.replace_leading(user, "@", "")
            mentionList = :ets.lookup(:mentions, user)
            if (mentionList == []) do
                :ets.insert(:mentions, {user, [tweetID]})
            else
                [{_userName, mentionList}] = mentionList
                :ets.insert(:mentions, {user, [tweetID | mentionList]})
            end
            d = :ets.lookup(:loggedInUsers, user)
            if user != userName and d != [] do
                [{_user, pid}] = d
                Client.displayTweet(pid, displayTweet)
            end
        end
        
        # ------------------------------------------------------------

        followers = :ets.lookup(:follows, userName)
        [{_user, followers}] = followers
        for {k, v} <- followers do
            d = :ets.lookup(:loggedInUsers, k)
            if (d != []) do 
                [{_user, pid}] = d
                Client.displayTweet(pid, displayTweet)
            end
        end
        
        {:noreply, list}
    end
  

    def handle_cast({:follow, userName, searchName}, list) do
      if userName != searchName do 
        userData = :ets.lookup(:users, searchName)
        if userData != [] do
          [{_userName, flist}] = :ets.lookup(:follows, searchName)
          :ets.insert(:follows, {searchName, Map.put(flist, userName, nil)})
          [{_userName, flist}] = :ets.lookup(:following, userName)
          :ets.insert(:following, {userName, Map.put(flist, searchName, nil)})
        end
      end
      {:noreply, list}
    end
  


    def handle_cast({:retweet, userName, tweetID}, list) do
      d = :ets.lookup(:tweets, tweetID)
      if (d != []) do
        [{_key, [tOwner, srcTweetID, tweetMessage, _time]}] = d
        if (srcTweetID != nil) do
          tweetID = srcTweetID
        end

        newtweetID = Sequence.next(hd(list), self)
        if rem(newtweetID,10000) == 0 do
          IO.puts "#{:os.system_time(:millisecond)} : #{newtweetID}"
        end
        tweetTime = :os.system_time()
        tweet =  [userName, tweetID, tweetMessage, tweetTime]
        tweetList = :ets.lookup(:tweets, userName)
        if tweetList != [] do
            [{_user, tweetList}] = tweetList
            :ets.insert(:users, {userName, [newtweetID | tweetList]})
        else
            :ets.insert(:users, {userName, [newtweetID]})
        end
        :ets.insert(:tweets, {newtweetID, tweet})

        # ------------------------------------------------------------------------

        hashTags = Regex.scan(~r/#[a-z|A-Z|0-9]*/, tweetMessage)
        for x <- hashTags do
            [tag] = x
            tag = String.replace_leading(tag, "#", "")
            list = :ets.lookup(:hashtags, tag)
            if list == [] do
                :ets.insert(:hashtags, {tag, [tweetID]})
            else
                [{_tagName, tagList}] = list
                :ets.insert(:hashtags, {tag, [tweetID | tagList]})
            end
        end

        # ---------------------------------------------------------------------------

        displayTweet = "#{tOwner} -> #{tweetMessage} [Retweeted by #{userName}]"
        pid = :ets.lookup(:loggedInUsers, userName)
        if pid != [] do
          [{_user, pid}] = pid
          Client.displayTweet(pid, displayTweet)
        end
        
        [{_user, followers}] = :ets.lookup(:follows, userName)
        for {k, v} <- followers do
          pid = :ets.lookup(:loggedInUsers, k)
          if (pid != []) do  
            [{_user, pid}] = pid
            Client.displayTweet(pid, displayTweet)
          end
        end
      end
      {:noreply, list}
    end
  

    def handle_cast({:lookupTag, tagName, caller}, list) do

      tweets = :ets.lookup(:hashtags, tagName)
      if (tweets != []) do
        [{_tagname, tweets}] = tweets
        for each <- tweets do
          [{_tweetID, [tUser, tRT, tMessage, _tTime]}] = :ets.lookup(:tweets, each)
          if tRT != nil do
            [{_tweetID, [tOwner, tRT, tMessage, _tTime]}] = :ets.lookup(:tweets, tRT)
            displayTweet = "#{tOwner} -> #{tMessage} [Retweeted by #{tUser}]"
          else
            displayTweet = "#{tUser} -> #{tMessage}"  
          end
          Client.displayTweet(caller, displayTweet)
        end  
      end
      {:noreply, list}
    end
  

    def handle_cast({:lookupMention, userName, caller}, list) do
      tweets = :ets.lookup(:mentions, userName)
      if tweets != [] do 
        [{_userName, tweets}] = tweets
        for each <- tweets do
          [{_tweetID, [tUser, tRT, tMessage, _tTime]}] = :ets.lookup(:tweets, each)
          if tRT != nil do
            [{_tweetID, [tOwner, tRT, tMessage, _tTime]}] = :ets.lookup(:tweets, tRT)
            displayTweet = "#{tOwner} -> #{tMessage} [Retweeted by #{tUser}]"
          else
            displayTweet = "#{tUser} -> #{tMessage}"  
          end
          Client.displayTweet(caller, displayTweet)
        end
      end
      {:noreply, list}
    end
  
    def handle_cast({:lookupTweet, userName, caller}, list) do
      [{_username, following}] = :ets.lookup(:following, userName)
      h = Heap.max()
      
      h = List.flatten(for {k, v} <- following do
        [{_user, tweets}] = :ets.lookup(:users, k)
        for x <- tweets do
          [{_tweetID, [tUser, tRT, tMessage, tTime]}] = :ets.lookup(:tweets, x)
          if tRT != nil do
            [{_tweetID, [tOwner, tRT, tMessage, _tTime]}] = :ets.lookup(:tweets, tRT)
            displayTweet = "#{tOwner} -> #{tMessage} [Retweeted by #{tUser}]"
          else
            displayTweet = "#{tUser} -> #{tMessage}"  
          end
          {tTime, displayTweet}
        end
      end) |> Enum.into(h)
  
      sendBackTweets(h, caller, 100)
      {:noreply, list}
    end
  
    defp sendBackTweets(h, caller, ttl) do 
      if h.size() > 0 and ttl > 0 do
        {_id, text} = h |> Heap.root()
        Client.displayTweet(caller, text)
        sendBackTweets(h |> Heap.pop(), caller, ttl - 1)  
      end
    end 
  end
  