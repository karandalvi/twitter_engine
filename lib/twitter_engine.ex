defmodule Twitter_Engine do
    
    def main(args) do
        if (hd(args) == "server") do
            startServer()
        else
            if (String.downcase(Enum.at(args, 2)) == "alice") do
                startClient(:alice, Enum.at(args, 1), "alice")
            end
            if (String.downcase(Enum.at(args, 2)) == "bob") do
                startClient(:bob, Enum.at(args, 1), "bob")
            end
            if (String.downcase(Enum.at(args, 2)) == "chuck") do
                startClient(:chuck, Enum.at(args, 1), "chuck")
            end
        end
    end

    defp startServer do
        s = Server.start
        IO.inspect s
        {:ok, host} = :inet.gethostname
        {:ok, {a,b,c,d}} = :inet.getaddr(host, :inet)
        a = to_string(a)
        b = to_string(b)
        c = to_string(c)
        d = to_string(d)
        IO.puts inspect "Host IP is : "<>a<>"."<>b<>"."<>c<>"."<>d
        serverIp = a<>"."<>b<>"."<>c<>"."<>d
        Node.start :"server@#{serverIp}" #IP address
        Node.set_cookie :glades221
        :global.register_name(:server, s)
        loop()
    end

    defp startClient(:alice, serverIP, username) do
        IO.puts "Client Simulator Running (Alice)"
        IO.puts "------------------------------------------"
        IO.puts "Alice will attempt to login in 2 seconds"
        :timer.sleep(2000)
        pid = startClient(serverIP, username)
        simulateAlice(pid)
    end

    defp startClient(:bob, serverIP, username) do
        IO.puts "Client Simulator Running (Bob)"
        IO.puts "------------------------------------------"
        IO.puts "Bob will attempt to login in 6 seconds"
        :timer.sleep(4000)
        pid = startClient(serverIP, username)
        simulateBob(pid)
    end

    defp startClient(:chuck, serverIP, username) do
        IO.puts "Client Simulator Running (Chuck)"
        IO.puts "------------------------------------------"
        IO.puts "Chuck will attempt to login in 10 seconds"
        :timer.sleep(4000)
        pid = startClient(serverIP, username)
        simulateChuck(pid)
    end

    defp startClient(serverIP, username) do
        c = Client.start(username)
        IO.inspect c
        ip = "server@" <> serverIP
        {:ok, host} = :inet.gethostname
        {:ok, {w,x,y,z}} = :inet.getaddr(host, :inet)
        w = to_string(w)
        x = to_string(x)
        y = to_string(y)
        z = to_string(z)
        workerIp = w<>"."<>x<>"."<>y<>"."<>z
        Node.start :"#{username}@#{workerIp}" #IP address
        Node.set_cookie :glades221
        Node.connect String.to_atom(ip)
        :global.sync()
        s = :global.whereis_name(:server)
        Client.connectToServer(c, s)
        IO.puts "Connection established to Server"
        IO.puts "Logged in as: @#{username}"
        c
    end

    defp loop() do
        receive do 

        end
        loop()
    end

    defp keepTweeting(c, follow) do
        messages = ["my first tweet", "yolo guys yolo! #hello", "sawaal na", "aee bachi!", "teri @kd "];
        
        if (follow) do
            :timer.sleep(500)
            IO.puts "Following"
            Client.follow(c, "kd")    
        end

        for x <- 0..4 do
            :timer.sleep(2000)
            Client.tweet(c, Enum.at(messages, rem(x, 5)))    
        end
        # Client.logout(c)

        if (follow) do
            :timer.sleep(400)
            IO.puts "Looking Up HashTag #hello"
            Client.lookupTag(c, "hello")    
            IO.puts "Looking up Tweets from people followed"
            :timer.sleep(1000)
            Client.lookupTweets(c)
        end
        
        # :timer.sleep(1000)
        # IO.puts "Looking Up My Mentions"
        # Client.lookupMentiond(c, "kd")    
        loop()
    end

    defp simulateAlice(pid) do
        :timer.sleep(500)
        IO.puts "Simulator: Alice will tweet 15 messages in the next 30 seconds"
        tweets = ["hello world! #twitter", 
                  "I am Alice!", 
                  "Have 2 extra tickets to #coldplay concert!", 
                  "Anyone interested?",
                  "#coldplay is my fav band!",
                  "Meeting old friends tonight",
                  "Looks like I have got followers :)",
                  "#twitter seems interesting! #like",
                  "Hi @bob Long time",
                  "Hi @chuck How are you doing?",
                  "Happy thanksgiving everyone!!",
                  "Bought the PS4 for $199! sweet deal #gaming ",
                  "Merry Christmas everyone!! #holidays",
                  "its cold in new york! ",
                  "happy new year @bob & @chuck !",
                ]
        for x <- 0..14 do
            :timer.sleep(2000)
            Client.tweet(pid, Enum.at(tweets, x))    
        end
        :timer.sleep(10000)
        Client.logout(pid)
    end

    defp simulateBob(pid) do

        :timer.sleep(500)
        Client.follow(pid, "alice")
        IO.puts "Simulator: Bob followed Alice"

        IO.puts "Simulator: Bob will tweet 6 messages in the next 30 seconds"
        tweets = ["new to #twitter Hope this is fun!", 
                  "Ah! I found my friend @alice", 
                  "my fav show is bob the builder #punny",
                  "go gators!!",
                  "Hi @chuck I did not know you are on #twitter",
                  "vacation time!!!!! wooooo"
                ]
        for x <- 0..5 do
            :timer.sleep(5000)
            Client.tweet(pid, Enum.at(tweets, x))    
        end
        Client.retweet(pid, 1)
        :timer.sleep(10000)
        Client.logout(pid)
    end

    defp simulateChuck(pid) do
        :timer.sleep(500)
        Client.follow(pid, "alice")
        Client.follow(pid, "bob")
        IO.puts "Simulator: Chuck is now following Alice & Bob"
        
        IO.puts "Simulator: Chuck will tweet 3 messages in the next 3 seconds"
        tweets = ["hello everyone!", 
        "this is my second tweet", 
        "the weather is nice today"]

        for x <- 0..2 do
            :timer.sleep(1000)
            Client.tweet(pid, Enum.at(tweets, x))
        end
        Client.logout(pid)
        :timer.sleep(100)
        IO.puts "Simulator: Chuck logged out"
        IO.puts "--------------------------------------------------------"
        :timer.sleep(15000)
        Client.connectToServer(pid, :global.whereis_name(:server))
        IO.puts "Simulator: Chuck logged in again"
        IO.puts "Simulator: Chuck fetching tweets from subscribed users"
        Client.lookupTweets(pid)
        :timer.sleep(3000)
        IO.puts "--------------------------------------------------------"
        IO.puts "Simulator: Chuck fetching tweets with hashtag #twitter"
        Client.lookupTag(pid, "twitter")
        :timer.sleep(10000)
        Client.logout(pid)
    end
end