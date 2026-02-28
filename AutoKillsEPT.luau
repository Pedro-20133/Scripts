local players = game:GetService("Players")
local player = players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Carregando a Interface Rayfield
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
	Name = "Auto Kills EPT",
	Icon = 0, -- Icon in Topbar. Can use Lucide Icons (string) or Roblox Image (number). 0 to use no icon (default).
	LoadingTitle = "Interface Suite",
	LoadingSubtitle = "by Sirius",
	ShowText = "Auto Kills EPT", -- for mobile users to unhide Rayfield, change if you'd like
	Theme = "Ocean", -- Check https://docs.sirius.menu/rayfield/configuration/themes

	ToggleUIKeybind = "K", -- The keybind to toggle the UI visibility (string like "K" or Enum.KeyCode)

	DisableRayfieldPrompts = false,
	DisableBuildWarnings = false, -- Prevents Rayfield from emitting warnings when the script has a version mismatch with the interface.

	ConfigurationSaving = {
		Enabled = true,
		FolderName = nil, -- Create a custom folder for your hub/game
		FileName = "AutoKillsEPT"
	},

	Discord = {
		Enabled = false, -- Prompt the user to join your Discord server if their executor supports it
		Invite = "noinvitelink", -- The Discord invite code, do not include Discord.gg/. E.g. Discord.gg/ ABCD would be ABCD
		RememberJoins = true -- Set this to false to make them join the Discord every time they load it up
	},

	KeySystem = false, -- Set this to true to use our key system
	KeySettings = {
		Title = "Untitled",
		Subtitle = "Key System",
		Note = "No method of obtaining the key is provided", -- Use this to tell the user how to get a key
		FileName = "Key", -- It is recommended to use something unique, as other scripts using Rayfield may overwrite your key file
		SaveKey = true, -- The user's key will be saved, but if you change the key, they will be unable to use your script
		GrabKeyFromSite = false, -- If this is true, set Key below to the RAW site you would like Rayfield to get the key from
		Key = {"Hello"} -- List of keys that the system will accept, can be RAW file links (pastebin, github, etc.) or simple strings ("hello", "key22")
	}
})

-- ==========================================
-- TAB PVP
-- ==========================================
local PvpTab = Window:CreateTab("PVP Tab", 4483362458)

_G.AtaqueLigado = false
_G.PlayerSelecionado = ""

-- Função para pegar o Humanoid atualizado (evita erro pós-morte)
local function getHumanoid()
	local char = player.Character or player.CharacterAdded:Wait()
	return char:WaitForChild("Humanoid")
end

local SlidersLbl = PvpTab:CreateLabel("Movement Tweaks")

local MoveSlider = PvpTab:CreateSlider({
	Name = "Set Walk Speed",
	Range = {16, 400},
	Increment = 1,
	Suffix = "Speed",
	CurrentValue = 16,
	Flag = "MoveSlider",
	Callback = function(Value)
		local hum = getHumanoid()
		if hum then hum.WalkSpeed = Value end
	end,
})

local JumpSlider = PvpTab:CreateSlider({
	Name = "Set Jump Force",
	Range = {50, 300},
	Increment = 1,
	Suffix = "Jump",
	CurrentValue = 50,
	Flag = "JumpSlider",
	Callback = function(Value)
		local hum = getHumanoid()
		if hum then hum.JumpPower = Value end
	end,
})

local AutoKillLbl = PvpTab:CreateLabel("Auto Kill System")

local function getPlayerNames()
	local names = {}
	for _, p in ipairs(players:GetPlayers()) do
		if p ~= player then 
			table.insert(names, p.Name)
		end
	end
	return names
end

local DropdownPlayers = PvpTab:CreateDropdown({
	Name = "Target Player",
	Options = getPlayerNames(),
	CurrentOption = {"Selecione um Player"},
	MultipleOptions = false,
	Callback = function(Option)
		_G.PlayerSelecionado = typeof(Option) == "table" and Option[1] or Option
	end,
})

local function safeRefresh()
	pcall(function()
		DropdownPlayers:Refresh(getPlayerNames(), true)
	end)
end

players.PlayerAdded:Connect(safeRefresh)
players.PlayerRemoving:Connect(safeRefresh)

-- Desliga o ataque se VOCÊ morrer
player.CharacterAdded:Connect(function(character)
	local hum = character:WaitForChild("Humanoid")
	hum.Died:Connect(function()
		_G.AtaqueLigado = false
	end)
end)

local ButtonStart = PvpTab:CreateButton({
	Name = "Iniciar Auto Kill",
	Callback = function()
		if _G.PlayerSelecionado == "" or _G.PlayerSelecionado == "Selecione um Player" then
			Rayfield:Notify({Title = "Erro", Content = "Selecione um alvo primeiro!", Duration = 3})
			return
		end

		_G.AtaqueLigado = true
		Rayfield:Notify({Title = "Auto Kill", Content = "Caçando: " .. _G.PlayerSelecionado})

		while _G.AtaqueLigado do
			local targetPlayer = players:FindFirstChild(_G.PlayerSelecionado)
			local targetChar = targetPlayer and targetPlayer.Character
			local targetHumanoid = targetChar and targetChar:FindFirstChildOfClass("Humanoid")
			local targetHRP = targetChar and targetChar:FindFirstChild("HumanoidRootPart")

			if not targetHumanoid or targetHumanoid.Health <= 0 then
				Rayfield:Notify({Title = "Missão Concluída", Content = "Alvo morto! Retornando..."})
				break 
			end

			local myCharacter = player.Character
			local myHRP = myCharacter and myCharacter:FindFirstChild("HumanoidRootPart")

			if myHRP and targetHRP then
				myHRP.CFrame = targetHRP.CFrame * CFrame.new(0, 5, 0)

				local statusEffect = ReplicatedStorage:FindFirstChild("Status_Effect")
				if statusEffect and statusEffect:FindFirstChild("Event") then
					statusEffect.Event:Fire("on_heavy", targetChar, myCharacter, 1.5)
				end

				local library = ReplicatedStorage:FindFirstChild("Library")
				if library and library:FindFirstChild("Network") then
					library.Network:FireServer("Damage", targetHumanoid, 40)
				end
			end
			task.wait(0.1)
		end

		_G.AtaqueLigado = false
		task.wait(0.3)

		-- Retorno para base
		local tycoons = workspace:FindFirstChild("Tycoons")
		local minhaBase = tycoons and tycoons:FindFirstChild(player.Name)
		if minhaBase and minhaBase:FindFirstChild("Assets") and minhaBase.Assets:FindFirstChild("Lasers") then
			local laserPart = minhaBase.Assets.Lasers:FindFirstChildWhichIsA("BasePart") or minhaBase.Assets.Lasers.PrimaryPart
			if laserPart and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
				player.Character.HumanoidRootPart.CFrame = laserPart.CFrame
				Rayfield:Notify({Title = "Segurança", Content = "De volta à base!"})
			end
		end
	end,
})

local ButtonStop = PvpTab:CreateButton({
	Name = "Parar Ataque Manualmente",
	Callback = function()
		_G.AtaqueLigado = false
	end,
})

local MapLbl = PvpTab:CreateLabel("Map Teleports")

local TpOnCenterButton = PvpTab:CreateButton({
	Name = "Tp on Center",
	Callback = function()
		-- CORREÇÃO: Pegar o Personagem e a HRP dentro do Callback
		local char = player.Character
		local myHRP = char and char:FindFirstChild("HumanoidRootPart")
		local centerPart = workspace:FindFirstChild("Map") and workspace.Map:FindFirstChild("Center")

		if myHRP and centerPart then
			myHRP.CFrame = centerPart.CFrame + Vector3.new(0, 3, 0) -- Adiciona 3 studs para não bugar no chão
			Rayfield:Notify({Title = "Teleporte", Content = "Teleportado para o centro!"})
		else
			Rayfield:Notify({Title = "Erro", Content = "Local 'Center' não encontrado no Mapa!", Duration = 3})
		end
	end,
})

-- ==========================================
-- TAB FARMER
-- ==========================================
local FarmTab = Window:CreateTab("Farm Tab", nil)

local FarmLabel = FarmTab:CreateLabel("Configurações de Farm")

-- ==========================================
-- TAB MORE
-- ==========================================
local MoreTab = Window:CreateTab("More Tab", nil)

local CloseButton = MoreTab:CreateButton({
	Name = "Close Script",
	Callback = function()
		Rayfield:Destroy()
	end,
})

local KickButton = MoreTab:CreateButton({
	Name = "Auto Kick",
	Callback = function()
		player:Kick("Script finalizado pelo usuário.")
	end,
})
