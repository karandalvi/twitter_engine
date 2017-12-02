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
            {:simulate, size, id, server} ->  action = %{1 => :tweet, 2 => :tweet, 3 => :tweet, 4 => :tweet, 5 => :tweetTag, 
                                      6 => :tweetMention, 7 => :logout, 8 => :lookupMention, 9 => :lookupTag, 10 => :retweet,
                                      11 => :tweet, 12 => :tweet, 13 => :tweet, 14 => :tweet, 15 => :tweetTag}
                            
                                      selected = Map.get(action, :rand.uniform(15))

                            if selected == :tweet do
                                process({:tweet, "a normal tweet"}, state)
                            end

                            if selected == :tweetTag do
                                tags = %{1 => "#monday", 2 => "#UF", 3 => "#gators", 4 => "#florida", 5 => "#holidays",
                                         6 => "#sunday", 7 => "#glades", 8 => "#fossil", 9 => "#lenovo", 10 => "#ps",
                                         11 => "#beatFSU", 12 => "#beatLSU", 13 => "#miamiDiaries", 14 => "#Seattle", 15 => "#FortLauderdale"} 
                                process({:tweet, "a tag tweet " <> Map.get(tags, :rand.uniform(15))}, state)
                            end

                            if selected == :tweetMention do
                                mention = "@client_" <> Integer.to_string(:rand.uniform(size)-1)
                                process({:tweet, "hi whatsup " <> mention}, state)
                            end

                            if selected == :retweet do
                                process({:retweet, :rand.uniform(10000)}, state)
                            end
                            
                            if selected == :lookupTag do
                                tags = %{1 => "#monday", 2 => "#UF", 3 => "#gators", 4 => "#florida", 5 => "#holidays",
                                6 => "#sunday", 7 => "#glades", 8 => "#fossil", 9 => "#lenovo", 10 => "#ps",
                                11 => "#beatFSU", 12 => "#beatLSU", 13 => "#miamiDiaries", 14 => "#Seattle", 15 => "#FortLauderdale"}
                                process({:lookupTag, Map.get(tags, :rand.uniform(15))}, state)
                            end

                            if selected == :lookupMention do
                                username = "@client_" <> Integer.to_string(id)
                                process({:lookupMention, username}, state)
                            end

                            if selected == :logout do
                                process({:deregister}, state)
                                :timer.sleep(:rand.uniform(10) * 1000)
                                process({:login}, state)
                            end


                            r = :rand.uniform(50)
                            i = div(id, round(:math.sqrt(size)))
                            :timer.sleep(500 + (r * i))    
                            send self, {:simulate, size, id, server}
            message -> process(message, state)
        end
        loop(state)
    end

    def connectToServer(pid, serverPID, username) do
        send pid, {:connectToServer, serverPID, username}    
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

    defp process({:connectToServer, serverPID, username}, state) do
        send serverPID, {:connect, self, username}
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

    defp process({:login}, state) do
        username = Enum.at(state, 0)
        e = Enum.at(state, 1)
        Engine.register(e, username, self)
    end
end
