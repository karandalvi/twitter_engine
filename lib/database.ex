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
        :ets.new(:hashtags, [:set, :protected, :named_table])
        loop(seq)
    end 

    def loop(seq) do
        receive do
            message -> process(message, seq)
        end
        loop(seq)
    end

    def registerUser(pid, userName) do
        send(pid, {:insert, :users, userName})
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

    def mention(pid, userName, tweetID) do
        send(pid, {:mention, userName, tweetID})
    end

    def follow(pid, followerName, followingName) do
        send(pid, {:follow, followerName, followingName})
    end

    defp process({:insert, :tweets, tweetData, caller}, seq) do
        tweetID = Sequence.next(seq, self)
        tweetTime = :os.system_time()
        [tweetUser, _tweetID, tweetMessage] = tweetData
        [{_userName, tweetList}] = :ets.lookup(:users, tweetUser)
        
        mentionedUsers = Regex.scan(~r/@[a-z|A-Z|0-9|.|_]*/, tweetMessage)
        for x <- mentionedUsers do
            [user] = x
            user = String.replace_leading(user, "@", "")
            m = :ets.lookup(:mentions, user)
            if (m == []) do
                :ets.insert(:mentions, {user, [tweetID]})
            else
                [{_userName, mentionList}] = m 
                :ets.insert(:mentions, {user, [tweetID] ++ mentionList})
            end
            
        end

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
        
        :ets.insert(:tweets, {tweetID, tweetData ++ [tweetTime]})
        :ets.insert(:users, {tweetUser, [tweetID] ++ tweetList})
        send caller, {:tweetStored, tweetID, {tweetID, tweetData ++ [tweetTime]}}
    end

    defp process({:insert, :users, userName}, seq) do
        :ets.insert_new(:users, {userName, []})
        :ets.insert_new(:follows, {userName, %{}})
        :ets.insert_new(:mentions, {userName, []})
    end

    defp process({:lookup, table, key, caller}, _seq) do
        send(caller, {:response, :ets.lookup(table, key)})
    end

    defp process({:mention, userName, tweetID}, seq) do
        [{_userName, tweetList}] = :ets.lookup(:mentions, userName)
        :ets.insert(:mentions, {userName, [tweetID] ++ tweetList})
    end

    defp process({:follow, followerName, followingName}, seq) do
        [{_userName, followList}] = :ets.lookup(:follows, followingName)
        :ets.insert(:follows, {followingName, Map.put(followList, followerName, nil)})
    end
end