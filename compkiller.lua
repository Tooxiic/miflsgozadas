local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")
local Compkiller = {
	Version = "2.6",
	Logo = "rbxassetid://123770965867756",
	Windows = {},
	Scale = {
		Window = UDim2.new(0, 485, 0, 565),
		Mobile = UDim2.new(0, 450, 0, 375),
		TabOpen = 185,
		TabClose = 85,
	},
	PerformanceMode = false,
	WindowsNil = {},
	NilFolder = Instance.new("Folder"),
	ArcylicParent = CurrentCamera,
	ProtectGui = protect_gui or protectgui or (syn and syn.protect_gui) or function(s)
		return s
	end,
}
function Compkiller:_RandomString(): string
	return "CK="
		.. string.char(
			math.random(64, 102),
			math.random(64, 102),
			math.random(64, 102),
			math.random(64, 102),
			math.random(64, 102),
			math.random(64, 102),
			math.random(64, 102),
			math.random(64, 102),
			math.random(64, 102),
			math.random(64, 102),
			math.random(64, 102),
			math.random(64, 102),
			math.random(64, 102),
			math.random(64, 102),
			math.random(64, 102),
			math.random(64, 102),
			math.random(64, 102),
			math.random(64, 102),
			math.random(64, 102),
			math.random(64, 102)
		)
end
function Compkiller:_Animation(Self: Instance, Info: TweenInfo, Property: { [K]: V })
	local Tween = TweenService:Create(Self, Info or TweenInfo.new(0.25), Property)

	Tween:Play()

	return Tween
end
function Compkiller:CacheImage(id: string): string
	if not Compkiller.SecureMode or not id or not id:byte() then
		return id or ""
	end

	assert(Compkiller.SecureMode, "please use Compkiller:Security(< string >) before cache image")
	assert(Compkiller.CacheDirectory, "please use Compkiller:Security(< string >) before cache image")

	local ids = string.match(id, "%d+")

	if ids == nil then
		return id
	end

	local Hash = Compkiller.Hash(id)

	local cache_path = string.format("%s/cache-%s.png", Compkiller.CacheDirectory, Hash)

	if isfile(cache_path) then
		return (getcustomasset or getsynasset or function()
			return ""
		end)(cache_path)
	end

	local imgSize = Compkiller.SecurityConfig.ImageScale

	local imagesize = (imgSize and string.format("%sx%s", tostring(math.round(imgSize)), tostring(math.round(imgSize))))
		or "150x150"

	if imagesize == nil then
		return ""
	end

	local endpoint = string.format(
		"https://thumbnails.roblox.com/v1/assets?assetIds=%s&size=%s&format=Png&isCircular=false",
		ids,
		imagesize
	)

	local json = game:HttpGet(endpoint)

	local JSON_Decode = select(
		2,
		pcall(function()
			return HttpService:JSONDecode(json)
		end)
	)

	if
		typeof(JSON_Decode) == "table"
		and JSON_Decode
		and JSON_Decode.data
		and JSON_Decode.data[1]
		and JSON_Decode.data[1].imageUrl
		and JSON_Decode.data[1].state == "Completed"
	then
		task.wait()
		local en = JSON_Decode.data[1].imageUrl

		writefile(cache_path, game:HttpGet(en))

		task.wait()

		return (getcustomasset or getsynasset or function()
			return ""
		end)(cache_path)
	end

	return ""
end
function Compkiller:Loader(IconId, Duration)
	local CompKiller = Instance.new("ScreenGui")

	CompKiller.Name = Compkiller:_RandomString()
	CompKiller.Parent = CoreGui
	CompKiller.Enabled = true
	CompKiller.ResetOnSpawn = false
	CompKiller.IgnoreGuiInset = true
	CompKiller.ZIndexBehavior = Enum.ZIndexBehavior.Global

	local Loader = Instance.new("Frame")
	local Icon = Instance.new("ImageLabel")
	local Vignette = Instance.new("ImageLabel")

	Loader.Name = Compkiller:_RandomString()
	Loader.Parent = CompKiller
	Loader.AnchorPoint = Vector2.new(0.5, 0.5)
	Loader.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	Loader.BackgroundTransparency = 1
	Loader.BorderColor3 = Color3.fromRGB(0, 0, 0)
	Loader.BorderSizePixel = 0
	Loader.Position = UDim2.new(0.5, 0, 0.5, 0)
	Loader.Size = UDim2.new(1, 0, 1, 0)

	Icon.Name = Compkiller:_RandomString()
	Icon.Parent = Loader
	Icon.AnchorPoint = Vector2.new(0.5, 0.5)
	Icon.BackgroundTransparency = 1.000
	Icon.BorderColor3 = Color3.fromRGB(0, 0, 0)
	Icon.BorderSizePixel = 0
	Icon.Position = UDim2.new(0.5, 0, 0.5, 0)
	Icon.Size = UDim2.new(0, 750, 0, 750)
	Icon.ZIndex = 100
	Icon.Image = IconId or Compkiller.Logo
	Icon.ImageTransparency = 1

	Vignette.Name = Compkiller:_RandomString()
	Vignette.Parent = Loader
	Vignette.BackgroundTransparency = 1.000
	Vignette.BorderColor3 = Color3.fromRGB(27, 42, 53)
	Vignette.BorderSizePixel = 0
	Vignette.Size = UDim2.new(1, 0, 1, 0)
	Vignette.Image = Compkiller:CacheImage("rbxassetid://18720640102")
	Vignette.ImageColor3 = Color3.fromRGB(228, 20, 85)
	Vignette.ImageTransparency = 1
	Vignette.AnchorPoint = Vector2.new(0.5, 0.5)
	Vignette.Position = UDim2.fromScale(0.5, 0.5)

	Compkiller:_Animation(Loader, TweenInfo.new(0.55, Enum.EasingStyle.Quint), {
		BackgroundTransparency = 0.5,
	})

	local Event = Instance.new("BindableEvent")

	task.delay(0.5, function()
		Compkiller:_Animation(Icon, TweenInfo.new(0.75, Enum.EasingStyle.Quint), {
			ImageTransparency = 0.01,
			Size = UDim2.new(0, 200, 0, 200),
		})

		task.delay(0.25, function()
			Compkiller:_Animation(Vignette, TweenInfo.new(5), {
				ImageTransparency = 0.2,
			})

			task.wait(Duration or 4.5)

			Compkiller:_Animation(Vignette, TweenInfo.new(3, Enum.EasingStyle.Quint, Enum.EasingDirection.InOut), {
				Size = UDim2.new(2, 0, 2, 0),
			})

			Compkiller:_Animation(Icon, TweenInfo.new(0.75, Enum.EasingStyle.Quint, Enum.EasingDirection.InOut), {
				ImageTransparency = 1,
			})

			Compkiller:_Animation(Loader, TweenInfo.new(1.5, Enum.EasingStyle.Quint, Enum.EasingDirection.InOut), {
				BackgroundTransparency = 1,
			})

			task.delay(0.1, function()
				Compkiller:_Animation(Vignette, TweenInfo.new(1, Enum.EasingStyle.Quint, Enum.EasingDirection.InOut), {
					ImageTransparency = 1,
				})

				task.wait(0.2)

				task.delay(3, function()
					CompKiller:Destroy()
				end)
			end)

			task.delay(0.6, function()
				Event:Fire()
			end)
		end)
	end)

	return {
		yield = function()
			return Event.Event:Wait()
		end,
	}
end

return Compkiller
