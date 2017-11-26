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
        IO.puts message
    end

    defp process({:follow, userName}, state) do
        usr = Enum.at(state, 0)
        e = Enum.at(state, 1)
        Engine.followUser(e, usr, userName, self)
    end

    defp process({:deregister}, state) do
        usr = Enum.at(state, 0)
        e = Enum.at(state, 1)
        Engine.deregister(e, usr)
    end
end