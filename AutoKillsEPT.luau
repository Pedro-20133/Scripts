local players = game:GetService("Players")
local player = players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Caso o jogo seja outro
if game.PlaceId ~= 10253248401 and game.GameId ~= 10253248401 then
	player:Kick("Este script não suporta este jogo.")
	return
end

-- Carregando a Interface Rayfield
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
	Name = "Script for EPT",
	Icon = 0,
	LoadingTitle = "Interface Suite",
	LoadingSubtitle = "by Sirius",
	Theme = "Ocean",
	ToggleUIKeybind = Enum.KeyCode.K,
	ConfigurationSaving = {
		Enabled = true,
		FolderName = "EPT_Scripts",
		FileName = "AutoKillsEPT"
	}
})

-- Variáveis Globais de Controle
_G.DinheiroNoPlayer = 0
_G.DinheiroNoColetor = 0
_G.AutoTycoonLIGADO = false
_G.AutoColectBoxsLIGADO = false
_G.AtaqueLigado = false
_G.PlayerSelecionado = ""

-- Função para limpar texto "$135" -> 135
local function limparValor(texto)
	local apenasNumeros = texto:gsub("%D", "") 
	return tonumber(apenasNumeros) or 0
end

-- ==========================================
-- TAB PVP
-- ==========================================
local PvpTab = Window:CreateTab("PVP Tab", 4483362458)

local function getHumanoid()
	local char = player.Character or player.CharacterAdded:Wait()
	return char:WaitForChild("Humanoid")
end

PvpTab:CreateSlider({
	Name = "Set Walk Speed",
	Range = {16, 400},
	Increment = 1,
	CurrentValue = 16,
	Callback = function(Value)
		local hum = getHumanoid()
		if hum then hum.WalkSpeed = Value end
	end,
})

local DropdownPlayers = PvpTab:CreateDropdown({
	Name = "Target Player",
	Options = {},
	CurrentOption = {"Selecione um Player"},
	Callback = function(Option)
		_G.PlayerSelecionado = typeof(Option) == "table" and Option[1] or Option
	end,
})

local function refreshPlayers()
	local names = {}
	for _, p in ipairs(players:GetPlayers()) do
		if p ~= player then table.insert(names, p.Name) end
	end
	DropdownPlayers:Refresh(names, true)
end
players.PlayerAdded:Connect(refreshPlayers)
players.PlayerRemoving:Connect(refreshPlayers)
refreshPlayers()

PvpTab:CreateButton({
	Name = "Iniciar Auto Kill",
	Callback = function()
		if _G.PlayerSelecionado == "" or _G.PlayerSelecionado == "Selecione um Player" then
			Rayfield:Notify({Title = "Erro", Content = "Selecione um alvo!"})
			return
		end
		_G.AtaqueLigado = true
		while _G.AtaqueLigado do
			local target = players:FindFirstChild(_G.PlayerSelecionado)
			local tChar = target and target.Character
			local tHRP = tChar and tChar:FindFirstChild("HumanoidRootPart")
			local myHRP = player.Character and player.Character:FindFirstChild("HumanoidRootPart")

			if tHRP and myHRP then
				myHRP.CFrame = tHRP.CFrame * CFrame.new(0, 5, 0)
				ReplicatedStorage.Library.Network:FireServer("Damage", tChar.Humanoid, 40)
			end
			task.wait(0.1)
		end
	end,
})

PvpTab:CreateButton({
	Name = "Parar Ataque",
	Callback = function() _G.AtaqueLigado = false end,
})

-- ==========================================
-- TAB FARMER
-- ==========================================
local FarmTab = Window:CreateTab("Farm Tab", nil)

local MoneyPlayerLabel = FarmTab:CreateLabel("Seu Dinheiro: $0")
local MoneyTycoonLabel = FarmTab:CreateLabel("No Coletor: $0")

-- Loop de Atualização de Dinheiro (Monitor)
-- Função de monitoramento atualizada para garantir que o valor seja SEMPRE um número
task.spawn(function()
	while true do
		pcall(function()
			local stats = player:FindFirstChild("leaderstats")
			if stats and stats:FindFirstChild("Money") then
				_G.DinheiroNoPlayer = stats.Money.Value
				MoneyPlayerLabel:Set("Seu Dinheiro: $" .. _G.DinheiroNoPlayer)
			end

			local tycoon = workspace.Tycoons:FindFirstChild(player.Name)
			if tycoon and tycoon:FindFirstChild("Auxiliary") then
				local label = tycoon.Auxiliary.Collector.Screen.SurfaceGui.TextLabel
				_G.DinheiroNoColetor = limparValor(label.Text)
				MoneyTycoonLabel:Set("No Coletor: " .. label.Text)
			end
		end)
		task.wait(0.5)
	end
end)

local function coletarAte(valorAlvo)
	local tycoon = workspace.Tycoons:FindFirstChild(player.Name)
	local collector = tycoon and (tycoon.Auxiliary.Collector.Parts:FindFirstChild("Part") or tycoon.Auxiliary.Collector:FindFirstChild("Essential"))
	local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")

	-- O script FICA AQUI até você ter o dinheiro ou desligar o toggle
	while _G.AutoTycoonLIGADO and _G.DinheiroNoPlayer < valorAlvo do
		if _G.DinheiroNoColetor > 0 and hrp and collector then
			local posOriginal = hrp.CFrame
			hrp.CFrame = collector.CFrame
			task.wait(0.2) -- Tempo para o toque registrar
			hrp.CFrame = posOriginal
		end
		task.wait(2) -- Espera o dinheiro subir no coletor
	end
end

local function tentarComprar(nomeBotao, preco)
	if not _G.AutoTycoonLIGADO then return end

	local tycoon = workspace.Tycoons:FindFirstChild(player.Name)
	local buttonsFolder = tycoon and tycoon:FindFirstChild("Buttons")

	if not buttonsFolder then return end

	-- Tenta encontrar o botão. Se não existir, o script espera um pouco 
	-- antes de decidir se pula ou se continua tentando.
	local botao = buttonsFolder:FindFirstChild(nomeBotao)

	if botao then
		local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		if hrp then
			-- Se não tem dinheiro, fica coletando até ter
			if _G.DinheiroNoPlayer < preco then
				coletarAte(preco)
			end

			-- Realiza a compra
			if _G.AutoTycoonLIGADO and _G.DinheiroNoPlayer >= preco then
				local targetPart = botao:IsA("BasePart") and botao or (botao:FindFirstChild("Head") or botao:FindFirstChild("Part") or botao.PrimaryPart)
				if targetPart then
					hrp.CFrame = targetPart.CFrame
					task.wait(0.6) -- Aumentado para garantir que o jogo registre
				end
			end
		end
	else
		-- Se o botão não existe, pode ser que você já comprou 
		-- OU ele ainda não desbloqueou. 
		-- Vamos dar um pequeno delay para o jogo "respirar"
		task.wait(1)
	end
end

FarmTab:CreateToggle({
	Name = "Auto Tycoon (Full)",
	CurrentValue = false,
	Flag = "AutoTycoon",
	Callback = function(Value)
		_G.AutoTycoonLIGADO = Value
		if Value then
			task.spawn(function()
				-- SEQUÊNCIA DE COMPRAS
				tentarComprar("Dropper2Dropper 2", 250)
				tentarComprar("Dropper3Dropper 3", 1500)
				tentarComprar("Dropper4Dropper 4", 3000)
				tentarComprar("Dropper5Dropper 5", 6500)

				tentarComprar("WallsWalls", 150)
				tentarComprar("LasersDoor Lasers", 550)
				tentarComprar("Walls 2Walls 2", 500)
				tentarComprar("Walls 3Walls 3", 1500)
				tentarComprar("SecondFloorSecond Floor", 8000)
				tentarComprar("StairsStairs", 1100)

				tentarComprar("Track2Big Track", 1200)
				tentarComprar("BigDropper1Big Dropper 1", 10000)
				tentarComprar("BigDropper2Big Dropper 2", 35000)
				tentarComprar("BigDropper3Big Dropper 3", 80000)

				tentarComprar("Walls 4Walls", 1000)
				tentarComprar("Walls 5Walls 2", 2500)
				tentarComprar("Walls 6Walls 3", 3000)
				tentarComprar("ThirdFloorThird Floor", 200000)
				tentarComprar("Stairs2Stairs", 11000)

				tentarComprar("Track3Super Track", 12000)
				tentarComprar("SuperDropperSuper Dropper", 250000)

				tentarComprar("Walls 7Walls 7", 10000)
				tentarComprar("Walls 8Walls 8", 25000)
				tentarComprar("Walls 9Walls 9", 30000)
				tentarComprar("RoofRoof", 40000)
				tentarComprar("Security GunsSecurity Guns", 400000)
				tentarComprar("Stairs3Stairs", 12000)

				tentarComprar("PowerPadAbility Pad", 250)
				tentarComprar("UltraPadBig Ability Pad", 1000)
				tentarComprar("BoostPadPotion Pad", 10000)

				tentarComprar("PetElemental Pet", 3000)
				tentarComprar("SuitElemental Body", 12000)
				tentarComprar("HealHealing Pad", 6000)
				tentarComprar("Air StrikeAir Strike", 1500000)

				tentarComprar("TurretEnergy Turret", 150000)
				tentarComprar("MysteryBlockMystery Block", 3500000)

				Rayfield:Notify({Title = "Auto Tycoon", Content = "Finalizado!"})
			end)
		end
	end,
})

-- ==========================================
-- TAB MORE
-- ==========================================
local MoreTab = Window:CreateTab("More Tab", nil)

MoreTab:CreateButton({
	Name = "Close Script",
	Callback = function() Rayfield:Destroy() end,
})

MoreTab:CreateButton({
	Name = "Auto Kick",
	Callback = function() player:Kick("Finalizado") end,
})
