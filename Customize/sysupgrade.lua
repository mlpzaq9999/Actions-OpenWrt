module("luci.model.cbi.gpsysupgrade.api.sysupgrade", package.seeall)
local fs = require "nixio.fs"
local sys = require "luci.sys"
local util = require "luci.util"
local i18n = require "luci.i18n"
local ipkg = require("luci.model.ipkg")
local api = require "luci.model.cbi.gpsysupgrade.api.api"

function get_system_version()
	local system_version = luci.sys.exec("[ -f '/etc/openwrt_info' ] && echo -n `awk 'NR==1' /etc/openwrt_info`")
    return system_version
end

function to_check(model)
    if not model or model == "" then model = api.auto_get_model() end
    
    local download_url,remote_version,needs_update
	local version_file = "/tmp/version.txt"
	local AutoUpdate = "/tmp/AutoUpdate"
	if model == "x86_64" then
		api.exec(api.wget, {api._unpack(api.wget_args), "-O", AutoUpdate, "https://github.com/mlpzaq9998/Actions-OpenWrt/releases/tag/AutoUpdate"}, nil, api.command_timeout)
		luci.sys.exec("cat /tmp/AutoUpdate | egrep -o 'Life.[0-9]+' | awk 'END {print}' > /tmp/version.txt")
		remote_version = luci.sys.exec("[ -f '" ..version_file.. "' ] && echo -n `cat " ..version_file.. "`")
		needs_update = api.compare_versions(get_system_version(), "<", remote_version)
		if fs.access("/sys/firmware/efi") then
			download_url = "https://github.com/mlpzaq9998/Actions-OpenWrt/releases/download/AutoUpdate/AutoBuild-x86_64-OpenWrt-" ..remote_version.. "-efi.img.gz"
		else
			download_url = "https://github.com/mlpzaq9998/Actions-OpenWrt/releases/download/AutoUpdate/AutoBuild-x86_64-OpenWrt-" ..remote_version.. ".img.gz"
		end
	else
		local needs_update = false
		return {
            code = 1,
            error = i18n.translate("Can't determine MODEL, or MODEL not supported.")
			}
	end
	

    if needs_update and not download_url then
        return {
            code = 1,
            now_version = get_system_version(),
            version = remote_version,
            error = i18n.translate(
                "New version found, but failed to get new version download url.")
        }
    end

    return {
        code = 0,
        update = needs_update,
        now_version = get_system_version(),
        version = remote_version,
        url = {download = download_url}
    }
end

function to_download(url)
    if not url or url == "" then
        return {code = 1, error = i18n.translate("Download url is required.")}
    end

    sys.call("/bin/rm -f /tmp/firmware_download.*")

    local tmp_file = util.trim(util.exec("mktemp -u -t firmware_download.XXXXXX"))

    local result = api.exec(api.wget, {api._unpack(api.wget_args), "-O", tmp_file, url}, nil, api.command_timeout) == 0

    if not result then
        api.exec("/bin/rm", {"-f", tmp_file})
        return {
            code = 1,
            error = i18n.translatef("File download failed or timed out: %s", url)
        }
    end

    return {code = 0, file = tmp_file}
end

function to_flash(file)
    if not file or file == "" or not fs.access(file) then
		api.exec("/bin/rm", {"-f", tmp_file})
        return {code = 1, error = i18n.translate("Firmware file is required.")}
    end

    local result = api.exec("/sbin/sysupgrade", {"-k", file}, nil, api.command_timeout) == 0

    if not result or not fs.access(file) then
        api.exec("/bin/rm", {"-f", tmp_file})
        return {
            code = 1,
            error = i18n.translatef("System upgrade failed")
        }
    end

    return {code = 0}
end
