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
                    size = 40000
                    clients = (for x <- 1..size do
                        clientUsername = "client_" <> Integer.to_string(x)  
                        pid = Client.start(clientUsername)
                        Client.connectToServer(pid, s, clientUsername)
                        pid
                    end)

                    for x <- 0..size-1 do
                        followers = div(div(size,2),x+1)
                        if followers > 0 do
                            for y <- size-1..(size-followers) do
                                send Enum.at(clients, y), {:follow, "client_" <> Integer.to_string(x)}
                            end    
                        end
                        send Enum.at(clients, x), {:simulate, size, x, s}
                    end
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
    
    end