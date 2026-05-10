local GuiFactory = {}

function GuiFactory.CreateScreenGui(playerGui, name)
	local gui = playerGui:FindFirstChild(name)
	if not gui then
		gui = Instance.new("ScreenGui")
		gui.Name = name
		gui.ResetOnSpawn = false
		gui.Parent = playerGui
	end
	return gui
end

function GuiFactory.CreateTextButton(parent, props)
	local button = Instance.new("TextButton")
	button.Name = props.name or "Button"
	button.Size = props.size or UDim2.fromOffset(140, 32)
	button.Position = props.position or UDim2.fromOffset(0, 0)
	button.Text = props.text or "Button"
	button.Font = Enum.Font.GothamSemibold
	button.TextSize = 14
	button.TextColor3 = props.textColor3 or Color3.fromRGB(245, 245, 245)
	button.BackgroundColor3 = props.backgroundColor3 or Color3.fromRGB(45, 45, 45)
	button.AutoButtonColor = true
	button.Parent = parent
	return button
end

function GuiFactory.CreateFrame(parent, props)
	local frame = Instance.new("Frame")
	frame.Name = props.name or "Frame"
	frame.Size = props.size or UDim2.fromOffset(100, 100)
	frame.Position = props.position or UDim2.fromOffset(0, 0)
	frame.BackgroundColor3 = props.backgroundColor3 or Color3.fromRGB(25, 25, 25)
	frame.BackgroundTransparency = props.backgroundTransparency or 0
	frame.Parent = parent
	return frame
end

return GuiFactory
