--!strict
--[[
	════════════════════════════════════════════════════════════════════════════════
	🐱 KittyHub — Notch Mini Computer Screen Monitor Module
	Jogo: Anime Breaker
	Padrão Arquitetural: KittyBrain (Obsidian Ultra / Cyberpunk Dark)

	Uso Modular:
	local createNotchMonitor = loadstring(game:HttpGet(".../notchMonitor.lua"))()
	local monitorWrapper = createNotchMonitor(parentGroup, {
		Config = Config,
		Options = Options,
		uiUtils = uiUtils,
		SaveConfig = SaveConfig,
		afkScreen = afkScreen, -- opcional
	})

	Interface & Componentes:
	- NOTCH_PRESETS_DATA (6 presets espaciais na tela)
	- MonitorBezel (#14131E com UIStroke #2C283E)
	- InnerScreen (#1C1A2A com UIStroke #262238)
	- Mac OS Dots (#FF5F56, #FFBD2E, #27C93F) & Title
	- Crosshair Grid (GridH, GridV)
	- Dynamic Center Status Badge (com BadgeGlowDot #78D79B e BadgeText)
	- Power LED chin (#78D79B) & Monitor Stand Neck / Base
	- 6 Interactive Preset Pills (TL, TOP, TR, BL, BTM, BR) com bounce elástico
	- Bidirectional Sync com Options.NotchPreset, Config e uiUtils.SetNotchPreset
	- uiUtils.UpdateNotchMonitorVisuals(activePreset) para atualizações externas
	════════════════════════════════════════════════════════════════════════════════
]]

local TweenService = game:GetService("TweenService")

-- ── 1. Tabela de Coordenadas e Âncoras dos Presets do Notch Dynamic Island ──
local NOTCH_PRESETS_DATA = {
	["Top-Left"] = {
		Position = UDim2.new(0, 15, 0, 10),
		AnchorPoint = Vector2.new(0, 0),
	},
	["Top-Center"] = {
		Position = UDim2.new(0.5, 0, 0, 10),
		AnchorPoint = Vector2.new(0.5, 0),
	},
	["Top-Right"] = {
		Position = UDim2.new(1, -15, 0, 10),
		AnchorPoint = Vector2.new(1, 0),
	},
	["Bottom-Left"] = {
		Position = UDim2.new(0, 15, 1, -10),
		AnchorPoint = Vector2.new(0, 1),
	},
	["Bottom-Center"] = {
		Position = UDim2.new(0.5, 0, 1, -10),
		AnchorPoint = Vector2.new(0.5, 1),
	},
	["Bottom-Right"] = {
		Position = UDim2.new(1, -15, 1, -10),
		AnchorPoint = Vector2.new(1, 1),
	},
}

-- ── Utilitário Seguro de Fontes Luau ──
local function safeSetFont(textObj: TextLabel | TextButton, fontName: string, weight: Enum.FontWeight, fallback: Enum.Font)
	local ok = pcall(function()
		(textObj :: any).FontFace = Font.fromName(fontName, weight)
	end)
	if not ok then
		textObj.Font = fallback
	end
end

-- ── 2. Função Construtora Principal do Monitor ──
local function createNotchMonitor(parentGroup: any, ctx: any)
	ctx = ctx or {}
	local Config = ctx.Config or {}
	if not Config.Settings then
		Config.Settings = {}
	end
	local Options = ctx.Options or {}
	local uiUtils = ctx.uiUtils or {}
	local SaveConfig = ctx.SaveConfig or function() end

	-- Registra dicionário de presets em uiUtils para interoperabilidade
	uiUtils.NOTCH_PRESETS_DATA = NOTCH_PRESETS_DATA

	-- ── Helpers de Controle do Notch (Extraídos de linhas 9003–9145) ──
	if typeof(uiUtils.SetNotchPreset) ~= "function" then
		function uiUtils.SetNotchPreset(presetName: string, animate: boolean)
			if Config.Settings then
				Config.Settings.NotchPreset = presetName
			end
			local afk = ctx.afkScreen or uiUtils.afkScreen or _G.afkScreen
			if afk and typeof(afk.SetPreset) == "function" then
				pcall(function()
					afk.SetPreset(presetName, animate)
				end)
			end
			local env = (typeof(getgenv) == "function" and getgenv()) or _G
			if env.__KITTY_NOTCH_TEST and typeof(env.__KITTY_NOTCH_TEST.SetPreset) == "function" then
				pcall(function()
					env.__KITTY_NOTCH_TEST.SetPreset(presetName, animate)
				end)
			end
			local btn = uiUtils.ToggleBtn or (afk and afk.ToggleBtn)
			if btn and typeof(btn) == "Instance" and not (afk and typeof(afk.SetPreset) == "function") then
				local p = NOTCH_PRESETS_DATA[presetName]
				if p then
					btn.AnchorPoint = p.AnchorPoint
					if animate ~= false then
						TweenService:Create(btn, TweenInfo.new(0.38, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), {
							Position = p.Position,
						}):Play()
					else
						btn.Position = p.Position
					end
				end
			end
			if typeof(uiUtils.UpdateNotchMonitorVisuals) == "function" then
				pcall(function()
					uiUtils.UpdateNotchMonitorVisuals(presetName)
				end)
			end
		end
	end

	if typeof(uiUtils.SetNotchBorderGlow) ~= "function" then
		function uiUtils.SetNotchBorderGlow(enabled: boolean)
			if Config.Settings then
				Config.Settings.NotchBorderGlow = (enabled == true)
			end
			local afk = ctx.afkScreen or uiUtils.afkScreen or _G.afkScreen
			if afk and typeof(afk.SetBorderOutlineEnabled) == "function" then
				pcall(function()
					afk.SetBorderOutlineEnabled(enabled)
				end)
			elseif afk and typeof(afk.SetBorderGlow) == "function" then
				pcall(function()
					afk.SetBorderGlow(enabled)
				end)
			end
			local env = (typeof(getgenv) == "function" and getgenv()) or _G
			if env.__KITTY_NOTCH_TEST and typeof(env.__KITTY_NOTCH_TEST.SetBorderOutlineEnabled) == "function" then
				pcall(function()
					env.__KITTY_NOTCH_TEST.SetBorderOutlineEnabled(enabled)
				end)
			end
			local btn = uiUtils.ToggleBtn or (afk and afk.ToggleBtn)
			if btn and typeof(btn) == "Instance" then
				local stroke = btn:FindFirstChildWhichIsA("UIStroke")
				if stroke then
					local gradient = stroke:FindFirstChildWhichIsA("UIGradient")
					if gradient then
						gradient.Enabled = (enabled == true)
					end
					if enabled then
						stroke.Color = Color3.fromRGB(255, 255, 255)
						stroke.Thickness = 1.35
						stroke.Transparency = 0
					else
						stroke.Color = Color3.fromRGB(60, 55, 72)
						stroke.Thickness = 1.2
						stroke.Transparency = 0.35
					end
				end
			end
		end
	end

	if typeof(uiUtils.SetNotchDraggable) ~= "function" then
		function uiUtils.SetNotchDraggable(enabled: boolean)
			if Config.Settings then
				Config.Settings.NotchDraggable = (enabled == true)
			end
			local afk = ctx.afkScreen or uiUtils.afkScreen or _G.afkScreen
			if afk and typeof(afk.SetDraggableEnabled) == "function" then
				pcall(function()
					afk.SetDraggableEnabled(enabled)
				end)
			end
			local env = (typeof(getgenv) == "function" and getgenv()) or _G
			if env.__KITTY_NOTCH_TEST and typeof(env.__KITTY_NOTCH_TEST.SetDraggableEnabled) == "function" then
				pcall(function()
					env.__KITTY_NOTCH_TEST.SetDraggableEnabled(enabled)
				end)
			end
		end
	end

	-- ── 3. Construção da Estrutura do Mini Monitor ──
	local monitorWrapper = Instance.new("Frame")
	monitorWrapper.Name = "NotchMonitorWrapper"
	monitorWrapper.Size = UDim2.new(1, 0, 0, 154)
	monitorWrapper.BackgroundTransparency = 1
	monitorWrapper.BorderSizePixel = 0
	monitorWrapper.ClipsDescendants = false

	-- Outer Monitor Bezel (Cyberpunk Dark #14131E com UIStroke #2C283E)
	local monitorBezel = Instance.new("Frame")
	monitorBezel.Name = "MonitorBezel"
	monitorBezel.Size = UDim2.new(1, 0, 0, 128)
	monitorBezel.Position = UDim2.new(0, 0, 0, 2)
	monitorBezel.BackgroundColor3 = Color3.fromRGB(20, 19, 30) -- #14131E
	monitorBezel.BorderSizePixel = 0
	monitorBezel.ZIndex = 5
	monitorBezel.Parent = monitorWrapper

	local bezelCorner = Instance.new("UICorner")
	bezelCorner.CornerRadius = UDim.new(0, 8)
	bezelCorner.Parent = monitorBezel

	local bezelStroke = Instance.new("UIStroke")
	bezelStroke.Color = Color3.fromRGB(44, 40, 62) -- #2C283E
	bezelStroke.Thickness = 1.2
	bezelStroke.Parent = monitorBezel

	-- Inner Screen Frame (Simulação do Game Viewport #1C1A2A)
	local innerScreen = Instance.new("Frame")
	innerScreen.Name = "InnerScreen"
	innerScreen.Size = UDim2.new(1, -12, 1, -16)
	innerScreen.Position = UDim2.new(0, 6, 0, 6)
	innerScreen.BackgroundColor3 = Color3.fromRGB(28, 26, 42) -- #1C1A2A
	innerScreen.BorderSizePixel = 0
	innerScreen.ClipsDescendants = true
	innerScreen.ZIndex = 6
	innerScreen.Parent = monitorBezel

	local screenCorner = Instance.new("UICorner")
	screenCorner.CornerRadius = UDim.new(0, 5)
	screenCorner.Parent = innerScreen

	local screenStroke = Instance.new("UIStroke")
	screenStroke.Color = Color3.fromRGB(38, 34, 56) -- #262238
	screenStroke.Thickness = 1
	screenStroke.Parent = innerScreen

	-- Top simulated titlebar / header
	local screenTopBar = Instance.new("Frame")
	screenTopBar.Name = "ScreenTopBar"
	screenTopBar.Size = UDim2.new(1, 0, 0, 12)
	screenTopBar.Position = UDim2.new(0, 0, 0, 0)
	screenTopBar.BackgroundColor3 = Color3.fromRGB(21, 19, 32)
	screenTopBar.BorderSizePixel = 0
	screenTopBar.ZIndex = 7
	screenTopBar.Parent = innerScreen

	-- Mac OS Window Dots (#FF5F56, #FFBD2E, #27C93F)
	local dotsColors = {
		Color3.fromRGB(255, 95, 86),  -- #FF5F56
		Color3.fromRGB(255, 189, 46), -- #FFBD2E
		Color3.fromRGB(39, 201, 63),  -- #27C93F
	}
	for i, dotCol in ipairs(dotsColors) do
		local winDot = Instance.new("Frame")
		winDot.Name = "Dot_" .. i
		winDot.Size = UDim2.new(0, 5, 0, 5)
		winDot.Position = UDim2.new(0, 7 + (i - 1) * 8, 0.5, 0)
		winDot.AnchorPoint = Vector2.new(0, 0.5)
		winDot.BackgroundColor3 = dotCol
		winDot.BackgroundTransparency = 0.35
		winDot.BorderSizePixel = 0
		winDot.ZIndex = 8
		local c = Instance.new("UICorner")
		c.CornerRadius = UDim.new(1, 0)
		c.Parent = winDot
		winDot.Parent = screenTopBar
	end

	local miniTopTitle = Instance.new("TextLabel")
	miniTopTitle.Name = "MiniTopTitle"
	miniTopTitle.Size = UDim2.new(1, -60, 1, 0)
	miniTopTitle.Position = UDim2.new(0, 36, 0, 0)
	miniTopTitle.BackgroundTransparency = 1
	miniTopTitle.Text = "DISPLAY VIEWPORT • NOTCH PRESETS"
	miniTopTitle.TextColor3 = Color3.fromRGB(110, 102, 132)
	safeSetFont(miniTopTitle, "Inter", Enum.FontWeight.SemiBold, Enum.Font.GothamMedium)
	miniTopTitle.TextSize = 7.5
	miniTopTitle.TextXAlignment = Enum.TextXAlignment.Left
	miniTopTitle.ZIndex = 8
	miniTopTitle.Parent = screenTopBar

	-- Subtle Horizon / Crosshair Grid (GridH, GridV)
	local gridH = Instance.new("Frame")
	gridH.Name = "GridH"
	gridH.Size = UDim2.new(1, -16, 0, 1)
	gridH.Position = UDim2.new(0, 8, 0.5, 3)
	gridH.BackgroundColor3 = Color3.fromRGB(44, 40, 62)
	gridH.BackgroundTransparency = 0.65
	gridH.BorderSizePixel = 0
	gridH.ZIndex = 7
	gridH.Parent = innerScreen

	local gridV = Instance.new("Frame")
	gridV.Name = "GridV"
	gridV.Size = UDim2.new(0, 1, 1, -22)
	gridV.Position = UDim2.new(0.5, 0, 0, 15)
	gridV.BackgroundColor3 = Color3.fromRGB(44, 40, 62)
	gridV.BackgroundTransparency = 0.65
	gridV.BorderSizePixel = 0
	gridV.ZIndex = 7
	gridV.Parent = innerScreen

	-- Central Dynamic Status Badge
	local centerBadge = Instance.new("Frame")
	centerBadge.Name = "CenterBadge"
	centerBadge.Size = UDim2.new(0, 114, 0, 18)
	centerBadge.Position = UDim2.new(0.5, 0, 0.5, 3)
	centerBadge.AnchorPoint = Vector2.new(0.5, 0.5)
	centerBadge.BackgroundColor3 = Color3.fromRGB(19, 17, 28)
	centerBadge.BorderSizePixel = 0
	centerBadge.ZIndex = 8
	centerBadge.Parent = innerScreen

	local badgeCorner = Instance.new("UICorner")
	badgeCorner.CornerRadius = UDim.new(0, 5)
	badgeCorner.Parent = centerBadge

	local badgeStroke = Instance.new("UIStroke")
	badgeStroke.Color = Color3.fromRGB(44, 40, 62)
	badgeStroke.Thickness = 1
	badgeStroke.Parent = centerBadge

	local badgeGlowDot = Instance.new("Frame")
	badgeGlowDot.Name = "BadgeGlowDot"
	badgeGlowDot.Size = UDim2.new(0, 5, 0, 5)
	badgeGlowDot.Position = UDim2.new(0, 7, 0.5, 0)
	badgeGlowDot.AnchorPoint = Vector2.new(0, 0.5)
	badgeGlowDot.BackgroundColor3 = Color3.fromRGB(120, 215, 155) -- #78D79B
	badgeGlowDot.BorderSizePixel = 0
	badgeGlowDot.ZIndex = 9
	local bgc = Instance.new("UICorner")
	bgc.CornerRadius = UDim.new(1, 0)
	bgc.Parent = badgeGlowDot
	badgeGlowDot.Parent = centerBadge

	local initialPreset = (Config.Settings and Config.Settings.NotchPreset) or "Top-Center"
	local badgeText = Instance.new("TextLabel")
	badgeText.Name = "BadgeText"
	badgeText.Size = UDim2.new(1, -18, 1, 0)
	badgeText.Position = UDim2.new(0, 16, 0, 0)
	badgeText.BackgroundTransparency = 1
	badgeText.Text = initialPreset .. " • ACTIVE"
	badgeText.TextColor3 = Color3.fromRGB(120, 215, 155)
	safeSetFont(badgeText, "Inter", Enum.FontWeight.SemiBold, Enum.Font.GothamMedium)
	badgeText.TextSize = 8.5
	badgeText.TextXAlignment = Enum.TextXAlignment.Left
	badgeText.ZIndex = 9
	badgeText.Parent = centerBadge

	-- Power Indicator LED no queixo inferior do bezel
	local powerLed = Instance.new("Frame")
	powerLed.Name = "PowerLed"
	powerLed.Size = UDim2.new(0, 5, 0, 2)
	powerLed.Position = UDim2.new(0.5, 0, 1, -2)
	powerLed.AnchorPoint = Vector2.new(0.5, 0.5)
	powerLed.BackgroundColor3 = Color3.fromRGB(120, 215, 155) -- #78D79B
	powerLed.BorderSizePixel = 0
	powerLed.ZIndex = 7
	local plc = Instance.new("UICorner")
	plc.CornerRadius = UDim.new(1, 0)
	plc.Parent = powerLed
	powerLed.Parent = monitorBezel

	-- Monitor Stand Neck & Base
	local standNeck = Instance.new("Frame")
	standNeck.Name = "StandNeck"
	standNeck.Size = UDim2.new(0, 18, 0, 9)
	standNeck.Position = UDim2.new(0.5, 0, 0, 130)
	standNeck.AnchorPoint = Vector2.new(0.5, 0)
	standNeck.BackgroundColor3 = Color3.fromRGB(24, 22, 34)
	standNeck.BorderSizePixel = 0
	standNeck.ZIndex = 3
	standNeck.Parent = monitorWrapper

	local neckStroke = Instance.new("UIStroke")
	neckStroke.Color = Color3.fromRGB(44, 40, 62)
	neckStroke.Thickness = 1
	neckStroke.Parent = standNeck

	local standBase = Instance.new("Frame")
	standBase.Name = "StandBase"
	standBase.Size = UDim2.new(0, 68, 0, 5)
	standBase.Position = UDim2.new(0.5, 0, 0, 139)
	standBase.AnchorPoint = Vector2.new(0.5, 0)
	standBase.BackgroundColor3 = Color3.fromRGB(30, 27, 42)
	standBase.BorderSizePixel = 0
	standBase.ZIndex = 4
	standBase.Parent = monitorWrapper

	local baseCorner = Instance.new("UICorner")
	baseCorner.CornerRadius = UDim.new(0, 2.5)
	baseCorner.Parent = standBase

	local baseStroke = Instance.new("UIStroke")
	baseStroke.Color = Color3.fromRGB(44, 40, 62)
	baseStroke.Thickness = 1
	baseStroke.Parent = standBase

	-- ── 4. 6 Interactive Preset Buttons (Pills) ──
	local presetConfigs = {
		{ name = "Top-Left", label = "TL", anchor = Vector2.new(0, 0), pos = UDim2.new(0, 6, 0, 15) },
		{ name = "Top-Center", label = "TOP", anchor = Vector2.new(0.5, 0), pos = UDim2.new(0.5, 0, 0, 15) },
		{ name = "Top-Right", label = "TR", anchor = Vector2.new(1, 0), pos = UDim2.new(1, -6, 0, 15) },
		{ name = "Bottom-Left", label = "BL", anchor = Vector2.new(0, 1), pos = UDim2.new(0, 6, 1, -6) },
		{ name = "Bottom-Center", label = "BTM", anchor = Vector2.new(0.5, 1), pos = UDim2.new(0.5, 0, 1, -6) },
		{ name = "Bottom-Right", label = "BR", anchor = Vector2.new(1, 1), pos = UDim2.new(1, -6, 1, -6) },
	}

	local presetButtons = {}

	local function updateVisualState(activePreset: string?)
		local targetPreset = activePreset or (Config.Settings and Config.Settings.NotchPreset) or "Top-Center"
		for pName, pBtn in pairs(presetButtons) do
			local isActive = (pName == targetPreset)
			local stroke = pBtn:FindFirstChildWhichIsA("UIStroke")
			local dot = pBtn:FindFirstChild("Dot")
			local label = pBtn:FindFirstChild("Label")

			if isActive then
				TweenService:Create(pBtn, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
					BackgroundColor3 = Color3.fromRGB(30, 58, 44), -- Deep Mint
				}):Play()
				if stroke then
					TweenService:Create(stroke, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
						Color = Color3.fromRGB(120, 215, 155), -- #78D79B Mint Green
						Thickness = 1.4,
					}):Play()
				end
				if dot then
					dot.BackgroundColor3 = Color3.fromRGB(120, 215, 155)
					dot.BackgroundTransparency = 0
				end
				if label then
					label.TextColor3 = Color3.fromRGB(255, 255, 255)
				end
			else
				TweenService:Create(pBtn, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
					BackgroundColor3 = Color3.fromRGB(24, 21, 35),
				}):Play()
				if stroke then
					TweenService:Create(stroke, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
						Color = Color3.fromRGB(44, 40, 62), -- #2C283E
						Thickness = 1,
					}):Play()
				end
				if dot then
					dot.BackgroundColor3 = Color3.fromRGB(80, 74, 102)
					dot.BackgroundTransparency = 0.35
				end
				if label then
					label.TextColor3 = Color3.fromRGB(142, 136, 168)
				end
			end
		end
		if badgeText then
			badgeText.Text = targetPreset .. " • ACTIVE"
		end
	end

	-- Expõe atualização visual reativa para sincronização global
	uiUtils.UpdateNotchMonitorVisuals = updateVisualState

	for _, pData in ipairs(presetConfigs) do
		local pillBtn = Instance.new("TextButton")
		pillBtn.Name = "PresetPill_" .. pData.name:gsub("%-", "")
		pillBtn.Size = UDim2.new(0, 44, 0, 18)
		pillBtn.Position = pData.pos
		pillBtn.AnchorPoint = pData.anchor
		pillBtn.BackgroundColor3 = Color3.fromRGB(24, 21, 35)
		pillBtn.AutoButtonColor = false
		pillBtn.Text = ""
		pillBtn.BorderSizePixel = 0
		pillBtn.ZIndex = 10
		pillBtn.Parent = innerScreen

		local pillCorner = Instance.new("UICorner")
		pillCorner.CornerRadius = UDim.new(0, 8)
		pillCorner.Parent = pillBtn

		local pillStroke = Instance.new("UIStroke")
		pillStroke.Color = Color3.fromRGB(44, 40, 62)
		pillStroke.Thickness = 1
		pillStroke.Parent = pillBtn

		local pillDot = Instance.new("Frame")
		pillDot.Name = "Dot"
		pillDot.Size = UDim2.new(0, 5, 0, 5)
		pillDot.Position = UDim2.new(0, 6, 0.5, 0)
		pillDot.AnchorPoint = Vector2.new(0, 0.5)
		pillDot.BackgroundColor3 = Color3.fromRGB(80, 74, 102)
		pillDot.BackgroundTransparency = 0.35
		pillDot.BorderSizePixel = 0
		pillDot.ZIndex = 11
		local pdc = Instance.new("UICorner")
		pdc.CornerRadius = UDim.new(1, 0)
		pdc.Parent = pillDot
		pillDot.Parent = pillBtn

		local pillLabel = Instance.new("TextLabel")
		pillLabel.Name = "Label"
		pillLabel.Size = UDim2.new(1, -16, 1, 0)
		pillLabel.Position = UDim2.new(0, 15, 0, 0)
		pillLabel.BackgroundTransparency = 1
		pillLabel.Text = pData.label
		pillLabel.TextColor3 = Color3.fromRGB(142, 136, 168)
		safeSetFont(pillLabel, "Inter", Enum.FontWeight.Bold, Enum.Font.GothamBold)
		pillLabel.TextSize = 8
		pillLabel.TextXAlignment = Enum.TextXAlignment.Left
		pillLabel.ZIndex = 11
		pillLabel.Parent = pillBtn

		-- Hover Effects
		pillBtn.MouseEnter:Connect(function()
			local current = (Config.Settings and Config.Settings.NotchPreset) or "Top-Center"
			if current ~= pData.name then
				TweenService:Create(pillBtn, TweenInfo.new(0.15), {
					BackgroundColor3 = Color3.fromRGB(36, 32, 52),
				}):Play()
				TweenService:Create(pillStroke, TweenInfo.new(0.15), {
					Color = Color3.fromRGB(214, 142, 180), -- #D68EB4 Pink Accent
				}):Play()
				pillLabel.TextColor3 = Color3.fromRGB(230, 225, 240)
			end
		end)

		pillBtn.MouseLeave:Connect(function()
			local current = (Config.Settings and Config.Settings.NotchPreset) or "Top-Center"
			if current ~= pData.name then
				TweenService:Create(pillBtn, TweenInfo.new(0.15), {
					BackgroundColor3 = Color3.fromRGB(24, 21, 35),
				}):Play()
				TweenService:Create(pillStroke, TweenInfo.new(0.15), {
					Color = Color3.fromRGB(44, 40, 62),
				}):Play()
				pillLabel.TextColor3 = Color3.fromRGB(142, 136, 168)
			end
		end)

		-- Click Handler com Elastic Bounce Animation (44x18 -> 41x16 -> 44x18)
		pillBtn.MouseButton1Click:Connect(function()
			local origSize = UDim2.new(0, 44, 0, 18)
			TweenService:Create(pillBtn, TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				Size = UDim2.new(0, 41, 0, 16),
			}):Play()
			task.delay(0.08, function()
				TweenService:Create(pillBtn, TweenInfo.new(0.12, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
					Size = origSize,
				}):Play()
			end)

			if Config.Settings then
				Config.Settings.NotchPreset = pData.name
			end
			if typeof(uiUtils.SetNotchPreset) == "function" then
				uiUtils.SetNotchPreset(pData.name, true)
			end
			if Options and Options.NotchPreset and typeof(Options.NotchPreset.SetValue) == "function" then
				pcall(function()
					Options.NotchPreset:SetValue(pData.name)
				end)
			end
			if typeof(SaveConfig) == "function" then
				SaveConfig()
			end
			updateVisualState(pData.name)
		end)

		presetButtons[pData.name] = pillBtn
	end

	-- ── 5. Montagem no parentGroup (AddUIPassthrough ou fallback Container) ──
	local mounted = false
	if parentGroup and typeof(parentGroup.AddUIPassthrough) == "function" then
		local s, res = pcall(function()
			return parentGroup:AddUIPassthrough("NotchMonitorPreview", {
				Instance = monitorWrapper,
				Height = 154,
				Visible = true,
			})
		end)
		if s and res then
			mounted = true
		end
	end
	if not mounted and parentGroup then
		if parentGroup.Container then
			monitorWrapper.Parent = parentGroup.Container
		else
			monitorWrapper.Parent = parentGroup
		end
		if typeof(parentGroup.Resize) == "function" then
			pcall(function()
				parentGroup:Resize()
			end)
		end
	end

	-- Aplica estado visual inicial persistido
	updateVisualState((Config.Settings and Config.Settings.NotchPreset) or "Top-Center")

	return monitorWrapper
end

return createNotchMonitor
