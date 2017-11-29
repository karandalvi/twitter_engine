defmodule Simulator do
    
        def main(args) do
            if(hd(args) == "server") do
                startServer()
            else
                if (String.downcase(Enum.at(args, 0)) == "clients") do
                    {:ok, host} = :inet.gethostname
                    {:ok, {w,x,y,z}} = :inet.getaddr(host, :inet)
                    w = to_string(w)
                    x = to_string(x)
                    y = to_string(y)
                    z = to_string(z)
                    workerIp = w<>"."<>x<>"."<>y<>"."<>z
                    Node.start :"client@#{workerIp}" #IP address
                    Node.set_cookie :glades221
                    ip = "server@" <> Enum.at(args, 1)
                    Node.connect String.to_atom(ip)
                    :global.sync()
                    s = :global.whereis_name(:server)
                    size = 25000
                    clients = (for x <- 1..size do
                        clientUsername = "client_" <> Integer.to_string(x)  
                        pid = Client.start(clientUsername)
                        Client.connectToServer(pid, s)
                        send pid, {:keepTweeting, "tweet"}
                        pid
                    end)

                    for x <- 0..size-1 do
                        followers = div(div(size,2),x+1)
                        if followers > 0 do
                            for y <- size-1..(size-followers) do
                                send Enum.at(clients, y), {:follow, "client_" <> Integer.to_string(x)}
                            end    
                        end
                        
                    end

                    # for x <- 1..size-1 do
                    #     followTill = div(size, (size - x)) - 1
                    #     p = Enum.at(clients, x-1)
                    #     if (followTill >= 0) do
                    #         for y <- 0..followTill do
                    #             send p, {:follow, "client_" <> Integer.to_string(y)}
                    #         end        
                    #     end
                        
                    # end
                end
            end
            loop()
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
    
    defp loop() do
        receive do 
    
        end
        loop()
    end
    
    defp startClient(:clients, serverIP, x) do
        id = Integer.to_string(x)
        clientUsername = "Client"<>id
        IO.puts "Client Simulator Running #{clientUsername}"
        IO.puts "------------------------------------------"
        IO.puts "#{clientUsername} will attempt to login in 2 seconds"
        :timer.sleep(2000)
        pid = startClient(serverIP, clientUsername)
        simulateClient(pid, clientUsername)
    end
    
    defp startClient(serverIP, clientUsername) do
        c = Client.start(clientUsername)
        IO.inspect c
        ip = "server@" <> serverIP
        {:ok, host} = :inet.gethostname
        {:ok, {w,x,y,z}} = :inet.getaddr(host, :inet)
        w = to_string(w)
        x = to_string(x)
        y = to_string(y)
        z = to_string(z)
        workerIp = w<>"."<>x<>"."<>y<>"."<>z
        Node.start :"#{clientUsername}@#{workerIp}" #IP address
        Node.set_cookie :glades221
        Node.connect String.to_atom(ip)
        :global.sync()
        s = :global.whereis_name(:server)
        Client.connectToServer(c, s)
        IO.puts "Connection established to Server"
        IO.puts "Logged in as: @#{clientUsername}"
        c
    end
    
    defp simulateClient(pid, clientUsername) do
        if String.equivalent?("Client1", clientUsername) do
            IO.puts "true"
        else
            #if not Client1, set this client to follow "Client1"
            Client.follow(pid, "Client1")
        end
    
        :timer.sleep(500)
        IO.puts "Simulator: #{clientUsername} will tweet 8 messages in the next 30 seconds"
        tweets = ["hello world! #elixir", 
                  "I am #{clientUsername}!", 
                  "I started using Honor 6x!",
                  "Works fine till now. I like it's display",
                  "#twitter seems interesting! #like",
                  "Started using Google Home Mini Too!!",
                  "Tough to choose between echo dot and home mini",
                  "ok bye!",
                ]
        for x <- 0..8 do
            :timer.sleep(2000)
            Client.tweet(pid, Enum.at(tweets, x))    
        end
    
        
        if String.equivalent?("Client2", clientUsername) do
            Client.logout(pid)
            :timer.sleep(100)
            IO.puts "Simulator: #{clientUsername} logged out"
            IO.puts "--------------------------------------------------------"
            :timer.sleep(15000)
            Client.connectToServer(pid, :global.whereis_name(:server))
            IO.puts "Simulator: #{clientUsername} logged in again"
            IO.puts "Simulator: #{clientUsername} fetching tweets from subscribed users"
            Client.lookupTweets(pid)
            :timer.sleep(3000)
            IO.puts "--------------------------------------------------------"
            IO.puts "Simulator: #{clientUsername} fetching tweets with hashtag #twitter"        
        end
    
        Client.lookupTag(pid, "TryingOutElixir")
        :timer.sleep(5000)
        Client.logout(pid)
    end
    
    # defp keepTweeting(c, follow) do
    #     messages = ["my first tweet", "yolo guys yolo! #hello", "sawaal na", "aee bachi!", "teri @kd "];
        
    #     if (follow) do
    #         :timer.sleep(500)
    #         IO.puts "Following"
    #         Client.follow(c, "kd")    
    #     end
    
    #     for x <- 0..4 do
    #         :timer.sleep(2000)
    #         Client.tweet(c, Enum.at(messages, rem(x, 5)))    
    #     end
    #     # Client.logout(c)
    
    #     if (follow) do
    #         :timer.sleep(400)
    #         IO.puts "Looking Up HashTag #hello"
    #         Client.lookupTag(c, "hello")    
    #         IO.puts "Looking up Tweets from people followed"
    #         :timer.sleep(1000)
    #         Client.lookupTweets(c)
    #     end
        
    #     # :timer.sleep(1000)
    #     # IO.puts "Looking Up My Mentions"
    #     # Client.lookupMentiond(c, "kd")    
    #     loop()
    # end
    
    end