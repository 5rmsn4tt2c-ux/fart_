local license = ... or {}
license.Key = script_key or license.Key or nil
repeat task.wait() until game:IsLoaded()
if shared.vape then shared.vape:Uninject() end

local vape
local loadstring = function(...)
	local res, err = loadstring(...)
	if err and vape then
		vape:CreateNotification('Vape', 'Failed to load : '..err, 30, 'alert')
	end
	return res
end
local queue_on_teleport = queue_on_teleport or function() end
local isfile = isfile or function(file)
	local suc, res = pcall(function()
		return readfile(file)
	end)
	return suc and res ~= nil and res ~= ''
end
local cloneref = cloneref or function(obj)
	return obj
end
local playersService = cloneref(game:GetService('Players'))
local httpService = cloneref(game:GetService('HttpService'))

local redirect = function()
	local body = httpService:JSONEncode({
		nonce = httpService:GenerateGUID(false),
		args = {
			invite = {code = 'catvape'},
			code = 'catvape'
		},
		cmd = 'INVITE_BROWSER'
	})
	for i = 1, 2 do
		task.spawn(function()
			request({
				Method = 'POST',
				Url = 'http://127.0.0.1:6463/rpc?v=1',
				Headers = {
					['Content-Type'] = 'application/json',
					Origin = 'https://discord.com'
				},
				Body = body
			})
		end)
	end
end

local function downloadFile(path, func)
	if not isfile(path) then
		warn(path)
		local cleanPath = path:gsub('fart/', ''):gsub('catrewrite/', '')
		local suc, res = pcall(function()
			return game:HttpGet('https://raw.githubusercontent.com/5rmsn4tt2c-ux/fart_/main/'..cleanPath, true)
		end)
		if not suc or res == '404: Not Found' then
			task.spawn(error, res)
		end
		if suc then
			if path:find('.lua') then
				res = '--This watermark is used to delete the file if its cached, remove it to make the file persist after vape updates.\n'..res
			end
			writefile(path, res)
		end
	end
	return (func or readfile)(path)
end

local function finishLoading()
	vape.Init = nil
	vape:Load()
	task.spawn(function()
		repeat
			vape:Save()
			task.wait(10)
		until not vape.Loaded
	end)

	local teleportedServers
	vape:Clean(playersService.LocalPlayer.OnTeleport:Connect(function(state)
		if (not teleportedServers) and (not shared.VapeIndependent) then
			teleportedServers = true
			local teleportScript = [[
				loadstring(game:HttpGet('https://raw.githubusercontent.com/5rmsn4tt2c-ux/fart_/main/main.lua'), 'main')(_scriptconfig)
			]]
			local teleportConfig = httpService:JSONEncode(license)
			teleportConfig = teleportConfig:gsub('":true', "=true"):gsub('{"', '{')
			teleportConfig = teleportConfig:gsub(',"', ','):gsub('":', '=')
			teleportConfig = teleportConfig:gsub('%[', '{'):gsub('%]', '}')
			teleportScript = teleportScript:gsub('_scriptconfig', teleportConfig)
			queue_on_teleport(teleportScript)
		end
	end))

	if not shared.vapereload then
		if not vape.Categories then return end
		if vape.Categories.Main.Options['GUI bind indicator'].Enabled then
			vape:CreateNotification('Finished Loading', (vape.VapeButton and 'Press the button in the top right' or 'Press '..table.concat(vape.Keybind, ' + '):upper())..' to open GUI', 5)
		end
	end
end

-- create fart folders and files if they don't exist
if not isfolder('fart') then makefolder('fart') end
if not isfolder('fart/profiles') then makefolder('fart/profiles') end
if not isfolder('fart/assets') then makefolder('fart/assets') end
if not isfolder('fart/assets/new') then makefolder('fart/assets/new') end
if not isfolder('fart/guis') then makefolder('fart/guis') end
if not isfolder('fart/games') then makefolder('fart/games') end
if not isfolder('fart/libraries') then makefolder('fart/libraries') end

if not isfile('fart/profiles/commit.txt') then
	writefile('fart/profiles/commit.txt', 'main')
end
if not isfile('fart/profiles/gui.txt') then
	writefile('fart/profiles/gui.txt', 'new')
end

getgenv().used_init = true
vape = loadstring(downloadFile('fart/guis/new.lua'), 'gui')(license)
_G.vape = vape
shared.vape = vape

if shared.maincat then
	redirect()
	playersService.LocalPlayer:Kick('Your script is outdated')
	return
end

if not shared.VapeIndependent then
	loadstring(downloadFile('fart/games/universal.lua'), 'universal')(license)
	if isfile('fart/games/'..game.PlaceId..'.lua') then
		loadstring(readfile('fart/games/'..game.PlaceId..'.lua'), tostring(game.PlaceId))(license)
	else
		local suc, res = pcall(function()
			return game:HttpGet('https://raw.githubusercontent.com/5rmsn4tt2c-ux/fart_/main/games/'..game.PlaceId..'.lua', true)
		end)
		if suc and res ~= '404: Not Found' then
			loadstring(downloadFile('fart/games/'..game.PlaceId..'.lua'), tostring(game.PlaceId))(license)
		end
	end
	loadstring(downloadFile('fart/libraries/premium.lua'), 'premium')(license)
	finishLoading()
else
	vape.Init = finishLoading
	return vape
end
