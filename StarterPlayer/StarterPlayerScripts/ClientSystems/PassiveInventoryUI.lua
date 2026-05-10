local HttpService = game:GetService("HttpService")
local GuiFactory = require(script.Parent:WaitForChild("GuiFactory"))
local ClientContext = require(script.Parent:WaitForChild("ClientContext"))

local PassiveInventoryUI = {}

local function decodeState(jsonText)
	local ok, decoded = pcall(function()
		return HttpService:JSONDecode(jsonText or "{}")
	end)
	if ok and type(decoded) == "table" then
		decoded.inventory = type(decoded.inventory) == "table" and decoded.inventory or {}
		decoded.equippedUid = tostring(decoded.equippedUid or "")
		return decoded
	end
	return {inventory = {}, equippedUid = ""}
end

local function createBoard(context, partName, guiName, title, accent)
	local part = context.ResolveWorkspaceObject(partName)
	if not part then
		warn("Passive board part not found: " .. partName)
		return nil
	end

	local gui = GuiFactory.CreateSurfaceGui(context.playerGui, guiName, part, Enum.NormalId.Front, 76)
	local root = GuiFactory.CreateFrame(gui, {
		name = "Root",
		size = UDim2.fromScale(1, 1),
		backgroundColor3 = Color3.fromRGB(22, 24, 36),
		cornerRadius = 18,
	})
	GuiFactory.CreateStroke(root, accent, 2, 0.12)
	GuiFactory.CreateTextLabel(root, {
		name = "Title",
		position = UDim2.fromOffset(16, 12),
		size = UDim2.new(1, -32, 0, 40),
		text = title,
		textColor3 = accent,
		font = Enum.Font.GothamBlack,
		textScaled = true,
		textXAlignment = Enum.TextXAlignment.Center,
	})
	local body = GuiFactory.CreateTextLabel(root, {
		name = "Body",
		position = UDim2.fromOffset(18, 66),
		size = UDim2.new(1, -36, 1, -130),
		text = "Loading...",
		textColor3 = Color3.fromRGB(245, 240, 255),
		font = Enum.Font.GothamBold,
		textScaled = true,
		textWrapped = true,
		textXAlignment = Enum.TextXAlignment.Center,
		textYAlignment = Enum.TextYAlignment.Center,
	})
	return {root = root, body = body}
end

function PassiveInventoryUI.Init(context)
	if not context.data then
		return
	end

	local rollBoard = createBoard(context, context.BoardPartNames.PassiveRoll, "PassiveRollBoardSurfaceGui", "PASSIVE ROLL", Color3.fromRGB(213, 184, 255))
	local inventoryBoard = createBoard(context, context.BoardPartNames.PassiveInventory, "PassiveInventoryBoardSurfaceGui", "PASSIVE INVENTORY", Color3.fromRGB(176, 232, 255))

	if rollBoard then
		local rollButton = GuiFactory.CreateTextButton(rollBoard.root, {
			name = "RollButton",
			position = UDim2.new(0.5, -90, 1, -52),
			size = UDim2.fromOffset(180, 36),
			text = "ROLL (Paper)",
			backgroundColor3 = Color3.fromRGB(213, 184, 255),
			textColor3 = Color3.fromRGB(34, 24, 52),
			font = Enum.Font.GothamBlack,
			textScaled = true,
		})
		rollButton.MouseButton1Click:Connect(function()
			context.passiveRemote:FireServer("Roll")
		end)
	end

	local function refresh()
		local passiveFolder = context.data and context.data:FindFirstChild("Passives")
		local stateValue = passiveFolder and passiveFolder:FindFirstChild("StateJson")
		local state = decodeState(stateValue and stateValue.Value or "{}")
		local unlocked = context.data and context.data:FindFirstChild("Rebirth") and context.data.Rebirth:FindFirstChild("FifthSystemsUnlocked") and context.data.Rebirth.FifthSystemsUnlocked.Value
		local lines = {}
		for index, entry in ipairs(state.inventory) do
			local equipped = entry.uid == state.equippedUid and " [E]" or ""
			lines[#lines + 1] = tostring(index) .. ". " .. tostring(entry.passiveId or "Passive") .. equipped
			if #lines >= 6 then
				break
			end
		end
		if #lines == 0 then
			lines[1] = "Inventory is empty"
		end
		if rollBoard then
			rollBoard.body.Text = unlocked and "Press ROLL to buy a passive.\nCost: paper" or "Unlocks after 5 rebirths"
		end
		if inventoryBoard then
			inventoryBoard.body.Text = table.concat(lines, "\n")
		end
	end

	refresh()
	ClientContext.AddRefresh(context, refresh)
end

return PassiveInventoryUI
