--!strict
--[[
    ════════════════════════════════════════════════════════════════════════════════
    🐱 KittyHub — Code Redemption Helper Module
    Jogo: Anime Breaker
    Padrão Arquitetural: KittyBrain (Reactive Automation & State Management)

    Uso:
        local CodeRedeemerFactory = loadstring(readfile("CodeRedeemer.lua"))()
        local redeemer = CodeRedeemerFactory({
            Remote = Remote,
            GameLib = GameLib,
            Configs = Configs,
            Library = Library,
        })
        redeemer.RedeemAllCodes()
    ════════════════════════════════════════════════════════════════════════════════
]]

return function(ctx)
	ctx = ctx or {}

	local KnownCodes = {
		"Release",
		"5KPLAYERS",
		"5KFAVS",
		"GUILDFIXES",
		"6KCCU",
		"100KVISITS",
		"200KVISITS",
		"300KVISITS",
		"7KCCU",
		"8KCCU",
		"500KVISITS",
		"750KVISITS",
		"10KFAVORITES",
		"NEWTOTEM",
		"2MVISITS",
		"20KFAVORITES",
		"NEWPORTAL",
		"NEWSHADOW",
		"10KCCU",
		"3MVISITS",
		"30KFAVORITES",
		"40KFAVORITES",
		"CLASSTREE",
		"SORRYFORSHUTDOWN",
		"5MVISITS",
		"70KFAVORITES",
		"NEWINVASION",
		"NEWHARBOR",
		"16KCCU",
		"7MVISITS",
		"80KFAVORITES",
		"NEWJEWELS",
		"NEWCRAFT",
		"10MVISITS",
		"90KFAVORITES",
		"NEWGRIMOIRE",
		"TRIALMEDIUM",
		"17KCCU",
		"SORRYFORGRIMS",
		"12MVISITS",
		"100KFAVORITES",
		"NEWTOWER",
		"NEWCOMPANIONS",
		"SORRYFORSHUT",
	}

	local sessionAttemptedCodes: { [string]: boolean } = {}
	local isRedeemingCodes = false

	local function getRemote()
		return ctx.Remote or (ctx.GameLib and ctx.GameLib.Remote)
	end

	local function getGameLib()
		return ctx.GameLib
	end

	local function getConfigs()
		return ctx.Configs or {}
	end

	local function IsCodeClaimed(code: string, claimedTable: any): boolean
		if not claimedTable or type(claimedTable) ~= "table" then
			return false
		end
		if claimedTable[code] then
			return true
		end
		local clean = string.upper((string.gsub(code, "%s+", "")))
		if claimedTable[clean] then
			return true
		end
		local baseClean = string.match(clean, "^(.-)%d*$") or clean
		for k, v in pairs(claimedTable) do
			if v then
				local kStr = string.upper((string.gsub(tostring(k), "%s+", "")))
				if kStr == clean then
					return true
				end
				local baseK = string.match(kStr, "^(.-)%d*$") or kStr
				if baseK == clean or kStr == baseClean or baseK == baseClean then
					return true
				end
			end
		end
		return false
	end

	local function RedeemCode(code: string)
		if not code or code == "" then
			return
		end
		code = string.gsub(code, "%s+", "")
		local remote = getRemote()
		if remote and typeof(remote.Fire) == "function" then
			remote:Fire("CodeSystem", "Use", code)
		end
	end

	local function GetCodesList(): { string }
		local codes: { string } = {}
		pcall(function()
			local configs = getConfigs()
			local gameLib = getGameLib()
			local codeData = configs.CodeData or (gameLib and gameLib.GetData and gameLib:GetData("CodeData"))
			if codeData then
				local list = codeData.Codes or codeData.ActiveCodes or codeData.CodeList or codeData.List
				if type(list) == "table" then
					for k, v in pairs(list) do
						local c = type(v) == "string" and v or (type(k) == "string" and k or nil)
						if c and c ~= "" and not table.find(codes, c) then
							table.insert(codes, c)
						end
					end
				end
			end
		end)

		-- Fallback to KnownCodes if cannot pull from config
		if #codes == 0 then
			for _, code in ipairs(KnownCodes) do
				table.insert(codes, code)
			end
		end
		return codes
	end

	local function HasUnclaimedCodes(): boolean
		local gameLib = getGameLib()
		local pData = gameLib and gameLib.PlayerData
		if not pData or not pData.Codes then
			return false
		end
		local codes = GetCodesList()
		for _, code in ipairs(codes) do
			if not IsCodeClaimed(code, pData.Codes) and not sessionAttemptedCodes[code] then
				return true
			end
		end
		return false
	end

	local function RedeemAllCodes()
		if isRedeemingCodes then
			return
		end
		local gameLib = getGameLib()
		local pData = gameLib and gameLib.PlayerData
		if not pData or not pData.Codes then
			return
		end

		local codes = GetCodesList()
		local hasAny = false
		for _, code in ipairs(codes) do
			if not IsCodeClaimed(code, pData.Codes) and not sessionAttemptedCodes[code] then
				hasAny = true
				break
			end
		end

		if not hasAny then
			return
		end

		isRedeemingCodes = true
		task.spawn(function()
			for _, code in ipairs(codes) do
				local curLib = getGameLib()
				local curData = curLib and curLib.PlayerData
				local claimed = (curData and curData.Codes) or {}
				if not IsCodeClaimed(code, claimed) and not sessionAttemptedCodes[code] then
					sessionAttemptedCodes[code] = true
					RedeemCode(code)
					task.wait(1)
				end
			end
			isRedeemingCodes = false
		end)
	end

	return {
		RedeemAllCodes = RedeemAllCodes,
		HasUnclaimedCodes = HasUnclaimedCodes,
		RedeemCode = RedeemCode,
		GetCodesList = GetCodesList,
		IsCodeClaimed = IsCodeClaimed,
		Codes = KnownCodes,
		KnownCodes = KnownCodes,
		SessionAttemptedCodes = sessionAttemptedCodes,
		IsRedeeming = function()
			return isRedeemingCodes
		end,
		ResetSessionAttempts = function()
			table.clear(sessionAttemptedCodes)
		end,
	}
end
