local Systems = script.Parent:WaitForChild("Systems")
local Players = game:GetService("Players")
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
local LeaderboardService = require(script.Parent.Parent:WaitForChild("Modules"):WaitForChild("LeaderboardService"))
local ADMIN_NAME = "Gihido"

local function fireSimple(player, text)
	local notifyEvent = RemoteRegistry.GetRemote("Notify")
	if notifyEvent then
		notifyEvent:FireClient(player, {kind = "simple", text = text})
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

local function formatLeaderboardValue(value)
	local n = tonumber(value) or 0
	if n >= 1000000 then
		return string.format("%.2fM", n / 1000000)
	elseif n >= 1000 then
		return string.format("%.1fK", n / 1000)
	end
	return tostring(math.floor(n + 0.5))
end

local LEADERBOARD_SOURCES = {
	Coins = PlayerDataSystem.GetCoinsObject,
	Wood = PlayerDataSystem.GetWoodCurrencyObject,
	Paper = PlayerDataSystem.GetPaperCurrencyObject,
	Hay = PlayerDataSystem.GetHayCurrencyObject,
	XP = PlayerDataSystem.GetXPCurrencyObject,
}

local function buildLeaderboardTop(boardName, topCount)
	local sourceGetter = LEADERBOARD_SOURCES[boardName] or LEADERBOARD_SOURCES.Coins
	local entries = LeaderboardService:BuildEntries(Players:GetPlayers(), function(plr)
		local currencyObj = sourceGetter(plr)
		return currencyObj and currencyObj.Value or 0
	end, formatLeaderboardValue)
	return LeaderboardService:GetTopPlayers(entries, topCount or 10)
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

local adminActionEvent = RemoteRegistry.GetRemote("AdminAction")
local leaderboardRequestEvent = RemoteRegistry.GetRemote("LeaderboardRequest")
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
	elseif actionName == "ResetSelf" then
		PlayerDataSystem.ResetAllPlayerDataCore(targetPlayer)
		XPSystem.ResetXPProgress(targetPlayer)
		PassiveSystem.SetPassiveState(targetPlayer, PassiveSystem.EmptyPassiveState())
		RuneInventorySystem.ResetRuneState(targetPlayer)
		fireSimple(player, "Данные сброшены: " .. targetPlayer.Name)
	end
end)

leaderboardRequestEvent.OnServerEvent:Connect(function(player, boardName, limit)
	local requestedBoard = type(boardName) == "string" and boardName or "Coins"
	if not LEADERBOARD_SOURCES[requestedBoard] then
		return
	end

	local topCount = math.clamp(math.floor(tonumber(limit) or 10), 1, 30)
	local topEntries = buildLeaderboardTop(requestedBoard, topCount)
	local payload = {}
	for _, entry in ipairs(topEntries) do
		payload[#payload + 1] = {
			name = entry.player and entry.player.Name or "Unknown",
			displayName = entry.player and entry.player.DisplayName or "",
			value = entry.value or 0,
			formattedValue = entry.formattedValue or tostring(entry.value or 0),
			rank = entry.rank or 0,
		}
	end

	leaderboardRequestEvent:FireClient(player, requestedBoard, payload)
end)
