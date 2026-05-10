local Systems = script.Parent:WaitForChild("Systems")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CoreSystems = Systems:WaitForChild("Core")
local UpgradeBoards = Systems:WaitForChild("UpgradeBoards")
local RuneSystems = Systems:WaitForChild("RuneSystems")

local RemoteRegistry = require(CoreSystems:WaitForChild("RemoteRegistry"))
local PlayerDataSystem = require(CoreSystems:WaitForChild("PlayerDataSystem"))
local GamepassSystem = require(CoreSystems:WaitForChild("GamepassSystem"))

local CoinSystem = require(Systems:WaitForChild("CoinSystem"))
local WoodSystem = require(Systems:WaitForChild("WoodSystem"))
local PaperFactorySystem = require(Systems:WaitForChild("PaperFactorySystem"))
local HaySystem = require(Systems:WaitForChild("HaySystem"))
local XPSystem = require(Systems:WaitForChild("XPSystem"))
local PassiveSystem = require(Systems:WaitForChild("PassiveSystem"))

local CoinUpgradeBoard = require(UpgradeBoards:WaitForChild("CoinUpgradeBoard"))
local WoodUpgradeBoard = require(UpgradeBoards:WaitForChild("WoodUpgradeBoard"))
local PaperUpgradeBoard = require(UpgradeBoards:WaitForChild("PaperUpgradeBoard"))
local HayUpgradeBoard = require(UpgradeBoards:WaitForChild("HayUpgradeBoard"))
local XPUpgradeBoard = require(UpgradeBoards:WaitForChild("XPUpgradeBoard"))

local RuneInventorySystem = require(RuneSystems:WaitForChild("RuneInventorySystem"))
local RuneSessionSystem = require(RuneSystems:WaitForChild("RuneSessionSystem"))
local RuneStatsSystem = require(RuneSystems:WaitForChild("RuneStatsSystem"))
local RuneRollSystem = require(RuneSystems:WaitForChild("RuneRollSystem"))
local ADMIN_NAME = "Gihido"

local function fireSimple(player, text)
	local remotes = ReplicatedStorage:FindFirstChild("Remotes")
	local notifyEvent = remotes and remotes:FindFirstChild(RemoteRegistry.Remotes.NotifyClient)
	if notifyEvent then
		notifyEvent:FireClient(player, {kind = "Simple", text = text})
	end
end

local function resolveTargetPlayer(sourcePlayer, payload)
	if type(payload) ~= "table" or type(payload.targetName) ~= "string" then
		return sourcePlayer
	end

	local targetName = string.lower(payload.targetName)
	if targetName == "" or targetName == "me" or targetName == "self" then
		return sourcePlayer
	end

	for _, candidate in ipairs(Players:GetPlayers()) do
		local nameLower = string.lower(candidate.Name)
		local displayLower = string.lower(candidate.DisplayName or "")
		if nameLower == targetName or displayLower == targetName or string.sub(nameLower, 1, #targetName) == targetName then
			return candidate
		end
	end
	return nil
end

-- Core
RemoteRegistry.Init()
PlayerDataSystem.Init()
GamepassSystem.Init()

-- Gameplay
XPSystem.Init()
RuneInventorySystem.Init()
RuneSessionSystem.Init()
RuneStatsSystem.Init({
	GetPassiveSpecialBoosts = PassiveSystem.GetPassiveSpecialBoosts,
	GetGamepassMultiplier = GamepassSystem.GetGamepassMultiplier,
})
PassiveSystem.Init({
	GetRuneBonusMultipliers = RuneStatsSystem.GetRuneBonusMultipliers,
})
CoinSystem.Init({
	GetXPBoostMultiplier = XPSystem.GetXPBoostMultiplier,
	GetPassiveMultipliers = PassiveSystem.GetPassiveMultipliers,
	GetPassiveSpecialBoosts = PassiveSystem.GetPassiveSpecialBoosts,
	GetRuneBonusMultipliers = RuneStatsSystem.GetRuneBonusMultipliers,
	GetGamepassMultiplier = GamepassSystem.GetGamepassMultiplier,
})
WoodSystem.Init({
	GetPassiveMultipliers = PassiveSystem.GetPassiveMultipliers,
	GetRuneBonusMultipliers = RuneStatsSystem.GetRuneBonusMultipliers,
	GetGamepassMultiplier = GamepassSystem.GetGamepassMultiplier,
})
PaperFactorySystem.Init({
	GetGamepassMultiplier = GamepassSystem.GetGamepassMultiplier,
	GetRuneBonusMultipliers = RuneStatsSystem.GetRuneBonusMultipliers,
})
HaySystem.Init()

-- Board systems
CoinUpgradeBoard.Init()
WoodUpgradeBoard.Init()
PaperUpgradeBoard.Init()
HayUpgradeBoard.Init()
XPUpgradeBoard.Init()

-- Rune runtime
RuneRollSystem.Init()

local remotes = ReplicatedStorage:WaitForChild("Remotes")
local adminActionEvent = remotes:WaitForChild(RemoteRegistry.Remotes.AdminAction)
adminActionEvent.OnServerEvent:Connect(function(player, actionName, currencyName, actionValue)
	if player.Name ~= ADMIN_NAME then
		return
	end

	local targetPlayer = resolveTargetPlayer(player, actionValue)
	if not targetPlayer then
		fireSimple(player, "Игрок не найден")
		return
	end

	if actionName == "GiveCurrency" then
		local amount = PlayerDataSystem.RoundToTenth(type(actionValue) == "table" and actionValue.amount or actionValue)
		if amount <= 0 then
			fireSimple(player, "Введи число больше нуля")
			return
		end

		local currencyObject = PlayerDataSystem.GetCurrencyObjectForName(targetPlayer, currencyName)
		if not currencyObject then
			fireSimple(player, "Неизвестная валюта")
			return
		end

		PlayerDataSystem.AddCurrency(currencyObject, amount)
		PlayerDataSystem.MarkDirty(targetPlayer)
		fireSimple(player, "Валюта выдана: " .. targetPlayer.Name)
	elseif actionName == "GivePassive" then
		local passiveId = tostring(currencyName or "")
		local success, reason = PassiveSystem.GrantPassive(targetPlayer, passiveId)
		if not success then
			if reason == "NOT_FOUND" then
				fireSimple(player, "Пассив не найден")
			elseif reason == "INVENTORY_FULL" then
				fireSimple(player, "Инвентарь пассивов заполнен")
			end
			return
		end
		fireSimple(player, "Пассив добавлен: " .. passiveId .. " -> " .. targetPlayer.Name)
	elseif actionName == "AdminRuneBoost" then
		if not PlayerDataSystem.ApplyAdminRuneBoost(targetPlayer, 20) then
			fireSimple(player, "Не удалось применить rune boost")
			return
		end
		fireSimple(player, "Rune boosts x20 применены -> " .. targetPlayer.Name)
	end
end)
