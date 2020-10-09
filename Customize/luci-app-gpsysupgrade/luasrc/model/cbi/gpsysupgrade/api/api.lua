module("luci.model.cbi.gpsysupgrade.api.api", package.seeall)
local fs = require "nixio.fs"
local sys = require "luci.sys"
local uci = require"luci.model.uci".cursor()
local util = require "luci.util"

appname = "gpsysupgrade"
curl = "/usr/bin/curl"
curl_args = {"-skL", "--connect-timeout 3", "--retry 3", "-m 60"}
wget = "/usr/bin/wget"
wget_args = {"--quiet", "--timeout=100", "--tries=3"}
command_timeout = 300
LEDE_BOARD = nil
DISTRIB_TARGET = nil


function _unpack(t, i)
    i = i or 1
    if t[i] ~= nil then return t[i], _unpack(t, i + 1) end
end

function exec(cmd, args, writer, timeout)
    local os = require "os"
    local nixio = require "nixio"

    local fdi, fdo = nixio.pipe()
    local pid = nixio.fork()

    if pid > 0 then
        fdo:close()

        if writer or timeout then
            local starttime = os.time()
            while true do
                if timeout and os.difftime(os.time(), starttime) >= timeout then
                    nixio.kill(pid, nixio.const.SIGTERM)
                    return 1
                end

                if writer then
                    local buffer = fdi:read(2048)
                    if buffer and #buffer > 0 then
                        writer(buffer)
                    end
                end

                local wpid, stat, code = nixio.waitpid(pid, "nohang")

                if wpid and stat == "exited" then return code end

                if not writer and timeout then nixio.nanosleep(1) end
            end
        else
            local wpid, stat, code = nixio.waitpid(pid)
            return wpid and stat == "exited" and code
        end
    elseif pid == 0 then
        nixio.dup(fdo, nixio.stdout)
        fdi:close()
        fdo:close()
        nixio.exece(cmd, args, nil)
        nixio.stdout:close()
        os.exit(1)
    end
end

function compare_versions(ver1, comp, ver2)
    local table = table

    local av1 = util.split(ver1, "[%.%-]", nil, true)
    local av2 = util.split(ver2, "[%.%-]", nil, true)

    local max = table.getn(av1)
    local n2 = table.getn(av2)
    if (max < n2) then max = n2 end

    for i = 1, max, 1 do
        local s1 = av1[i] or ""
        local s2 = av2[i] or ""

        if comp == "~=" and (s1 ~= s2) then return true end
        if (comp == "<" or comp == "<=") and (s1 < s2) then return true end
        if (comp == ">" or comp == ">=") and (s1 > s2) then return true end
        if (s1 ~= s2) then return false end
    end

    return not (comp == "<" or comp == ">")
end

function auto_get_model()
    local arch = nixio.uname().machine or ""
    if fs.access("/etc/openwrt_release") then
		if arch == "x86_64" then
		model = "x86_64"
		else
        local boardinfo = luci.util.ubus("system", "board") or { }
		model = boardinfo.model
		end
    end
    return util.trim(model)
end

