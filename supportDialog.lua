--[[
    ════════════════════════════════════════════════════════════════════════════════
    🐱 KittyHub — Support Dialog Helper Module
    Jogo: Anime Breaker
    Padrão Arquitetural: KittyBrain (Obsidian Ultra / LinoriaLib Inspired)

    Uso:
        local SupportDialogFactory = loadstring(readfile("SupportDialog.lua"))()
        local ShowSupportDialog = SupportDialogFactory(Window)
        ShowSupportDialog(opts)
    ════════════════════════════════════════════════════════════════════════════════
]]

local HttpService = game:GetService("HttpService")

local env = (typeof(getgenv) == "function" and getgenv()) or _G
local rawEnv = (typeof(getfenv) == "function" and getfenv()) or {}

local syn = rawEnv.syn or rawget(_G, "syn") or (env and env.syn)
local http = rawEnv.http or rawget(_G, "http") or (env and env.http)
local http_request = rawEnv.http_request or rawget(_G, "http_request") or (env and env.http_request)
local request = rawEnv.request or rawget(_G, "request") or (env and env.request)
local setclipboard = rawEnv.setclipboard or rawget(_G, "setclipboard") or (env and env.setclipboard)
local toclipboard = rawEnv.toclipboard or rawget(_G, "toclipboard") or (env and env.toclipboard)

return function(Window)
	return function(opts)
		opts = opts or {}
		local targetWindow = Window or opts.Window
		local inviteCode = opts.InviteCode or opts.inviteCode or "wcprsvmcp8"
		local fullDiscordLink = "https://discord.gg/" .. inviteCode
		local dialogTitle = opts.Title or "SKIP KEY SYSTEM"
		local dialogDescription = opts.Description
			or "Quer pular as chaves? Compre Premium no Discord.\n\nWant to skip keys? Buy Premium on Discord."
		local library = opts.Library

		local function promptDiscordInvite()
			local httpRequest = (syn and syn.request) or (http and http.request) or http_request or request

			if httpRequest then
				pcall(function()
					httpRequest({
						Url = "http://127.0.0.1:6463/rpc?v=1",
						Method = "POST",
						Headers = {
							["Content-Type"] = "application/json",
							["Origin"] = "https://discord.com",
						},
						Body = HttpService:JSONEncode({
							cmd = "INVITE_BROWSER",
							args = { code = inviteCode },
							nonce = HttpService:GenerateGUID(false),
						}),
					})
				end)
			end

			if setclipboard then
				setclipboard(fullDiscordLink)
			elseif toclipboard then
				toclipboard(fullDiscordLink)
			end
		end

		local function showCopiedFeedback()
			if targetWindow and typeof(targetWindow.AddDialog) == "function" then
				local successDialog = targetWindow:AddDialog("CopiedDialog", {
					Title = "COPIED",
					Description = "Convite do Discord copiado!\n\nDiscord invite copied!",
					AutoDismiss = true,
					OutsideClickDismiss = true,
					FooterButtons = {
						Close = {
							Title = "Close",
							Variant = "Primary",
							Order = 1,
						},
					},
				})

				task.delay(3, function()
					if successDialog then
						pcall(function()
							if successDialog.Dismiss then
								successDialog:Dismiss()
							elseif successDialog.Close then
								successDialog:Close()
							end
						end)
					end
				end)
			elseif library and typeof(library.Notify) == "function" then
				pcall(function()
					library:Notify({
						Title = "COPIED",
						Description = "Convite do Discord copiado!\n\nDiscord invite copied!",
						Time = 3,
					})
				end)
			end
		end

		-- Direct invite action without opening the prompt dialog
		if opts.DirectInvite then
			promptDiscordInvite()
			showCopiedFeedback()
			return nil
		end

		-- Presentation via Window:AddDialog
		if targetWindow and typeof(targetWindow.AddDialog) == "function" then
			return targetWindow:AddDialog(opts.DialogId or "SkipKeyDialog", {
				Title = dialogTitle,
				Description = dialogDescription,
				AutoDismiss = (opts.AutoDismiss ~= nil) and opts.AutoDismiss or true,
				OutsideClickDismiss = (opts.OutsideClickDismiss ~= nil) and opts.OutsideClickDismiss or true,
				FooterButtons = {
					Buy = {
						Title = opts.BuyButtonTitle or "Discord (Buy)",
						Variant = "Primary",
						Order = 1,
						Callback = function()
							promptDiscordInvite()
							showCopiedFeedback()
							if typeof(opts.OnBuy) == "function" then
								pcall(opts.OnBuy)
							end
						end,
					},
					Skip = {
						Title = opts.CloseButtonTitle or "Close",
						Variant = "Secondary",
						Order = 2,
						Callback = function()
							if typeof(opts.OnClose) == "function" then
								pcall(opts.OnClose)
							end
						end,
					},
				},
			})
		else
			-- Fallback: invoke desktop invite, copy link, and display feedback
			promptDiscordInvite()
			showCopiedFeedback()
			return nil
		end
	end
end
