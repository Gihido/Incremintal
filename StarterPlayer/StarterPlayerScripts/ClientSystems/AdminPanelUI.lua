local GuiFactory = require(script.Parent:WaitForChild("GuiFactory"))
local ResponsiveUI = require(script.Parent:WaitForChild("ResponsiveUI"))

local AdminPanelUI = {}

local function isLocalAdmin(player)
	return player and player.Name == "Gihido"
end

function AdminPanelUI.Init(context)
	if not isLocalAdmin(context.player) then
		return
	end

	local gui = GuiFactory.CreateScreenGui(context.playerGui, "AdminPanelGui")
	local panel = GuiFactory.CreateFrame(gui, {
		name = "Panel",
		size = UDim2.fromOffset(320, 240),
		position = UDim2.new(0, 24, 1, -264),
		backgroundColor3 = Color3.fromRGB(18, 18, 18),
		backgroundTransparency = 0.15,
	})
	ResponsiveUI.BindScale(panel)

	local list = Instance.new("UIListLayout")
	list.Padding = UDim.new(0, 6)
	list.Parent = panel

	local pad = Instance.new("UIPadding")
	pad.PaddingTop = UDim.new(0, 10)
	pad.PaddingLeft = UDim.new(0, 10)
	pad.PaddingRight = UDim.new(0, 10)
	pad.PaddingBottom = UDim.new(0, 10)
	pad.Parent = panel

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, 0, 0, 28)
	title.BackgroundTransparency = 1
	title.Font = Enum.Font.GothamBold
	title.TextSize = 16
	title.TextColor3 = Color3.fromRGB(255, 226, 130)
	title.Text = "Admin Panel"
	title.Parent = panel

	local function makeButton(text, callback)
		local btn = GuiFactory.CreateTextButton(panel, {text = text, size = UDim2.new(1, 0, 0, 32)})
		btn.MouseButton1Click:Connect(callback)
		return btn
	end

	makeButton("Give 5000 Coins", function()
		context.adminRemote:FireServer("GiveCurrency", "Coins", {amount = 5000, targetName = "self"})
	end)

	makeButton("Give Passive: MythicCore", function()
		context.adminRemote:FireServer("GivePassive", "MythicCore", {targetName = "self"})
	end)

	makeButton("Rune Boost x20", function()
		context.adminRemote:FireServer("AdminRuneBoost", "", {targetName = "self"})
	end)

	makeButton("Reset Self", function()
		context.adminRemote:FireServer("ResetSelf", "", {targetName = "self"})
	end)
end

return AdminPanelUI
