--!nocheck
--[[
    ═══════════════════════════════════════════════════════════════
    🐱 KittyHub — Anime Breaker: Overview & Dashboard Tab Module
    ═══════════════════════════════════════════════════════════════
    Padrão Arquitetural: KittyBrain (Obsidian Ultra Executive Cyberpunk)
    Módulo desacoplado de Telemetria, Identidade e Ações Rápidas.

    Retorno do Módulo:
        return function(dashTab, ctx)

    Parâmetros:
        dashTab: Objeto da Tab de Dashboard (Obsidian Ultra Tab)
        ctx: {
            Library: any,          -- Instância da Obsidian Ultra Library
            Config: any,           -- Tabela de Configurações Ativas
            Toggles: any,          -- Tabela de Toggles da UI
            uiUtils: any,          -- Utilitários de UI (Tabs.Main, Tabs.Settings, etc.)
            scriptRunToken: any,   -- GUID Token de Execução Ativa
        }
]]

local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local TeleportService = game:GetService("TeleportService")
local Stats = game:GetService("Stats")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
if not LocalPlayer then
	pcall(function()
		if Players:GetPropertyChangedSignal("LocalPlayer") then
			Players:GetPropertyChangedSignal("LocalPlayer"):Wait()
		end
	end)
	LocalPlayer = Players.LocalPlayer
end

return function(dashTab, ctx)
	ctx = ctx or {}
	local KittyGs = (typeof(getgenv) == "function" and getgenv().KittyGs) or _G.KittyGs or {}
	local Library = ctx.Library
	local Config = ctx.Config
	local Toggles = ctx.Toggles
	local uiUtils = ctx.uiUtils or {}
	local scriptRunToken = ctx.scriptRunToken or (KittyGs and KittyGs.RunToken) or _G.AnimeBreakerRunToken
	ctx.scriptRunToken = scriptRunToken

	dashTab = dashTab or (uiUtils.Tabs and uiUtils.Tabs.Dashboard)
	local contentParent = dashTab and dashTab.Sides and dashTab.Sides[1]
	if not contentParent then
		return nil
	end

	-- 1. Configure spacing between vertical layout containers
	local parentListLayout = contentParent:FindFirstChildWhichIsA("UIListLayout")
	if parentListLayout then
		parentListLayout.Padding = UDim.new(0, 8)
	end

	-- 2. Cyberpunk Obsidian Dark executive palette
	local Surface = Color3.fromRGB(20, 19, 30)
	local SurfaceAlt = Color3.fromRGB(24, 22, 36)
	local ChipSurface = Color3.fromRGB(28, 26, 42)
	local Border = Color3.fromRGB(44, 40, 62)
	local ChipBorder = Color3.fromRGB(40, 36, 58)
	local Text = Color3.fromRGB(255, 255, 255)
	local Muted = Color3.fromRGB(148, 163, 184)
	local PinkFocus = Color3.fromRGB(214, 142, 180) -- #D68EB4 Primary Dashboard Highlight
	local PinkNeon = Color3.fromRGB(225, 151, 190) -- Soft Neon Pink
	local DiscordPillBg = Color3.fromRGB(50, 32, 46) -- #32202E
	local StatusOk = Color3.fromRGB(16, 185, 129)
	local WarningYellow = Color3.fromRGB(245, 158, 11)

	local sessionStart = os.time()
	local executorName = (identifyexecutor and identifyexecutor()) or "Real"

	-- 3. createLucideIcon with Obsidian Ultra integration & 16-icon fallback map
	local function createLucideIcon(parent, iconName, size, color)
		local iconLabel = Instance.new("ImageLabel")
		iconLabel.Name = (iconName or "Icon") .. "LucideIcon"
		iconLabel.Size = size or UDim2.fromOffset(13, 13)
		iconLabel.BackgroundTransparency = 1
		iconLabel.ImageColor3 = color or PinkFocus
		local applied = false
		pcall(function()
			if Library and Library.GetCustomIcon and Library.ApplyLucideIcon then
				local iconData = Library:GetCustomIcon(iconName)
				if iconData then
					Library:ApplyLucideIcon(iconLabel, iconData)
					applied = true
				end
			end
		end)
		if not applied then
			local fallbackMap = {
				["clock"] = { url = "rbxassetid://104502745253902", offset = Vector2.new(225, 500) },
				["key"] = { url = "rbxassetid://104502745253902", offset = Vector2.new(850, 200) },
				["timer"] = { url = "rbxassetid://89421818506275", offset = Vector2.new(0, 275) },
				["message-square"] = { url = "rbxassetid://104502745253902", offset = Vector2.new(175, 975) },
				["disc"] = { url = "rbxassetid://104502745253902", offset = Vector2.new(975, 450) },
				["shield-check"] = { url = "rbxassetid://104502745253902", offset = Vector2.new(875, 650) },
				["activity"] = { url = "rbxassetid://104502745253902", offset = Vector2.new(25, 25) },
				["users"] = { url = "rbxassetid://89421818506275", offset = Vector2.new(100, 325) },
				["cpu"] = { url = "rbxassetid://89421818506275", offset = Vector2.new(175, 350) },
				["wifi"] = { url = "rbxassetid://104502745253902", offset = Vector2.new(25, 25) },
				["gauge"] = { url = "rbxassetid://89421818506275", offset = Vector2.new(0, 275) },
				["hard-drive"] = { url = "rbxassetid://104502745253902", offset = Vector2.new(50, 550) },
				["copy"] = { url = "rbxassetid://104502745253902", offset = Vector2.new(275, 900) },
				["check"] = { url = "rbxassetid://104502745253902", offset = Vector2.new(825, 250) },
				["message-circle"] = { url = "rbxassetid://104502745253902", offset = Vector2.new(175, 975) },
				["crown"] = { url = "rbxassetid://104502745253902", offset = Vector2.new(875, 650) },
			}
			local fb = fallbackMap[iconName]
			if fb then
				iconLabel.Image = fb.url
				iconLabel.ImageRectOffset = fb.offset
				iconLabel.ImageRectSize = Vector2.new(24, 24)
			end
		end
		iconLabel.Parent = parent
		return iconLabel
	end

	-- 4. Inspect Luarmor key details
	local function getLuarmorKeyDetails()
		local exp = getgenv and getgenv().key_expires
		local key = (getgenv and getgenv().script_key) or _G.LuarmorKey
		local keyType = "Lifetime / Dev"
		local remainingStr = "Permanent"

		if exp then
			if type(exp) == "number" then
				local remaining = exp - os.time()
				if remaining > 0 then
					keyType = "Premium Key"
					local days = math.floor(remaining / 86400)
					local hours = math.floor((remaining % 86400) / 3600)
					local mins = math.floor((remaining % 3600) / 60)
					if days > 1 then
						remainingStr = string.format("%d days remaining", days)
					elseif days == 1 then
						remainingStr = "1 day remaining"
					elseif hours > 0 then
						remainingStr = string.format("%d hours remaining", hours)
					else
						remainingStr = string.format("%d mins remaining", math.max(1, mins))
					end
				else
					keyType = "Premium Key"
					remainingStr = "Expired"
				end
			else
				remainingStr = tostring(exp)
			end
		elseif key and tostring(key) ~= "" then
			keyType = "Premium Key"
			remainingStr = "Permanent"
		end

		return keyType, remainingStr
	end

	local initKeyType, initKeyRemaining = getLuarmorKeyDetails()

	-- 5. Executive Header (68px)
	local headerFrame = Instance.new("Frame")
	headerFrame.Name = "ExecutiveHeader"
	headerFrame.BackgroundColor3 = Surface
	headerFrame.BorderSizePixel = 0
	headerFrame.Size = UDim2.new(1, 0, 0, 68)
	headerFrame.LayoutOrder = 1
	headerFrame.ClipsDescendants = true
	headerFrame.Parent = contentParent

	local headerCorner = Instance.new("UICorner")
	headerCorner.CornerRadius = UDim.new(0, 8)
	headerCorner.Parent = headerFrame

	local headerStroke = Instance.new("UIStroke")
	headerStroke.Color = Border
	headerStroke.Thickness = 1
	headerStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	headerStroke.Parent = headerFrame

	local headerPad = Instance.new("UIPadding")
	headerPad.PaddingLeft = UDim.new(0, 12)
	headerPad.PaddingRight = UDim.new(0, 14)
	headerPad.PaddingTop = UDim.new(0, 11)
	headerPad.PaddingBottom = UDim.new(0, 11)
	headerPad.Parent = headerFrame

	-- Player Avatar (46x46px, UICorner 8px, UIStroke PinkFocus 1.5px)
	local playerAvatar = Instance.new("ImageLabel")
	playerAvatar.Name = "PlayerAvatar"
	playerAvatar.BackgroundColor3 = SurfaceAlt
	playerAvatar.BorderSizePixel = 0
	playerAvatar.Position = UDim2.fromOffset(0, 0)
	playerAvatar.Size = UDim2.fromOffset(46, 46)
	local userId = (LocalPlayer and LocalPlayer.UserId) or 0
	playerAvatar.Image = "rbxthumb://type=AvatarHeadShot&id=" .. tostring(userId) .. "&w=150&h=150"
	playerAvatar.Parent = headerFrame

	local avatarCorner = Instance.new("UICorner")
	avatarCorner.CornerRadius = UDim.new(0, 8)
	avatarCorner.Parent = playerAvatar

	local avatarStroke = Instance.new("UIStroke")
	avatarStroke.Color = PinkFocus
	avatarStroke.Thickness = 1.5
	avatarStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	avatarStroke.Parent = playerAvatar

	-- Player Identity Container (Clean: DisplayName + @Username only)
	local playerInfo = Instance.new("Frame")
	playerInfo.Name = "PlayerInfo"
	playerInfo.BackgroundTransparency = 1
	playerInfo.Position = UDim2.fromOffset(56, 0)
	playerInfo.Size = UDim2.new(0.5, -56, 1, 0)
	playerInfo.Parent = headerFrame

	local playerDisplayName = Instance.new("TextLabel")
	playerDisplayName.Name = "DisplayName"
	playerDisplayName.BackgroundTransparency = 1
	playerDisplayName.Position = UDim2.fromOffset(0, 2)
	playerDisplayName.Size = UDim2.new(1, 0, 0, 18)
	playerDisplayName.Font = Enum.Font.GothamBold
	playerDisplayName.Text = (LocalPlayer and LocalPlayer.DisplayName) or "Player"
	playerDisplayName.TextColor3 = Text
	playerDisplayName.TextSize = 14
	playerDisplayName.TextXAlignment = Enum.TextXAlignment.Left
	playerDisplayName.TextTruncate = Enum.TextTruncate.AtEnd
	playerDisplayName.Parent = playerInfo

	local playerUsername = Instance.new("TextLabel")
	playerUsername.Name = "Username"
	playerUsername.BackgroundTransparency = 1
	playerUsername.Position = UDim2.fromOffset(0, 24)
	playerUsername.Size = UDim2.new(1, 0, 0, 16)
	playerUsername.Font = Enum.Font.Gotham
	playerUsername.Text = "@" .. ((LocalPlayer and LocalPlayer.Name) or "Player")
	playerUsername.TextColor3 = Muted
	playerUsername.TextSize = 11
	playerUsername.TextXAlignment = Enum.TextXAlignment.Left
	playerUsername.TextTruncate = Enum.TextTruncate.AtEnd
	playerUsername.Parent = playerInfo

	-- Right Side of Header (Game Title, Server Version & Game Icon)
	local headerRight = Instance.new("Frame")
	headerRight.Name = "HeaderRight"
	headerRight.BackgroundTransparency = 1
	headerRight.AnchorPoint = Vector2.new(1, 0)
	headerRight.Position = UDim2.new(1, 0, 0, 0)
	headerRight.Size = UDim2.new(0.5, 0, 1, 0)
	headerRight.Parent = headerFrame

	local gameIcon = Instance.new("ImageLabel")
	gameIcon.Name = "GameIcon"
	gameIcon.BackgroundColor3 = SurfaceAlt
	gameIcon.BorderSizePixel = 0
	gameIcon.AnchorPoint = Vector2.new(1, 0)
	gameIcon.Position = UDim2.new(1, 0, 0, 0)
	gameIcon.Size = UDim2.fromOffset(46, 46)
	gameIcon.Image = "rbxthumb://type=GameIcon&id=" .. tostring(game.PlaceId) .. "&w=150&h=150"
	gameIcon.Parent = headerRight

	local gameIconCorner = Instance.new("UICorner")
	gameIconCorner.CornerRadius = UDim.new(0, 8)
	gameIconCorner.Parent = gameIcon

	local gameIconStroke = Instance.new("UIStroke")
	gameIconStroke.Color = PinkFocus
	gameIconStroke.Thickness = 1.5
	gameIconStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	gameIconStroke.Parent = gameIcon

	task.spawn(function()
		pcall(function()
			local info = MarketplaceService:GetProductInfo(game.PlaceId)
			if info and info.IconImageAssetId and info.IconImageAssetId > 0 then
				gameIcon.Image = "rbxassetid://" .. tostring(info.IconImageAssetId)
			end
		end)
	end)

	local gameInfo = Instance.new("Frame")
	gameInfo.Name = "GameInfo"
	gameInfo.BackgroundTransparency = 1
	gameInfo.AnchorPoint = Vector2.new(1, 0)
	gameInfo.Position = UDim2.new(1, -56, 0, 0)
	gameInfo.Size = UDim2.new(1, -56, 1, 0)
	gameInfo.Parent = headerRight

	local gameTitle = Instance.new("TextLabel")
	gameTitle.Name = "GameTitle"
	gameTitle.BackgroundTransparency = 1
	gameTitle.Position = UDim2.fromOffset(0, 2)
	gameTitle.Size = UDim2.new(1, 0, 0, 18)
	gameTitle.Font = Enum.Font.GothamBold
	gameTitle.Text = "Anime Breaker"
	gameTitle.TextColor3 = Text
	gameTitle.TextSize = 15
	gameTitle.TextXAlignment = Enum.TextXAlignment.Right
	gameTitle.TextTruncate = Enum.TextTruncate.AtEnd
	gameTitle.Parent = gameInfo

	local serverVersion = Instance.new("TextLabel")
	serverVersion.Name = "ServerVersion"
	serverVersion.BackgroundTransparency = 1
	serverVersion.Position = UDim2.fromOffset(0, 24)
	serverVersion.Size = UDim2.new(1, 0, 0, 16)
	serverVersion.Font = Enum.Font.Gotham
	serverVersion.Text = "Server Version: v" .. tostring(game.PlaceVersion)
	serverVersion.TextColor3 = Muted
	serverVersion.TextSize = 11
	serverVersion.TextXAlignment = Enum.TextXAlignment.Right
	serverVersion.TextTruncate = Enum.TextTruncate.AtEnd
	serverVersion.Parent = gameInfo

	-- 6. Central 2x2 Cards Grid (78px height each)
	local cardsGrid = Instance.new("Frame")
	cardsGrid.Name = "CardsGrid"
	cardsGrid.BackgroundTransparency = 1
	cardsGrid.Size = UDim2.new(1, 0, 0, 166)
	cardsGrid.LayoutOrder = 2
	cardsGrid.Parent = contentParent

	local gridLayout = Instance.new("UIGridLayout")
	gridLayout.CellSize = UDim2.new(0.5, -5, 0, 78)
	gridLayout.CellPadding = UDim2.fromOffset(10, 10)
	gridLayout.SortOrder = Enum.SortOrder.LayoutOrder
	gridLayout.Parent = cardsGrid

	local function createBaseCard(name, order)
		local card = Instance.new("Frame")
		card.Name = name
		card.BackgroundColor3 = Surface
		card.BorderSizePixel = 0
		card.LayoutOrder = order
		card.ClipsDescendants = true
		card.Parent = cardsGrid

		local cCorner = Instance.new("UICorner")
		cCorner.CornerRadius = UDim.new(0, 8)
		cCorner.Parent = card

		local cStroke = Instance.new("UIStroke")
		cStroke.Color = Border
		cStroke.Thickness = 1
		cStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		cStroke.Parent = card

		local cPad = Instance.new("UIPadding")
		cPad.PaddingLeft = UDim.new(0, 12)
		cPad.PaddingRight = UDim.new(0, 12)
		cPad.PaddingTop = UDim.new(0, 10)
		cPad.PaddingBottom = UDim.new(0, 10)
		cPad.Parent = card

		local cLayout = Instance.new("UIListLayout")
		cLayout.FillDirection = Enum.FillDirection.Vertical
		cLayout.SortOrder = Enum.SortOrder.LayoutOrder
		cLayout.Padding = UDim.new(0, 2)
		cLayout.Parent = card

		return card
	end

	-- Card 1 (Top-Left): SESSION TIME
	local cardSession = createBaseCard("SessionTimeCard", 1)

	local headerSess = Instance.new("Frame")
	headerSess.Name = "HeaderRow"
	headerSess.BackgroundTransparency = 1
	headerSess.Size = UDim2.new(1, 0, 0, 14)
	headerSess.LayoutOrder = 1
	headerSess.Parent = cardSession

	local hsLayout = Instance.new("UIListLayout")
	hsLayout.FillDirection = Enum.FillDirection.Horizontal
	hsLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	hsLayout.SortOrder = Enum.SortOrder.LayoutOrder
	hsLayout.Padding = UDim.new(0, 5)
	hsLayout.Parent = headerSess

	createLucideIcon(headerSess, "clock", UDim2.fromOffset(12, 12), PinkFocus)

	local hsTitle = Instance.new("TextLabel")
	hsTitle.Name = "Title"
	hsTitle.BackgroundTransparency = 1
	hsTitle.Font = Enum.Font.GothamBold
	hsTitle.Text = "SESSION TIME"
	hsTitle.TextColor3 = PinkFocus
	hsTitle.TextSize = 10
	hsTitle.AutomaticSize = Enum.AutomaticSize.X
	hsTitle.Parent = headerSess

	local sessionValLabel = Instance.new("TextLabel")
	sessionValLabel.Name = "ValueLabel"
	sessionValLabel.BackgroundTransparency = 1
	sessionValLabel.Size = UDim2.new(1, 0, 0, 24)
	sessionValLabel.LayoutOrder = 2
	sessionValLabel.Font = Enum.Font.GothamBold
	sessionValLabel.Text = "00:00:00"
	sessionValLabel.TextColor3 = Text
	sessionValLabel.TextSize = 18
	sessionValLabel.TextXAlignment = Enum.TextXAlignment.Left
	sessionValLabel.Parent = cardSession

	local sessionSub = Instance.new("TextLabel")
	sessionSub.Name = "Subtitle"
	sessionSub.BackgroundTransparency = 1
	sessionSub.Size = UDim2.new(1, 0, 0, 14)
	sessionSub.LayoutOrder = 3
	sessionSub.Font = Enum.Font.Gotham
	sessionSub.Text = "Active session runtime"
	sessionSub.TextColor3 = Muted
	sessionSub.TextSize = 10
	sessionSub.TextXAlignment = Enum.TextXAlignment.Left
	sessionSub.Parent = cardSession

	-- Card 2 (Top-Right): KEY TYPE
	local cardKeyType = createBaseCard("KeyTypeCard", 2)

	local headerKey = Instance.new("Frame")
	headerKey.Name = "HeaderRow"
	headerKey.BackgroundTransparency = 1
	headerKey.Size = UDim2.new(1, 0, 0, 14)
	headerKey.LayoutOrder = 1
	headerKey.Parent = cardKeyType

	local hkLayout = Instance.new("UIListLayout")
	hkLayout.FillDirection = Enum.FillDirection.Horizontal
	hkLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	hkLayout.SortOrder = Enum.SortOrder.LayoutOrder
	hkLayout.Padding = UDim.new(0, 5)
	hkLayout.Parent = headerKey

	createLucideIcon(headerKey, "key", UDim2.fromOffset(12, 12), PinkFocus)

	local hkTitle = Instance.new("TextLabel")
	hkTitle.Name = "Title"
	hkTitle.BackgroundTransparency = 1
	hkTitle.Font = Enum.Font.GothamBold
	hkTitle.Text = "KEY TYPE"
	hkTitle.TextColor3 = PinkFocus
	hkTitle.TextSize = 10
	hkTitle.AutomaticSize = Enum.AutomaticSize.X
	hkTitle.Parent = headerKey

	local keyTypeValLabel = Instance.new("TextLabel")
	keyTypeValLabel.Name = "ValueLabel"
	keyTypeValLabel.BackgroundTransparency = 1
	keyTypeValLabel.Size = UDim2.new(1, 0, 0, 24)
	keyTypeValLabel.LayoutOrder = 2
	keyTypeValLabel.Font = Enum.Font.GothamBold
	keyTypeValLabel.Text = initKeyType
	keyTypeValLabel.TextColor3 = Text
	keyTypeValLabel.TextSize = 18
	keyTypeValLabel.TextXAlignment = Enum.TextXAlignment.Left
	keyTypeValLabel.Parent = cardKeyType

	local keyTypeSub = Instance.new("TextLabel")
	keyTypeSub.Name = "Subtitle"
	keyTypeSub.BackgroundTransparency = 1
	keyTypeSub.Size = UDim2.new(1, 0, 0, 14)
	keyTypeSub.LayoutOrder = 3
	keyTypeSub.Font = Enum.Font.Gotham
	keyTypeSub.Text = "Luarmor authenticated license"
	keyTypeSub.TextColor3 = Muted
	keyTypeSub.TextSize = 10
	keyTypeSub.TextXAlignment = Enum.TextXAlignment.Left
	keyTypeSub.Parent = cardKeyType

	-- Card 3 (Bottom-Left): KEY EXPIRATION
	local cardKeyExp = createBaseCard("KeyExpCard", 3)

	local headerExp = Instance.new("Frame")
	headerExp.Name = "HeaderRow"
	headerExp.BackgroundTransparency = 1
	headerExp.Size = UDim2.new(1, 0, 0, 14)
	headerExp.LayoutOrder = 1
	headerExp.Parent = cardKeyExp

	local heLayout = Instance.new("UIListLayout")
	heLayout.FillDirection = Enum.FillDirection.Horizontal
	heLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	heLayout.SortOrder = Enum.SortOrder.LayoutOrder
	heLayout.Padding = UDim.new(0, 5)
	heLayout.Parent = headerExp

	createLucideIcon(headerExp, "timer", UDim2.fromOffset(12, 12), PinkFocus)

	local heTitle = Instance.new("TextLabel")
	heTitle.Name = "Title"
	heTitle.BackgroundTransparency = 1
	heTitle.Font = Enum.Font.GothamBold
	heTitle.Text = "KEY EXPIRATION"
	heTitle.TextColor3 = PinkFocus
	heTitle.TextSize = 10
	heTitle.AutomaticSize = Enum.AutomaticSize.X
	heTitle.Parent = headerExp

	local keyExpValLabel = Instance.new("TextLabel")
	keyExpValLabel.Name = "ValueLabel"
	keyExpValLabel.BackgroundTransparency = 1
	keyExpValLabel.Size = UDim2.new(1, 0, 0, 24)
	keyExpValLabel.LayoutOrder = 2
	keyExpValLabel.Font = Enum.Font.GothamBold
	keyExpValLabel.Text = initKeyRemaining
	keyExpValLabel.TextColor3 = Text
	keyExpValLabel.TextSize = 18
	keyExpValLabel.TextXAlignment = Enum.TextXAlignment.Left
	keyExpValLabel.Parent = cardKeyExp

	local subKeyExp = Instance.new("Frame")
	subKeyExp.Name = "SubtitleRow"
	subKeyExp.BackgroundTransparency = 1
	subKeyExp.Size = UDim2.new(1, 0, 0, 14)
	subKeyExp.LayoutOrder = 3
	subKeyExp.Parent = cardKeyExp

	local seLayout = Instance.new("UIListLayout")
	seLayout.FillDirection = Enum.FillDirection.Horizontal
	seLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	seLayout.SortOrder = Enum.SortOrder.LayoutOrder
	seLayout.Padding = UDim.new(0, 5)
	seLayout.Parent = subKeyExp

	local expDot = Instance.new("Frame")
	expDot.Name = "StatusDot"
	expDot.BackgroundColor3 = StatusOk
	expDot.BorderSizePixel = 0
	expDot.Size = UDim2.fromOffset(5, 5)
	expDot.LayoutOrder = 1
	expDot.Parent = subKeyExp

	local edCorner = Instance.new("UICorner")
	edCorner.CornerRadius = UDim.new(1, 0)
	edCorner.Parent = expDot

	local expStatusText = Instance.new("TextLabel")
	expStatusText.Name = "StatusText"
	expStatusText.BackgroundTransparency = 1
	expStatusText.Font = Enum.Font.GothamMedium
	expStatusText.Text = "Active"
	expStatusText.TextColor3 = StatusOk
	expStatusText.TextSize = 10
	expStatusText.AutomaticSize = Enum.AutomaticSize.X
	expStatusText.LayoutOrder = 2
	expStatusText.Parent = subKeyExp

	-- Card 4 (Bottom-Right): SCRIPT DISCORD
	local cardDiscord = createBaseCard("DiscordCard", 4)
	local dCardLayout = cardDiscord:FindFirstChildWhichIsA("UIListLayout")
	if dCardLayout then
		dCardLayout.Padding = UDim.new(0, 4)
	end

	local headerDisc = Instance.new("Frame")
	headerDisc.Name = "HeaderRow"
	headerDisc.BackgroundTransparency = 1
	headerDisc.Size = UDim2.new(1, 0, 0, 14)
	headerDisc.LayoutOrder = 1
	headerDisc.Parent = cardDiscord

	local hdLayout = Instance.new("UIListLayout")
	hdLayout.FillDirection = Enum.FillDirection.Horizontal
	hdLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	hdLayout.SortOrder = Enum.SortOrder.LayoutOrder
	hdLayout.Padding = UDim.new(0, 5)
	hdLayout.Parent = headerDisc

	createLucideIcon(headerDisc, "message-square", UDim2.fromOffset(12, 12), PinkFocus)

	local hdTitle = Instance.new("TextLabel")
	hdTitle.Name = "Title"
	hdTitle.BackgroundTransparency = 1
	hdTitle.Font = Enum.Font.GothamBold
	hdTitle.Text = "SCRIPT DISCORD"
	hdTitle.TextColor3 = PinkFocus
	hdTitle.TextSize = 10
	hdTitle.AutomaticSize = Enum.AutomaticSize.X
	hdTitle.Parent = headerDisc

	local discordBtn = Instance.new("TextButton")
	discordBtn.Name = "DiscordBtn"
	discordBtn.BackgroundColor3 = Color3.fromRGB(28, 26, 42) -- #1C1A2A
	discordBtn.BorderSizePixel = 0
	discordBtn.Size = UDim2.new(1, 0, 0, 34)
	discordBtn.LayoutOrder = 2
	discordBtn.Text = ""
	discordBtn.AutoButtonColor = false
	discordBtn.ClipsDescendants = true
	discordBtn.Parent = cardDiscord

	local dbCorner = Instance.new("UICorner")
	dbCorner.CornerRadius = UDim.new(0, 6)
	dbCorner.Parent = discordBtn

	local dbStroke = Instance.new("UIStroke")
	dbStroke.Color = Color3.fromRGB(46, 42, 66) -- #2E2A42
	dbStroke.Thickness = 1
	dbStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	dbStroke.Parent = discordBtn

	local discordLeft = Instance.new("Frame")
	discordLeft.Name = "LeftContainer"
	discordLeft.BackgroundTransparency = 1
	discordLeft.Position = UDim2.fromOffset(8, 0)
	discordLeft.Size = UDim2.new(1, -84, 1, 0)
	discordLeft.Parent = discordBtn

	local dlLayout = Instance.new("UIListLayout")
	dlLayout.FillDirection = Enum.FillDirection.Horizontal
	dlLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	dlLayout.SortOrder = Enum.SortOrder.LayoutOrder
	dlLayout.Padding = UDim.new(0, 6)
	dlLayout.Parent = discordLeft

	createLucideIcon(discordLeft, "disc", UDim2.fromOffset(13, 13), PinkFocus)

	local discordUrlText = Instance.new("TextLabel")
	discordUrlText.Name = "UrlText"
	discordUrlText.BackgroundTransparency = 1
	discordUrlText.Font = Enum.Font.GothamMedium
	discordUrlText.Text = "discord.gg/wcprsvmcp8"
	discordUrlText.TextColor3 = Color3.fromRGB(226, 232, 240) -- #E2E8F0
	discordUrlText.TextSize = 11
	discordUrlText.TextTruncate = Enum.TextTruncate.AtEnd
	discordUrlText.AutomaticSize = Enum.AutomaticSize.X
	discordUrlText.Parent = discordLeft

	local copyPill = Instance.new("Frame")
	copyPill.Name = "CopyPill"
	copyPill.BackgroundColor3 = DiscordPillBg -- #32202E
	copyPill.BorderSizePixel = 0
	copyPill.AnchorPoint = Vector2.new(1, 0.5)
	copyPill.Position = UDim2.new(1, -8, 0.5, 0)
	copyPill.Size = UDim2.new(0, 0, 0, 22)
	copyPill.AutomaticSize = Enum.AutomaticSize.X
	copyPill.Parent = discordBtn

	local cpCorner = Instance.new("UICorner")
	cpCorner.CornerRadius = UDim.new(0, 4)
	cpCorner.Parent = copyPill

	local cpStroke = Instance.new("UIStroke")
	cpStroke.Color = PinkFocus -- #D68EB4
	cpStroke.Thickness = 1
	cpStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	cpStroke.Parent = copyPill

	local cpPad = Instance.new("UIPadding")
	cpPad.PaddingLeft = UDim.new(0, 8)
	cpPad.PaddingRight = UDim.new(0, 8)
	cpPad.Parent = copyPill

	local pillText = Instance.new("TextLabel")
	pillText.Name = "PillText"
	pillText.BackgroundTransparency = 1
	pillText.Font = Enum.Font.GothamBold
	pillText.Text = "Copy Link"
	pillText.TextColor3 = PinkFocus
	pillText.TextSize = 10
	pillText.AutomaticSize = Enum.AutomaticSize.X
	pillText.Size = UDim2.new(0, 0, 1, 0)
	pillText.Parent = copyPill

	local isCopyingDiscord = false
	discordBtn.MouseEnter:Connect(function()
		discordBtn.BackgroundColor3 = Color3.fromRGB(38, 34, 56) -- #262238
	end)
	discordBtn.MouseLeave:Connect(function()
		discordBtn.BackgroundColor3 = Color3.fromRGB(28, 26, 42) -- #1C1A2A
	end)

	discordBtn.MouseButton1Click:Connect(function()
		if isCopyingDiscord then
			return
		end
		isCopyingDiscord = true
		pcall(function()
			local link = "https://discord.gg/wcprsvmcp8"
			if setclipboard then
				setclipboard(link)
			elseif toclipboard then
				toclipboard(link)
			end
		end)
		pillText.Text = "Copied!"
		pillText.TextColor3 = StatusOk
		cpStroke.Color = StatusOk
		task.delay(2, function()
			if pillText and pillText.Parent then
				pillText.Text = "Copy Link"
				pillText.TextColor3 = PinkFocus
				cpStroke.Color = PinkFocus
				isCopyingDiscord = false
			end
		end)
	end)

	-- 7. System Telemetry Card (58px)
	local telemetryCard = Instance.new("Frame")
	telemetryCard.Name = "TelemetryCard"
	telemetryCard.BackgroundColor3 = Surface
	telemetryCard.BorderSizePixel = 0
	telemetryCard.Size = UDim2.new(1, 0, 0, 58)
	telemetryCard.LayoutOrder = 3
	telemetryCard.ClipsDescendants = true
	telemetryCard.Parent = contentParent

	local tcCorner = Instance.new("UICorner")
	tcCorner.CornerRadius = UDim.new(0, 8)
	tcCorner.Parent = telemetryCard

	local tcStroke = Instance.new("UIStroke")
	tcStroke.Color = Border
	tcStroke.Thickness = 1
	tcStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	tcStroke.Parent = telemetryCard

	local tcPad = Instance.new("UIPadding")
	tcPad.PaddingLeft = UDim.new(0, 12)
	tcPad.PaddingRight = UDim.new(0, 12)
	tcPad.PaddingTop = UDim.new(0, 8)
	tcPad.PaddingBottom = UDim.new(0, 8)
	tcPad.Parent = telemetryCard

	local tcLayout = Instance.new("UIListLayout")
	tcLayout.FillDirection = Enum.FillDirection.Vertical
	tcLayout.SortOrder = Enum.SortOrder.LayoutOrder
	tcLayout.Padding = UDim.new(0, 6)
	tcLayout.Parent = telemetryCard

	local teleHeader = Instance.new("Frame")
	teleHeader.Name = "HeaderRow"
	teleHeader.BackgroundTransparency = 1
	teleHeader.Size = UDim2.new(1, 0, 0, 14)
	teleHeader.LayoutOrder = 1
	teleHeader.Parent = telemetryCard

	local thLayout = Instance.new("UIListLayout")
	thLayout.FillDirection = Enum.FillDirection.Horizontal
	thLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	thLayout.SortOrder = Enum.SortOrder.LayoutOrder
	thLayout.Padding = UDim.new(0, 5)
	thLayout.Parent = teleHeader

	createLucideIcon(teleHeader, "activity", UDim2.fromOffset(12, 12), PinkFocus)

	local thTitle = Instance.new("TextLabel")
	thTitle.Name = "Title"
	thTitle.BackgroundTransparency = 1
	thTitle.Font = Enum.Font.GothamBold
	thTitle.Text = "SYSTEM & TELEMETRY"
	thTitle.TextColor3 = PinkFocus
	thTitle.TextSize = 10
	thTitle.AutomaticSize = Enum.AutomaticSize.X
	thTitle.Parent = teleHeader

	local chipsRow = Instance.new("Frame")
	chipsRow.Name = "ChipsRow"
	chipsRow.BackgroundTransparency = 1
	chipsRow.Size = UDim2.new(1, 0, 0, 24)
	chipsRow.LayoutOrder = 2
	chipsRow.Parent = telemetryCard

	local crLayout = Instance.new("UIListLayout")
	crLayout.FillDirection = Enum.FillDirection.Horizontal
	crLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	crLayout.SortOrder = Enum.SortOrder.LayoutOrder
	crLayout.Padding = UDim.new(0, 6)
	crLayout.Parent = chipsRow

	local function createTelemetryChip(name, iconName, iconColor, initialText, order)
		local chip = Instance.new("Frame")
		chip.Name = name .. "Chip"
		chip.BackgroundColor3 = ChipSurface
		chip.BorderSizePixel = 0
		chip.Size = UDim2.new(0.2, -5, 1, 0)
		chip.LayoutOrder = order
		chip.ClipsDescendants = true
		chip.Parent = chipsRow

		local chCorner = Instance.new("UICorner")
		chCorner.CornerRadius = UDim.new(0, 6)
		chCorner.Parent = chip

		local chStroke = Instance.new("UIStroke")
		chStroke.Color = ChipBorder
		chStroke.Thickness = 1
		chStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		chStroke.Parent = chip

		local chPad = Instance.new("UIPadding")
		chPad.PaddingLeft = UDim.new(0, 6)
		chPad.PaddingRight = UDim.new(0, 6)
		chPad.Parent = chip

		local chLayout = Instance.new("UIListLayout")
		chLayout.FillDirection = Enum.FillDirection.Horizontal
		chLayout.VerticalAlignment = Enum.VerticalAlignment.Center
		chLayout.SortOrder = Enum.SortOrder.LayoutOrder
		chLayout.Padding = UDim.new(0, 5)
		chLayout.Parent = chip

		createLucideIcon(chip, iconName, UDim2.fromOffset(12, 12), iconColor)

		local valLabel = Instance.new("TextLabel")
		valLabel.Name = "ValueLabel"
		valLabel.BackgroundTransparency = 1
		valLabel.Font = Enum.Font.GothamBold
		valLabel.Text = initialText
		valLabel.TextColor3 = Text
		valLabel.TextSize = 11
		valLabel.TextTruncate = Enum.TextTruncate.AtEnd
		valLabel.Size = UDim2.new(1, -17, 1, 0)
		valLabel.TextXAlignment = Enum.TextXAlignment.Left
		valLabel.Parent = chip

		return valLabel
	end

	local playersValLabel = createTelemetryChip(
		"Players",
		"users",
		Muted,
		string.format("Players: %d/%d", #Players:GetPlayers(), Players.MaxPlayers),
		1
	)
	local executorValLabel = createTelemetryChip("Executor", "cpu", WarningYellow, tostring(executorName), 2)
	local pingValLabel = createTelemetryChip("Ping", "wifi", StatusOk, "0 ms", 3)
	local fpsValLabel = createTelemetryChip("FPS", "gauge", StatusOk, "60 FPS", 4)
	local memValLabel = createTelemetryChip("Memory", "hard-drive", Muted, "0 MB", 5)

	-- 8. Quick Actions Bar (30px)
	local quickActionsRow = Instance.new("Frame")
	quickActionsRow.Name = "QuickActionsRow"
	quickActionsRow.BackgroundTransparency = 1
	quickActionsRow.Size = UDim2.new(1, 0, 0, 30)
	quickActionsRow.LayoutOrder = 4
	quickActionsRow.Parent = contentParent

	local qaLayout = Instance.new("UIListLayout")
	qaLayout.FillDirection = Enum.FillDirection.Horizontal
	qaLayout.Padding = UDim.new(0, 8)
	qaLayout.SortOrder = Enum.SortOrder.LayoutOrder
	qaLayout.Parent = quickActionsRow

	local function createQuickButton(name, text, order)
		local btn = Instance.new("TextButton")
		btn.Name = name
		btn.BackgroundColor3 = Color3.fromRGB(26, 24, 40) -- #1A1828
		btn.BorderSizePixel = 0
		btn.Size = UDim2.new(0.25, -6, 1, 0)
		btn.LayoutOrder = order
		btn.Font = Enum.Font.GothamMedium
		btn.TextSize = 10
		btn.Text = text
		btn.TextColor3 = Text
		btn.AutoButtonColor = false
		btn.Parent = quickActionsRow

		local bCorner = Instance.new("UICorner")
		bCorner.CornerRadius = UDim.new(0, 6)
		bCorner.Parent = btn

		local bStroke = Instance.new("UIStroke")
		bStroke.Color = Color3.fromRGB(44, 39, 62) -- #2C273E
		bStroke.Thickness = 1
		bStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		bStroke.Parent = btn

		btn.MouseEnter:Connect(function()
			btn.BackgroundColor3 = Color3.fromRGB(36, 32, 54)
		end)
		btn.MouseLeave:Connect(function()
			btn.BackgroundColor3 = Color3.fromRGB(26, 24, 40)
		end)

		return btn, bStroke
	end

	local autoFarmBtn, afStroke = createQuickButton("AutoFarmQuickBtn", "Auto Farm: OFF", 1)
	local farmingTabBtn = createQuickButton("FarmingTabBtn", "Farming Tab", 2)
	local settingsTabBtn = createQuickButton("SettingsTabBtn", "Settings Tab", 3)
	local rejoinBtn = createQuickButton("RejoinBtn", "Rejoin", 4)

	local function syncAutoFarmBtn()
		local isAfOn = false
		if Toggles and Toggles.AutoFarm then
			isAfOn = (Toggles.AutoFarm.Value == true)
		elseif Config and Config.NpcFarm then
			isAfOn = (Config.NpcFarm.AutoFarm == true)
		end

		if isAfOn then
			autoFarmBtn.Text = "Auto Farm: ON"
			autoFarmBtn.TextColor3 = StatusOk
			afStroke.Color = StatusOk
		else
			autoFarmBtn.Text = "Auto Farm: OFF"
			autoFarmBtn.TextColor3 = Muted
			afStroke.Color = Color3.fromRGB(44, 39, 62)
		end
	end
	syncAutoFarmBtn()

	autoFarmBtn.MouseButton1Click:Connect(function()
		if Toggles and Toggles.AutoFarm then
			Toggles.AutoFarm:SetValue(not Toggles.AutoFarm.Value)
		elseif Config and Config.NpcFarm then
			Config.NpcFarm.AutoFarm = not Config.NpcFarm.AutoFarm
		end
		syncAutoFarmBtn()
	end)

	farmingTabBtn.MouseButton1Click:Connect(function()
		if uiUtils.Tabs and uiUtils.Tabs.Main then
			uiUtils.Tabs.Main:Show()
		end
	end)

	settingsTabBtn.MouseButton1Click:Connect(function()
		if uiUtils.Tabs and uiUtils.Tabs.Settings then
			uiUtils.Tabs.Settings:Show()
		end
	end)

	rejoinBtn.MouseButton1Click:Connect(function()
		pcall(function()
			TeleportService:Teleport(game.PlaceId, LocalPlayer)
		end)
	end)

	-- 9. Throttled continuous telemetry loop (1.0s) with real-time frame sampling
	local renderFrameCount = 0
	local lastFpsTime = os.clock()
	local renderConn = nil
	pcall(function()
		renderConn = RunService.RenderStepped:Connect(function()
			renderFrameCount = renderFrameCount + 1
		end)
	end)

	if renderConn then
		if ctx.Connections and type(ctx.Connections) == "table" then
			table.insert(ctx.Connections, renderConn)
		end
		if KittyGs and type(KittyGs.Connections) == "table" then
			table.insert(KittyGs.Connections, renderConn)
		end
		if _G.AnimeBreakerConnections and type(_G.AnimeBreakerConnections) == "table" then
			table.insert(_G.AnimeBreakerConnections, renderConn)
		end
	end

	local function disconnectRenderConn()
		if renderConn then
			pcall(function()
				renderConn:Disconnect()
			end)
			renderConn = nil
		end
	end

	task.spawn(function()
		while _G.AnimeBreakerRunToken == ctx.scriptRunToken or (KittyGs and KittyGs.RunToken == ctx.scriptRunToken) do
			pcall(function()
				local elapsed = os.time() - sessionStart
				local h = math.floor(elapsed / 3600)
				local m = math.floor((elapsed % 3600) / 60)
				local s = elapsed % 60
				if sessionValLabel then
					sessionValLabel.Text = string.format("%02d:%02d:%02d", h, m, s)
				end

				local kType, kRem = getLuarmorKeyDetails()
				if keyTypeValLabel then
					keyTypeValLabel.Text = kType
				end
				if keyExpValLabel then
					keyExpValLabel.Text = kRem
				end

				syncAutoFarmBtn()

				local ping = 0
				pcall(function()
					if LocalPlayer and LocalPlayer.GetNetworkPing then
						ping = math.floor(LocalPlayer:GetNetworkPing() * 1000)
					end
				end)

				local mem = 0
				pcall(function()
					mem = math.floor(Stats:GetTotalMemoryUsageMb())
				end)

				local now = os.clock()
				local dtSec = math.max(0.001, now - lastFpsTime)
				lastFpsTime = now
				local fps = math.round(renderFrameCount / dtSec)
				renderFrameCount = 0

				local notchFps = (KittyGs and KittyGs.NotchFps) or _G.NotchFps
				if notchFps and type(notchFps) == "number" and notchFps > 0 then
					fps = notchFps
				end

				if fps <= 0 then
					fps = 60
				end

				if playersValLabel then
					local pCount = #Players:GetPlayers()
					local maxP = Players.MaxPlayers
					playersValLabel.Text = string.format("Players: %d/%d", pCount, maxP)
				end

				if pingValLabel then
					pingValLabel.Text = string.format("%d ms", ping)
					if ping < 100 then
						pingValLabel.TextColor3 = StatusOk
					else
						pingValLabel.TextColor3 = WarningYellow
					end
				end

				if fpsValLabel then
					fpsValLabel.Text = string.format("%d FPS", fps)
				end

				if memValLabel then
					memValLabel.Text = string.format("%d MB", mem)
				end
			end)
			task.wait(1.0)
		end

		disconnectRenderConn()
	end)

	return {
		Header = headerFrame,
		CardsGrid = cardsGrid,
		TelemetryCard = telemetryCard,
		QuickActions = quickActionsRow,
		SyncAutoFarm = syncAutoFarmBtn,
		Disconnect = disconnectRenderConn,
		Cleanup = disconnectRenderConn,
		Destroy = disconnectRenderConn,
	}
end
