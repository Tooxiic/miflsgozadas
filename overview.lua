--!strict
--[[
    ════════════════════════════════════════════════════════════════════════════════
    🐱 KittyHub — Overview Telemetry Overlay Module
    Jogo: Anime Breaker
    Padrão Arquitetural: KittyBrain (Obsidian Ultra Inspired / Dev-First)

    Uso Modular:
    1. Direct Loadstring:
       local overview = loadstring(game:HttpGet(".../overview.lua"))(uiUtils, tabs, options)

    2. Requerido como Módulo:
       local Overview = loadstring(game:HttpGet(".../overview.lua"))()
       local overview = Overview.new(uiUtils, tabs, options)

    Interface Pública:
    - overview.Gui: ScreenGui
    - overview.MainFrame: Frame
    - overview.Theme: Table de cores
    - overview.SetKeyStatus(status: string)
    - overview.SetExpires(expires: string)
    - overview.SetLocation(location: string)
    - overview.Toggle()
    - overview.Show()
    - overview.Hide()
    - overview.Minimize(state: boolean?)
    - overview.Destroy()
    ════════════════════════════════════════════════════════════════════════════════
]]

local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Stats = game:GetService("Stats")
local HttpService = game:GetService("HttpService")
local MarketplaceService = game:GetService("MarketplaceService")

local LocalPlayer = Players.LocalPlayer
if not LocalPlayer then
    Players:GetPropertyChangedSignal("LocalPlayer"):Wait()
    LocalPlayer = Players.LocalPlayer
end

-- ============================================================================
-- 1. TEMA PADRÃO & TIPOGRAFIA
-- ============================================================================
local DefaultTheme = {
    bg = Color3.fromRGB(18, 18, 24),
    surface = Color3.fromRGB(26, 26, 36),
    border = Color3.fromRGB(42, 42, 58),
    text = Color3.fromRGB(240, 240, 245),
    muted = Color3.fromRGB(140, 140, 155),
    accent = Color3.fromRGB(147, 112, 219), -- Violeta suave / dev-first
    green = Color3.fromRGB(34, 197, 94),
}

local Fonts = {
    regular = Enum.Font.GothamMedium,
    bold = Enum.Font.GothamBold,
}

local OverviewModule = {}
OverviewModule.__index = OverviewModule

-- ============================================================================
-- 2. FUNÇÕES UTILITÁRIAS INTERNAS
-- ============================================================================
local function getSafeGuiParent(): Instance
    if gethui then
        local success, result = pcall(gethui)
        if success and result then return result end
    end
    local success, result = pcall(function()
        return CoreGui
    end)
    if success and result then return result end
    return LocalPlayer:WaitForChild("PlayerGui")
end

local function detectExecutor(): string
    if identifyexecutor then
        local success, name, ver = pcall(identifyexecutor)
        if success and name then
            return tostring(name) .. (ver and (" " .. tostring(ver)) or "")
        end
    end
    if getexecutorname then
        local success, name = pcall(getexecutorname)
        if success and name then return tostring(name) end
    end
    return "Real / Unknown"
end

local function detectLocation(): string
    local env = (typeof(getgenv) == "function" and getgenv()) or _G
    if env.AnimeBreakerLocation and type(env.AnimeBreakerLocation) == "string" then
        return env.AnimeBreakerLocation
    end
    local mapAttr = workspace:GetAttribute("MapName") or workspace:GetAttribute("CurrentMap")
    if mapAttr and type(mapAttr) == "string" and #mapAttr > 0 then
        return mapAttr
    end
    local success, info = pcall(function()
        return MarketplaceService:GetProductInfo(game.PlaceId)
    end)
    if success and info and info.Name then
        return tostring(info.Name)
    end
    return "Mundo " .. tostring(game.PlaceId)
end

local function getLuarmorKeyDetails(): (string, string)
    local env = (typeof(getgenv) == "function" and getgenv()) or _G
    local exp = env.key_expires
    local key = env.script_key or env.LuarmorKey
    local keyType = "Lifetime"
    local remainingStr = "Nunca"

    if exp then
        if type(exp) == "number" then
            local remaining = exp - os.time()
            if remaining > 0 then
                keyType = "Premium Key"
                local days = math.floor(remaining / 86400)
                local hours = math.floor((remaining % 86400) / 3600)
                local mins = math.floor((remaining % 3600) / 60)
                if days > 1 then
                    remainingStr = string.format("%d d", days)
                elseif days == 1 then
                    remainingStr = "1 d"
                elseif hours > 0 then
                    remainingStr = string.format("%d h", hours)
                else
                    remainingStr = string.format("%d min", math.max(1, mins))
                end
            else
                keyType = "Premium Key"
                remainingStr = "Expirado"
            end
        else
            remainingStr = tostring(exp)
        end
    elseif key and tostring(key) ~= "" then
        keyType = "Premium"
        remainingStr = "Ativo"
    end

    return keyType, remainingStr
end

local function setClipboardSafe(text: string): boolean
    if setclipboard then
        local ok = pcall(setclipboard, text)
        if ok then return true end
    end
    if toclipboard then
        local ok = pcall(toclipboard, text)
        if ok then return true end
    end
    return false
end

local function tween(instance: Instance, duration: number, props: {[string]: any})
    local tweenInfo = TweenInfo.new(duration or 0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    local anim = TweenService:Create(instance, tweenInfo, props)
    anim:Play()
    return anim
end

local function createCorner(parent: Instance, radius: number?): UICorner
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius or 8)
    corner.Parent = parent
    return corner
end

local function createStroke(parent: Instance, color: Color3?, thickness: number?): UIStroke
    local stroke = Instance.new("UIStroke")
    stroke.Color = color or DefaultTheme.border
    stroke.Thickness = thickness or 1
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Parent = parent
    return stroke
end

local function createPadding(parent: Instance, top: number, bottom: number, left: number, right: number): UIPadding
    local pad = Instance.new("UIPadding")
    pad.PaddingTop = UDim.new(0, top)
    pad.PaddingBottom = UDim.new(0, bottom)
    pad.PaddingLeft = UDim.new(0, left)
    pad.PaddingRight = UDim.new(0, right)
    pad.Parent = parent
    return pad
end

local function createSeparator(parent: Instance, color: Color3?): Frame
    local sep = Instance.new("Frame")
    sep.Name = "Separator"
    sep.Size = UDim2.new(1, 0, 0, 1)
    sep.BackgroundColor3 = color or DefaultTheme.border
    sep.BorderSizePixel = 0
    sep.Parent = parent
    return sep
end

-- ============================================================================
-- 3. CONSTRUTOR PRINCIPAL (OverviewModule.new)
-- ============================================================================
function OverviewModule.new(uiUtils: any?, tabs: any?, options: any?)
    local self = setmetatable({}, OverviewModule)

    local opts = options or (if type(uiUtils) == "table" and not uiUtils.Window and not uiUtils.Tabs then uiUtils else {})
    local passedUiUtils = if type(uiUtils) == "table" and (uiUtils.Window or uiUtils.Tabs or uiUtils.Library) then uiUtils else nil

    self.UiUtils = passedUiUtils
    self.Tabs = tabs or (passedUiUtils and passedUiUtils.Tabs)
    self.Options = opts

    -- Configuração do tema
    local theme = {}
    for k, v in pairs(DefaultTheme) do
        theme[k] = v
    end
    if opts.Theme and type(opts.Theme) == "table" then
        for k, v in pairs(opts.Theme) do
            theme[k] = v
        end
    end
    self.Theme = theme

    -- Configurações gerais
    local DISCORD_INVITE_URL = opts.DiscordUrl or "https://discord.gg/kittyhub"
    local DISCORD_DISPLAY = opts.DiscordDisplay or "discord.gg/kittyhub"
    local SCRIPT_VERSION = opts.Version or "v60 / KittyHub"
    local GAME_TITLE = opts.Title or "Anime Breaker"

    -- Gerenciamento de ciclo de vida e token de hot-reload
    local runToken = HttpService:GenerateGUID(false)
    self.RunToken = runToken
    self.Connections = {} as {RBXScriptConnection}

    local env = (typeof(getgenv) == "function" and getgenv()) or _G
    if type(env.KittyGs) ~= "table" then
        env.KittyGs = {}
    end
    local KittyGs = env.KittyGs

    if KittyGs and KittyGs.Overview and typeof(KittyGs.Overview.Unload) == "function" then
        pcall(KittyGs.Overview.Unload)
    elseif env.AnimeBreakerOverviewUnload then
        pcall(env.AnimeBreakerOverviewUnload)
    end

    if KittyGs then
        KittyGs.Overview = KittyGs.Overview or {}
        KittyGs.Overview.RunToken = runToken
    end
    env.AnimeBreakerOverviewRunToken = runToken
    _G.AnimeBreakerOverviewRunToken = runToken

    local function registerConn(conn: RBXScriptConnection)
        table.insert(self.Connections, conn)
        return conn
    end

    -- ------------------------------------------------------------------------
    -- Construção da UI: ScreenGui
    -- ------------------------------------------------------------------------
    local parentGui = opts.Parent or getSafeGuiParent()
    local OverviewGui = Instance.new("ScreenGui")
    OverviewGui.Name = "KittyHub_Overview"
    OverviewGui.ResetOnSpawn = false
    OverviewGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    OverviewGui.Parent = parentGui
    self.Gui = OverviewGui

    local WINDOW_WIDTH = opts.Width or 340
    local WINDOW_FULL_HEIGHT = opts.Height or 286
    local WINDOW_COLLAPSED_HEIGHT = 48

    local MainFrame = Instance.new("Frame")
    MainFrame.Name = "MainFrame"
    MainFrame.Size = UDim2.new(0, WINDOW_WIDTH, 0, WINDOW_FULL_HEIGHT)
    MainFrame.Position = opts.Position or UDim2.new(0, 32, 0, 50)
    MainFrame.BackgroundColor3 = theme.bg
    MainFrame.BorderSizePixel = 0
    MainFrame.ClipsDescendants = true
    MainFrame.Parent = OverviewGui
    self.MainFrame = MainFrame

    createCorner(MainFrame, 8)
    createStroke(MainFrame, theme.border, 1)

    -- ------------------------------------------------------------------------
    -- Header Compacto
    -- ------------------------------------------------------------------------
    local Header = Instance.new("Frame")
    Header.Name = "Header"
    Header.Size = UDim2.new(1, 0, 0, WINDOW_COLLAPSED_HEIGHT)
    Header.BackgroundColor3 = theme.surface
    Header.BorderSizePixel = 0
    Header.Parent = MainFrame

    createPadding(Header, 8, 8, 12, 12)

    local Avatar = Instance.new("ImageLabel")
    Avatar.Name = "Avatar"
    Avatar.Size = UDim2.new(0, 32, 0, 32)
    Avatar.Position = UDim2.new(0, 0, 0.5, 0)
    Avatar.AnchorPoint = Vector2.new(0, 0.5)
    Avatar.BackgroundColor3 = theme.bg
    Avatar.Image = "rbxthumb://type=AvatarHeadShot&id=" .. tostring(LocalPlayer.UserId) .. "&w=150&h=150"
    Avatar.Parent = Header

    createCorner(Avatar, 16)
    createStroke(Avatar, theme.border, 1)

    local UserBlock = Instance.new("Frame")
    UserBlock.Name = "UserBlock"
    UserBlock.Size = UDim2.new(0, 110, 1, 0)
    UserBlock.Position = UDim2.new(0, 40, 0.5, 0)
    UserBlock.AnchorPoint = Vector2.new(0, 0.5)
    UserBlock.BackgroundTransparency = 1
    UserBlock.Parent = Header

    local UsernameLabel = Instance.new("TextLabel")
    UsernameLabel.Name = "Username"
    UsernameLabel.Size = UDim2.new(1, 0, 0, 16)
    UsernameLabel.Position = UDim2.new(0, 0, 0, 0)
    UsernameLabel.BackgroundTransparency = 1
    UsernameLabel.Font = Fonts.bold
    UsernameLabel.TextSize = 12
    UsernameLabel.TextColor3 = theme.text
    UsernameLabel.TextXAlignment = Enum.TextXAlignment.Left
    UsernameLabel.TextTruncate = Enum.TextTruncate.AtEnd
    UsernameLabel.Text = LocalPlayer.Name
    UsernameLabel.Parent = UserBlock

    local StatusRow = Instance.new("Frame")
    StatusRow.Name = "StatusRow"
    StatusRow.Size = UDim2.new(1, 0, 0, 14)
    StatusRow.Position = UDim2.new(0, 0, 0, 17)
    StatusRow.BackgroundTransparency = 1
    StatusRow.Parent = UserBlock

    local StatusDot = Instance.new("Frame")
    StatusDot.Name = "Dot"
    StatusDot.Size = UDim2.new(0, 6, 0, 6)
    StatusDot.Position = UDim2.new(0, 0, 0.5, 0)
    StatusDot.AnchorPoint = Vector2.new(0, 0.5)
    StatusDot.BackgroundColor3 = theme.green
    StatusDot.BorderSizePixel = 0
    StatusDot.Parent = StatusRow

    createCorner(StatusDot, 3)

    local StatusText = Instance.new("TextLabel")
    StatusText.Name = "Text"
    StatusText.Size = UDim2.new(1, -12, 1, 0)
    StatusText.Position = UDim2.new(0, 12, 0, 0)
    StatusText.BackgroundTransparency = 1
    StatusText.Font = Fonts.regular
    StatusText.TextSize = 10
    StatusText.TextColor3 = theme.muted
    StatusText.TextXAlignment = Enum.TextXAlignment.Left
    StatusText.Text = "Online"
    StatusText.Parent = StatusRow

    -- Metadados à direita
    local MetaBlock = Instance.new("Frame")
    MetaBlock.Name = "MetaBlock"
    MetaBlock.Size = UDim2.new(0, 100, 1, 0)
    MetaBlock.Position = UDim2.new(1, -54, 0.5, 0)
    MetaBlock.AnchorPoint = Vector2.new(1, 0.5)
    MetaBlock.BackgroundTransparency = 1
    MetaBlock.Parent = Header

    local GameTitleLabel = Instance.new("TextLabel")
    GameTitleLabel.Name = "GameTitle"
    GameTitleLabel.Size = UDim2.new(1, 0, 0, 16)
    GameTitleLabel.Position = UDim2.new(0, 0, 0, 0)
    GameTitleLabel.BackgroundTransparency = 1
    GameTitleLabel.Font = Fonts.bold
    GameTitleLabel.TextSize = 12
    GameTitleLabel.TextColor3 = theme.text
    GameTitleLabel.TextXAlignment = Enum.TextXAlignment.Right
    GameTitleLabel.Text = GAME_TITLE
    GameTitleLabel.Parent = MetaBlock

    local VersionLabel = Instance.new("TextLabel")
    VersionLabel.Name = "Version"
    VersionLabel.Size = UDim2.new(1, 0, 0, 14)
    VersionLabel.Position = UDim2.new(0, 0, 0, 17)
    VersionLabel.BackgroundTransparency = 1
    VersionLabel.Font = Fonts.regular
    VersionLabel.TextSize = 10
    VersionLabel.TextColor3 = theme.accent
    VersionLabel.TextXAlignment = Enum.TextXAlignment.Right
    VersionLabel.Text = SCRIPT_VERSION
    VersionLabel.Parent = MetaBlock

    -- Controles da Janela (Minimizar / Fechar)
    local WindowControls = Instance.new("Frame")
    WindowControls.Name = "WindowControls"
    WindowControls.Size = UDim2.new(0, 48, 1, 0)
    WindowControls.Position = UDim2.new(1, 0, 0.5, 0)
    WindowControls.AnchorPoint = Vector2.new(1, 0.5)
    WindowControls.BackgroundTransparency = 1
    WindowControls.Parent = Header

    local MinimizeButton = Instance.new("TextButton")
    MinimizeButton.Name = "Minimize"
    MinimizeButton.Size = UDim2.new(0, 22, 0, 22)
    MinimizeButton.Position = UDim2.new(0, 0, 0.5, 0)
    MinimizeButton.AnchorPoint = Vector2.new(0, 0.5)
    MinimizeButton.BackgroundColor3 = theme.bg
    MinimizeButton.BorderSizePixel = 0
    MinimizeButton.Font = Fonts.bold
    MinimizeButton.TextSize = 11
    MinimizeButton.TextColor3 = theme.muted
    MinimizeButton.Text = "—"
    MinimizeButton.AutoButtonColor = false
    MinimizeButton.Parent = WindowControls

    createCorner(MinimizeButton, 4)
    createStroke(MinimizeButton, theme.border, 1)

    local CloseButton = Instance.new("TextButton")
    CloseButton.Name = "Close"
    CloseButton.Size = UDim2.new(0, 22, 0, 22)
    CloseButton.Position = UDim2.new(0, 26, 0.5, 0)
    CloseButton.AnchorPoint = Vector2.new(0, 0.5)
    CloseButton.BackgroundColor3 = theme.bg
    CloseButton.BorderSizePixel = 0
    CloseButton.Font = Fonts.regular
    CloseButton.TextSize = 11
    CloseButton.TextColor3 = theme.muted
    CloseButton.Text = "✕"
    CloseButton.AutoButtonColor = false
    CloseButton.Parent = WindowControls

    createCorner(CloseButton, 4)
    createStroke(CloseButton, theme.border, 1)

    local HeaderSeparator = createSeparator(MainFrame, theme.border)
    HeaderSeparator.Position = UDim2.new(0, 0, 0, WINDOW_COLLAPSED_HEIGHT)

    -- ------------------------------------------------------------------------
    -- Conteúdo (Corpo + Rodapé)
    -- ------------------------------------------------------------------------
    local Content = Instance.new("Frame")
    Content.Name = "Content"
    Content.Size = UDim2.new(1, 0, 0, WINDOW_FULL_HEIGHT - WINDOW_COLLAPSED_HEIGHT - 1)
    Content.Position = UDim2.new(0, 0, 0, WINDOW_COLLAPSED_HEIGHT + 1)
    Content.BackgroundTransparency = 1
    Content.ClipsDescendants = true
    Content.Parent = MainFrame
    self.Content = Content

    -- Corpo: Linhas com Dot Leaders
    local Body = Instance.new("Frame")
    Body.Name = "Body"
    Body.Size = UDim2.new(1, 0, 0, 136)
    Body.Position = UDim2.new(0, 0, 0, 0)
    Body.BackgroundTransparency = 1
    Body.Parent = Content

    createPadding(Body, 12, 10, 14, 14)

    local BodyLayout = Instance.new("UIListLayout")
    BodyLayout.FillDirection = Enum.FillDirection.Vertical
    BodyLayout.SortOrder = Enum.SortOrder.LayoutOrder
    BodyLayout.Padding = UDim.new(0, 5)
    BodyLayout.Parent = Body

    local function createRow(parent: Instance, labelText: string, initialValue: string)
        local row = Instance.new("Frame")
        row.Name = "Row_" .. labelText
        row.Size = UDim2.new(1, 0, 0, 20)
        row.BackgroundTransparency = 1
        row.ClipsDescendants = true
        row.Parent = parent

        local dots = Instance.new("TextLabel")
        dots.Name = "Dots"
        dots.Size = UDim2.new(1, 0, 1, 0)
        dots.BackgroundTransparency = 1
        dots.Font = Fonts.regular
        dots.TextSize = 11
        dots.TextColor3 = theme.border
        dots.TextTransparency = 0.35
        dots.TextXAlignment = Enum.TextXAlignment.Center
        dots.TextYAlignment = Enum.TextYAlignment.Center
        dots.Text = "·············································································"
        dots.ZIndex = 1
        dots.Parent = row

        local label = Instance.new("TextLabel")
        label.Name = "Label"
        label.Position = UDim2.new(0, 0, 0, 0)
        label.Size = UDim2.new(0, 0, 1, 0)
        label.AutomaticSize = Enum.AutomaticSize.X
        label.BackgroundColor3 = theme.bg
        label.BackgroundTransparency = 0
        label.Font = Fonts.regular
        label.TextSize = 12
        label.TextColor3 = theme.muted
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.TextYAlignment = Enum.TextYAlignment.Center
        label.Text = labelText
        label.ZIndex = 2
        label.Parent = row

        local labelPad = Instance.new("UIPadding")
        labelPad.PaddingRight = UDim.new(0, 8)
        labelPad.Parent = label

        local value = Instance.new("TextLabel")
        value.Name = "Value"
        value.Position = UDim2.new(1, 0, 0, 0)
        value.AnchorPoint = Vector2.new(1, 0)
        value.Size = UDim2.new(0, 0, 1, 0)
        value.AutomaticSize = Enum.AutomaticSize.X
        value.BackgroundColor3 = theme.bg
        value.BackgroundTransparency = 0
        value.Font = Fonts.bold
        value.TextSize = 12
        value.TextColor3 = theme.text
        value.TextXAlignment = Enum.TextXAlignment.Right
        value.TextYAlignment = Enum.TextYAlignment.Center
        value.Text = initialValue
        value.ZIndex = 2
        value.Parent = row

        local valPad = Instance.new("UIPadding")
        valPad.PaddingLeft = UDim.new(0, 8)
        valPad.Parent = value

        return {
            Frame = row,
            SetValue = function(newVal: string, color: Color3?)
                value.Text = newVal
                if color then
                    value.TextColor3 = color
                end
            end,
            SetLabel = function(newLabel: string)
                label.Text = newLabel
            end,
        }
    end

    local initKey, initExp = getLuarmorKeyDetails()
    if opts.Key then initKey = opts.Key end
    if opts.Expires then initExp = opts.Expires end

    local rowSession = createRow(Body, "Sessão", "00:00:00")
    local rowKey = createRow(Body, "Key", initKey)
    local rowExpires = createRow(Body, "Expira", initExp)
    local rowExecutor = createRow(Body, "Executor", detectExecutor())
    local rowLocation = createRow(Body, "Localização", detectLocation())

    rowKey.SetValue(initKey, theme.accent)
    rowExpires.SetValue(initExp, theme.text)

    self.RowSession = rowSession
    self.RowKey = rowKey
    self.RowExpires = rowExpires
    self.RowExecutor = rowExecutor
    self.RowLocation = rowLocation

    -- Separador Corpo/Rodapé
    local FooterSeparator = createSeparator(Content, theme.border)
    FooterSeparator.Position = UDim2.new(0, 0, 0, 142)

    -- Rodapé: Métricas Alinhadas
    local Footer = Instance.new("Frame")
    Footer.Name = "Footer"
    Footer.Size = UDim2.new(1, 0, 0, 95)
    Footer.Position = UDim2.new(0, 0, 0, 143)
    Footer.BackgroundTransparency = 1
    Footer.Parent = Content

    createPadding(Footer, 8, 10, 14, 14)

    local MetricsGrid = Instance.new("Frame")
    MetricsGrid.Name = "MetricsGrid"
    MetricsGrid.Size = UDim2.new(1, 0, 0, 42)
    MetricsGrid.Position = UDim2.new(0, 0, 0, 0)
    MetricsGrid.BackgroundTransparency = 1
    MetricsGrid.Parent = Footer

    local function createMetricPair(parent: Instance, labelText: string, initialValue: string, posX: number, posY: number)
        local cell = Instance.new("Frame")
        cell.Name = "Metric_" .. labelText
        cell.Size = UDim2.new(0.5, -4, 0, 18)
        cell.Position = UDim2.new(posX, 0, posY, 0)
        cell.BackgroundTransparency = 1
        cell.Parent = parent

        local lbl = Instance.new("TextLabel")
        lbl.Name = "Label"
        lbl.Size = UDim2.new(0, 0, 1, 0)
        lbl.AutomaticSize = Enum.AutomaticSize.X
        lbl.BackgroundTransparency = 1
        lbl.Font = Fonts.regular
        lbl.TextSize = 11
        lbl.TextColor3 = theme.muted
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.Text = labelText .. ":"
        lbl.Parent = cell

        local val = Instance.new("TextLabel")
        val.Name = "Value"
        val.Size = UDim2.new(0, 0, 1, 0)
        val.Position = UDim2.new(0, 64, 0, 0)
        val.AutomaticSize = Enum.AutomaticSize.X
        val.BackgroundTransparency = 1
        val.Font = Fonts.bold
        val.TextSize = 11
        val.TextColor3 = theme.text
        val.TextXAlignment = Enum.TextXAlignment.Left
        val.Text = initialValue
        val.Parent = cell

        return {
            SetValue = function(newVal: string, color: Color3?)
                val.Text = newVal
                if color then
                    val.TextColor3 = color
                end
            end,
        }
    end

    local metricPing = createMetricPair(MetricsGrid, "Ping", "0 ms", 0, 0)
    local metricFps = createMetricPair(MetricsGrid, "FPS", "60", 0.5, 0)
    local metricMem = createMetricPair(MetricsGrid, "Mem", "0 MB", 0, 0.5)
    local metricPlayers = createMetricPair(MetricsGrid, "Jogadores", "1/1", 0.5, 0.5)

    self.MetricPing = metricPing
    self.MetricFps = metricFps
    self.MetricMem = metricMem
    self.MetricPlayers = metricPlayers

    -- Botão Discord
    local DiscordButton = Instance.new("TextButton")
    DiscordButton.Name = "DiscordButton"
    DiscordButton.Size = UDim2.new(1, 0, 0, 24)
    DiscordButton.Position = UDim2.new(0, 0, 1, -24)
    DiscordButton.BackgroundColor3 = theme.surface
    DiscordButton.BorderSizePixel = 0
    DiscordButton.Font = Fonts.regular
    DiscordButton.TextSize = 11
    DiscordButton.TextColor3 = theme.muted
    DiscordButton.Text = DISCORD_DISPLAY
    DiscordButton.AutoButtonColor = false
    DiscordButton.Parent = Footer

    createCorner(DiscordButton, 6)
    local discordStroke = createStroke(DiscordButton, theme.border, 1)

    registerConn(DiscordButton.MouseEnter:Connect(function()
        tween(DiscordButton, 0.15, {BackgroundColor3 = Color3.fromRGB(34, 34, 46)})
        tween(DiscordButton, 0.15, {TextColor3 = theme.text})
        tween(discordStroke, 0.15, {Color = theme.accent})
    end))

    registerConn(DiscordButton.MouseLeave:Connect(function()
        tween(DiscordButton, 0.15, {BackgroundColor3 = theme.surface})
        tween(DiscordButton, 0.15, {TextColor3 = theme.muted})
        tween(discordStroke, 0.15, {Color = theme.border})
    end))

    local copyDebounce = false
    registerConn(DiscordButton.MouseButton1Click:Connect(function()
        if copyDebounce then return end
        copyDebounce = true

        setClipboardSafe(DISCORD_INVITE_URL)

        DiscordButton.Text = "Copiado"
        tween(DiscordButton, 0.12, {TextColor3 = theme.green})

        task.delay(1.8, function()
            if self.RunToken ~= runToken then return end
            DiscordButton.Text = DISCORD_DISPLAY
            tween(DiscordButton, 0.2, {TextColor3 = theme.muted})
            copyDebounce = false
        end)
    end))

    -- ------------------------------------------------------------------------
    -- Arraste (Draggable) & Ações de Janela
    -- ------------------------------------------------------------------------
    local isDragging = false
    local dragStart = Vector3.zero
    local startPos = MainFrame.Position

    registerConn(Header.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            isDragging = true
            dragStart = input.Position
            startPos = MainFrame.Position

            local inputEndedConn: RBXScriptConnection? = nil
            inputEndedConn = input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    isDragging = false
                    if inputEndedConn then
                        inputEndedConn:Disconnect()
                    end
                end
            end)
        end
    end))

    registerConn(UserInputService.InputChanged:Connect(function(input)
        if isDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            MainFrame.Position = UDim2.new(
                startPos.X.Scale,
                startPos.X.Offset + delta.X,
                startPos.Y.Scale,
                startPos.Y.Offset + delta.Y
            )
        end
    end))

    local isMinimized = false
    self.IsMinimized = false

    local function setMinimizedState(min: boolean)
        isMinimized = min
        self.IsMinimized = isMinimized
        if isMinimized then
            MinimizeButton.Text = "+"
            tween(MainFrame, 0.2, {Size = UDim2.new(0, WINDOW_WIDTH, 0, WINDOW_COLLAPSED_HEIGHT)})
            task.delay(0.2, function()
                if isMinimized then Content.Visible = false end
            end)
        else
            MinimizeButton.Text = "—"
            Content.Visible = true
            tween(MainFrame, 0.2, {Size = UDim2.new(0, WINDOW_WIDTH, 0, WINDOW_FULL_HEIGHT)})
        end
    end

    registerConn(MinimizeButton.MouseButton1Click:Connect(function()
        setMinimizedState(not isMinimized)
    end))

    registerConn(CloseButton.MouseButton1Click:Connect(function()
        self:Hide()
    end))

    local function setupWindowButtonHover(btn: TextButton)
        registerConn(btn.MouseEnter:Connect(function()
            tween(btn, 0.12, {BackgroundColor3 = theme.surface, TextColor3 = theme.text})
        end))
        registerConn(btn.MouseLeave:Connect(function()
            tween(btn, 0.12, {BackgroundColor3 = theme.bg, TextColor3 = theme.muted})
        end))
    end
    setupWindowButtonHover(MinimizeButton)
    setupWindowButtonHover(CloseButton)

    -- Teclas de Atalho: RightShift / Insert (ou customizadas)
    local hotkeys = opts.Hotkeys or { Enum.KeyCode.RightShift, Enum.KeyCode.Insert }
    registerConn(UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        for _, code in ipairs(hotkeys) do
            if input.KeyCode == code then
                self:Toggle()
                break
            end
        end
    end))

    -- ------------------------------------------------------------------------
    -- Loop de Telemetria O(1)
    -- ------------------------------------------------------------------------
    local sessionStartTime = os.time()
    if opts.AutoStartTelemetry ~= false then
        local renderFrameCount = 0
        local lastFpsTime = os.clock()
        local renderConn = nil
        pcall(function()
            renderConn = RunService.RenderStepped:Connect(function()
                renderFrameCount = renderFrameCount + 1
            end)
        end)
        if renderConn then
            registerConn(renderConn)
            self._renderConn = renderConn
        end

        task.spawn(function()
            while self.RunToken == runToken do
                pcall(function()
                    -- 1. Tempo de Sessão
                    local elapsed = os.time() - sessionStartTime
                    local h = math.floor(elapsed / 3600)
                    local m = math.floor((elapsed % 3600) / 60)
                    local s = elapsed % 60
                    rowSession.SetValue(string.format("%02d:%02d:%02d", h, m, s))

                    -- 2. Localização atual
                    rowLocation.SetValue(detectLocation())

                    -- 3. Ping
                    local pingMs = 0
                    local pingSuccess, pingVal = pcall(function()
                        return LocalPlayer:GetNetworkPing()
                    end)
                    if pingSuccess and pingVal then
                        pingMs = math.floor(pingVal * 1000)
                    end
                    metricPing.SetValue(tostring(pingMs) .. " ms")

                    -- 4. FPS Real (RenderStepped)
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
                    metricFps.SetValue(tostring(fps))

                    -- 5. Memória
                    local memMb = 0
                    local memSuccess, memVal = pcall(function()
                        return Stats:GetTotalMemoryUsageMb()
                    end)
                    if memSuccess and memVal then
                        memMb = math.floor(memVal)
                    end
                    metricMem.SetValue(tostring(memMb) .. " MB")

                    -- 6. Jogadores
                    local curPlayers = #Players:GetPlayers()
                    local maxPlayers = Players.MaxPlayers or 12
                    metricPlayers.SetValue(tostring(curPlayers) .. "/" .. tostring(maxPlayers))
                end)
                task.wait(1.0)
            end
        end)
    end

    -- Limpeza global do AnimeBreaker
    local function unloadFn()
        self:Destroy()
    end

    if KittyGs then
        KittyGs.Overview = KittyGs.Overview or {}
        KittyGs.Overview.Unload = unloadFn
    end
    env.AnimeBreakerOverviewUnload = unloadFn
    _G.AnimeBreakerOverviewUnload = unloadFn

    self._setMinimizedState = setMinimizedState
    return self
end

-- ============================================================================
-- 4. MÉTODOS DE CONTROLE DA INSTÂNCIA
-- ============================================================================
function OverviewModule:SetKeyStatus(status: string)
    if self.RowKey then
        self.RowKey.SetValue(status, self.Theme.accent)
    end
end

function OverviewModule:SetExpires(expires: string)
    if self.RowExpires then
        self.RowExpires.SetValue(expires, self.Theme.text)
    end
end

function OverviewModule:SetLocation(loc: string)
    if self.RowLocation then
        self.RowLocation.SetValue(loc)
    end
end

function OverviewModule:Toggle()
    if not self.MainFrame then return end
    self.MainFrame.Visible = not self.MainFrame.Visible
    if self.MainFrame.Visible and self.IsMinimized then
        self.Content.Visible = false
    elseif self.MainFrame.Visible then
        self.Content.Visible = true
    end
end

function OverviewModule:Show()
    if not self.MainFrame then return end
    self.MainFrame.Visible = true
    if not self.IsMinimized then
        self.Content.Visible = true
    end
end

function OverviewModule:Hide()
    if not self.MainFrame then return end
    self.MainFrame.Visible = false
end

function OverviewModule:Minimize(state: boolean?)
    if self._setMinimizedState then
        if state == nil then
            self._setMinimizedState(not self.IsMinimized)
        else
            self._setMinimizedState(state)
        end
    end
end

function OverviewModule:Destroy()
    local oldToken = self.RunToken
    self.RunToken = nil
    local env = (typeof(getgenv) == "function" and getgenv()) or _G
    local KittyGs = env.KittyGs
    if KittyGs and KittyGs.Overview then
        if KittyGs.Overview.RunToken == oldToken or oldToken == nil then
            KittyGs.Overview.RunToken = nil
        end
        KittyGs.Overview.Unload = nil
    end
    if env.AnimeBreakerOverviewRunToken == oldToken or oldToken == nil then
        env.AnimeBreakerOverviewRunToken = nil
    end
    if _G.AnimeBreakerOverviewRunToken == oldToken or oldToken == nil then
        _G.AnimeBreakerOverviewRunToken = nil
    end
    if self._renderConn then
        pcall(function() self._renderConn:Disconnect() end)
        self._renderConn = nil
    end
    if self.Connections then
        for _, conn in ipairs(self.Connections) do
            pcall(function() conn:Disconnect() end)
        end
        table.clear(self.Connections)
    end
    if self.Gui then
        self.Gui:Destroy()
        self.Gui = nil
    end
    if env.AnimeBreakerOverviewUnload then
        env.AnimeBreakerOverviewUnload = nil
    end
    if _G.AnimeBreakerOverviewUnload then
        _G.AnimeBreakerOverviewUnload = nil
    end
end

OverviewModule.Unload = OverviewModule.Destroy

-- Metamétodo __call para suporte a invocação direta
setmetatable(OverviewModule, {
    __call = function(_, ...)
        return OverviewModule.new(...)
    end,
})

-- ============================================================================
-- 5. RESOLUÇÃO DE CARREGAMENTO (VARARG AUTO-INVOCATION)
-- ============================================================================
-- Se o arquivo foi invocado via loadstring(...) (...) passando argumentos,
-- auto-instancia e retorna o objeto. Se não, retorna a tabela do módulo.
local passedArgs = { ... }
if #passedArgs > 0 and passedArgs[1] ~= nil then
    return OverviewModule.new(table.unpack(passedArgs))
end

return OverviewModule
