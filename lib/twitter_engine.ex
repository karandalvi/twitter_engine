defmodule Twitter_Engine do
    
    def main(args) do
        if (hd(args) == "server") do
            startServer()
        else
            startClient(Enum.at(args, 1), Enum.at(args, 2))
        end
    end

    defp startServer do
        s = Server.start
        IO.inspect s
        {:ok, host} = :inet.gethostname
        #host = to_string(host)
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

    defp startClient(serverIP, username) do
        c = Client.start(username)
        IO.inspect c
        ip = "server@" <> serverIP
        # IO.puts inspect
        #Node.start :"worker@172.16.102.76" #IP address
        {:ok, host} = :inet.gethostname
        #host = to_string(host)
        {:ok, {w,x,y,z}} = :inet.getaddr(host, :inet)
        w = to_string(w)
        x = to_string(x)
        y = to_string(y)
        z = to_string(z)
        # IO.puts inspect "Worker IP is : "<>w<>"."<>x<>"."<>y<>"."<>z
        workerIp = w<>"."<>x<>"."<>y<>"."<>z
        Node.start :"#{username}@#{workerIp}" #IP address
        Node.set_cookie :glades221
        # IO.puts Node.self
        # IO.puts inspect
        Node.connect String.to_atom(ip)
        IO.puts "Connection established to server node"
        :global.sync()
        s = :global.whereis_name(:server)
        Client.connectToServer(c, s)
        IO.puts "Connection established to server process"
        # loop()
        keepTweeting(c, username == "shaun")
    end

    defp loop() do
        receive do 

        end
        loop()
    end

    defp keepTweeting(c, follow) do
        messages = ["my first tweet", "yolo guys yolo!", "sawaal na", "aee bachi!", "teri @kd "];
        
        if (follow) do
            :timer.sleep(1000)
            IO.puts "Following"
            Client.follow(c, "kd")    
        end

        for x <- 0..4 do
            :timer.sleep(2000)
            Client.tweet(c, Enum.at(messages, rem(x, 5)))    
        end
        # Client.logout(c)
        loop()
    end
end