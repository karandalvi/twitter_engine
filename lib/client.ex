defmodule Client do
    
    def start(username) do
        spawn(fn -> loop([username]) end)
    end

    def loop(state) do
        receive do
            {:engineConnection, pid} -> loop(state ++ [pid])
            {:tweet, tweetMessage} -> process({:tweet, tweetMessage}, state)
            {:displayTweet, tweetMessage} -> process({:displayTweet, tweetMessage}, state)
            {:follow, userName} -> process({:follow, userName}, state)
            {:logout} -> process({:deregister}, state)
            {:keepTweeting, tweetMessage} -> process({:tweet, tweetMessage}, state)
                                             :timer.sleep(:rand.uniform(10) * 1000)
                                             send self, {:keepTweeting, tweetMessage}
            message -> process(message, state)
        end
        loop(state)
    end

    def connectToServer(pid, serverPID) do
        send pid, {:connectToServer, serverPID}    
    end

    def tweet(pid, tweetMessage) do
        send pid, {:tweet, tweetMessage}
    end

    def logout(pid) do
        send pid, {:logout}
    end

    def displayTweet(pid, tweetMessage) do
        send pid, {:displayTweet, tweetMessage}
    end

    def follow(pid, userName) do
        send pid, {:follow, userName}
    end

    def lookupTweets(pid) do
        send pid, {:lookupTweets}
    end

    def lookupTag(pid, tagName) do
        send pid, {:lookupTag, tagName}
    end

    def lookupMention(pid, userName) do
        send pid, {:lookupMention, userName}
    end

    def retweet(pid, tweetID) do
        send pid, {:retweet, tweetID}
    end

    defp process({:connectToServer, serverPID}, state) do
        send serverPID, {:connect, self}
        receive do
            {:response, enginePID} -> 
                send self, {:engineConnection, enginePID}
                Engine.register(enginePID, hd(state), self)
        end
    end

    defp process({:tweet, message}, state) do
        usr = Enum.at(state, 0)
        e = Enum.at(state, 1)
        Engine.tweet(e, usr, message)
    end

    defp process({:displayTweet, message}, state) do
        # IO.puts message
    end

    defp process({:follow, userName}, state) do
        usr = Enum.at(state, 0)
        e = Enum.at(state, 1)
        Engine.followUser(e, usr, userName)
    end

    defp process({:deregister}, state) do
        usr = Enum.at(state, 0)
        e = Enum.at(state, 1)
        Engine.deregister(e, usr)
    end

    defp process({:lookupTag, tagName}, state) do
        e = Enum.at(state, 1)
        Engine.lookupTag(e, tagName, self)
    end

    defp process({:lookupMention, userName}, state) do
        e = Enum.at(state, 1)
        Engine.lookupMention(e, userName, self)
    end

    defp process({:lookupTweets}, state) do
        username = Enum.at(state, 0)
        e = Enum.at(state, 1)
        Engine.lookupTweets(e, username, self)
    end

    defp process({:retweet, tweetID}, state) do
        username = Enum.at(state, 0)
        e = Enum.at(state, 1)
        Engine.retweet(e, username, tweetID)
    end
end
