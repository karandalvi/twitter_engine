defmodule Simulator do

    def main(args) do
        if(hd(args) == "server") do
            startServer()
        else
            if (String.downcase(Enum.at(args, 2)) == "clients") do
                for x <- 1..10 do
                    startClient(:clients, Enum.at(args, 1), x)
                end
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
        #do nothing 
    else
        #if not Client1, set this client to follow Client1
        Client.follow(pid, "Client1")
        Client.lookupTag(pid, "TryingOutElixir")
    end

    :timer.sleep(500)
    IO.puts "Simulator: #{clientUsername} will tweet 15 messages in the next 30 seconds"
    tweets = ["hello world! #TryingOutElixir - from #{clientUsername}", 
              "I am #{clientUsername}!", 
              "I started using Honor 6x?",
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
    :timer.sleep(10000)
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