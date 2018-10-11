local skynet = require "skynet"
local socket = require "skynet.socket"
local lkcp = require "lkcp"

local floor = math.floor

local next_tick = {}

local function kcp_update(kc, now)
    kc:lkcp_update()
    next_tick[kc] = kc:lkcp_check(now)
end

local function kcp_routine(kc)
    next_tick[kc] = 0
    skynet.fork(function()
        while true do
            local now = floor(skynet.time() * 1000)
            if now >= next_tick[kc] then
                kcp_update(kc, now)
            end
            skynet.sleep(1)
        end
    end)
end

local function server()
    local conn = 1
    local clients = {}
    local host
    local function server_recv(str, from)
		print("server recv", str, socket.udp_address(from))
        local kc = clients[from]
        if kc then
            print("server recv msg", socket.udp_address(from))
            kc:lkcp_input(str)
            local content = kc:lkcp_recv()
            while content do
                print("server recv", content, socket.udp_address(from))
                kc:lkcp_send("OK " .. content)
                content = kc:lkcp_recv()
            end
            next_tick[kc] = 0
        else
            if str == "hello" then
                local curConn = conn
                conn = conn + 1
                local kc = lkcp.lkcp_create(curConn, function(buf)
                    socket.sendto(host, from, buf)
                end)
                kc:lkcp_nodelay(1, 10, 2, 1)
                kcp_routine(kc)
                clients[from] = kc
                socket.sendto(host, from, "conn_" .. curConn)
            end
        end
    end
    host = socket.udp(server_recv, "127.0.0.1", 8765)

	-- local host
	-- host = socket.udp(function(str, from)
	-- 	print("server recv", str, socket.udp_address(from))
	-- 	socket.sendto(host, from, "OK " .. str)
	-- end , "127.0.0.1", 8765)	-- bind an address
end

local function client()
    local c, kc
    local function client_recv(str, from)
        if kc then
            print("client recv msg", socket.udp_address(from))
            kc:lkcp_input(str)
            local content = kc:lkcp_recv()
            while content do
                print("client recv", content, socket.udp_address(from))
                content = kc:lkcp_recv()
            end
            next_tick[kc] = 0
        else
            local conn_str = str:match("conn_(%d+)")
            if conn_str then
                local conn = tonumber(conn_str)
                kc = lkcp.lkcp_create(conn, function(buf)
                    socket.write(c, buf)
                end)
                kc:lkcp_nodelay(1, 10, 2, 1)
                -- kc:lkcp_nodelay(0, 10, 0, 0)
                -- kc:lkcp_nodelay(0, 10, 0, 1)
                kcp_routine(kc)
                for i = 1, 20 do
                    kc:lkcp_send("client msg " .. i)
                end
                next_tick[kc] = 0
            else
                print("error connection:", str)
            end
        end
    end
    c = socket.udp(client_recv)
	socket.udp_connect(c, "127.0.0.1", 8765)
    socket.write(c, "hello")

	-- local c = socket.udp(function(str, from)
	-- 	print("client recv", str, socket.udp_address(from))
	-- end)
	-- socket.udp_connect(c, "127.0.0.1", 8765)
	-- for i=1,20 do
	-- 	socket.write(c, "hello " .. i)	-- write to the address by udp_connect binding
	-- end
end

skynet.start(function()
	skynet.fork(server)
	skynet.fork(client)
	skynet.fork(client)
end)
