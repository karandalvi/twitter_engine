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
        seq = Sequence.start
        :ets.new(:tweets,  [:set, :protected, :named_table])
        :ets.new(:users,   [:set, :protected, :named_table])
        :ets.new(:mentions,[:set, :protected, :named_table])
        :ets.new(:follows, [:set, :protected, :named_table])
        :ets.new(:following, [:set, :protected, :named_table])
        :ets.new(:hashtags, [:set, :protected, :named_table])
        loop(seq)
    end 

    def loop(seq) do
        receive do
            message -> process(message, seq)
        end
        loop(seq)
    end

    # -----------------------------------------------------
    # Client APIs
    # -----------------------------------------------------

    def registerUser(pid, userName) do
        send(pid, {:register, :users, userName})
    end

    def insert(pid, table, value, caller) do
        send(pid, {:insert, table, value, caller})
    end

    def lookup(pid, table, key, caller) do
        send(pid, {:lookup, table, key, self})
        receive do
          {:response, value} -> value
        end
    end

    def tweet(pid, key, caller) do
        send(pid, {:tweet, key, self})
        receive do
          {:tweetCommit, value} -> value
        end
    end

    def mention(pid, userName, tweetID) do
        send(pid, {:mention, userName, tweetID})
    end

    def follow(pid, followerName, followingName) do
        send(pid, {:follow, followerName, followingName})
    end

    # -----------------------------------------------------
    # Server Callback
    # -----------------------------------------------------

    defp process({:register, :users, userName}, seq) do
        :ets.insert_new(:users, {userName, []})
        :ets.insert_new(:follows, {userName, %{}})
        :ets.insert_new(:following, {userName, %{}})
        :ets.insert_new(:mentions, {userName, []})
    end

    defp process({:insert, :mentions, value, caller}, seq) do
        :ets.insert(:mentions, value)    
    end

    defp process({:follow, followerName, followingName}, seq) do
        [{_userName, flist}] = :ets.lookup(:follows, followingName)
        :ets.insert(:follows, {followingName, Map.put(flist, followerName, nil)})
        [{_userName, flist}] = :ets.lookup(:following, followerName)
        :ets.insert(:following, {followerName, Map.put(flist, followingName, nil)})
    end
    
    defp process({:tweet, tweetData, caller}, seq) do
        tweetID = Sequence.next(seq, self)
        tweetTime = :os.system_time()
        [tweetUser, _tweetID, tweetMessage] = tweetData
        [{_userName, tweetList}] = :ets.lookup(:users, tweetUser)
        :ets.insert(:tweets, {tweetID, tweetData ++ [tweetTime]})
        :ets.insert(:users, {tweetUser, [tweetID] ++ tweetList})
        processHashTags(tweetID, tweetMessage)
        send caller, {:tweetCommit, {tweetID, tweetData ++ [tweetTime]}}
    end

    defp processHashTags(tweetID, tweetMessage) do
        hashTags = Regex.scan(~r/#[a-z|A-Z|0-9]*/, tweetMessage)
        for x <- hashTags do
            [tag] = x
            tag = String.replace_leading(tag, "#", "")
            list = :ets.lookup(:hashtags, tag)
            if list == [] do
                :ets.insert(:hashtags, {tag, [tweetID]})
            else
                [{_tagName, tagList}] = list
                :ets.insert(:hashtags, {tag, [tweetID] ++ tagList})
            end
        end        
    end

    defp process({:lookup, table, key, caller}, _seq) do
        send(caller, {:response, :ets.lookup(table, key)})
    end

end