local NotificationUI = {}

local function ensureLabel(playerGui)
	local screenGui = playerGui:FindFirstChild("NotifyGui")
	if not screenGui then
		screenGui = Instance.new("ScreenGui")
		screenGui.Name = "NotifyGui"
		screenGui.ResetOnSpawn = false
		screenGui.Parent = playerGui
	end

	local label = screenGui:FindFirstChild("Message")
	if not label then
		label = Instance.new("TextLabel")
		label.Name = "Message"
		label.AnchorPoint = Vector2.new(0.5, 0)
		label.Position = UDim2.fromScale(0.5, 0.05)
		label.Size = UDim2.fromOffset(500, 42)
		label.BackgroundTransparency = 0.25
		label.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
		label.TextColor3 = Color3.fromRGB(255, 255, 255)
		label.TextScaled = true
		label.Font = Enum.Font.GothamBold
		label.Visible = false
		label.Parent = screenGui
	end

	return label
end

function NotificationUI.Init(context)
	local label = ensureLabel(context.playerGui)
	local hideVersion = 0

	context.notifyRemote.OnClientEvent:Connect(function(payload)
		if type(payload) ~= "table" or payload.kind ~= "simple" then
			return
		end

		hideVersion += 1
		local current = hideVersion
		label.Text = tostring(payload.text or "")
		label.Visible = true
		task.delay(2.25, function()
			if hideVersion == current then
				label.Visible = false
			end
		end)
	end)
end

return NotificationUI
