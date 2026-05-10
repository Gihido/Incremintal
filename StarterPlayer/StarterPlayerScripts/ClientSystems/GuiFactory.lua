local GuiFactory = {}

function GuiFactory.ClearChildren(instance)
	for _, child in ipairs(instance:GetChildren()) do
		child:Destroy()
	end
end

function GuiFactory.CreateCorner(parent, radius)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius or 10)
	corner.Parent = parent
	return corner
end

function GuiFactory.CreateStroke(parent, color, thickness, transparency)
	local stroke = Instance.new("UIStroke")
	stroke.Color = color or Color3.fromRGB(255, 255, 255)
	stroke.Thickness = thickness or 1
	stroke.Transparency = transparency or 0
	stroke.Parent = parent
	return stroke
end

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

function GuiFactory.CreateSurfaceGui(playerGui, name, adorneePart, face, pixelsPerStud)
	local old = playerGui:FindFirstChild(name)
	if old then
		old:Destroy()
	end

	local surfaceGui = Instance.new("SurfaceGui")
	surfaceGui.Name = name
	surfaceGui.Adornee = adorneePart
	surfaceGui.Face = face or Enum.NormalId.Front
	surfaceGui.AlwaysOnTop = true
	surfaceGui.LightInfluence = 0
	surfaceGui.Brightness = 2
	surfaceGui.MaxDistance = 100
	surfaceGui.PixelsPerStud = pixelsPerStud or 70
	surfaceGui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	surfaceGui.ResetOnSpawn = false
	surfaceGui.Parent = playerGui
	return surfaceGui
end

function GuiFactory.CreateTextLabel(parent, props)
	props = props or {}
	local label = Instance.new("TextLabel")
	label.Name = props.name or "Label"
	label.Size = props.size or UDim2.new(1, 0, 0, 28)
	label.Position = props.position or UDim2.fromOffset(0, 0)
	label.BackgroundColor3 = props.backgroundColor3 or Color3.fromRGB(25, 25, 25)
	label.BackgroundTransparency = props.backgroundTransparency == nil and 1 or props.backgroundTransparency
	label.Text = props.text or ""
	label.TextColor3 = props.textColor3 or Color3.fromRGB(245, 245, 245)
	label.Font = props.font or Enum.Font.GothamSemibold
	label.TextSize = props.textSize or 16
	label.TextScaled = props.textScaled or false
	label.TextWrapped = props.textWrapped or false
	label.TextXAlignment = props.textXAlignment or Enum.TextXAlignment.Left
	label.TextYAlignment = props.textYAlignment or Enum.TextYAlignment.Center
	label.Parent = parent
	return label
end

function GuiFactory.CreateTextButton(parent, props)
	props = props or {}
	local button = Instance.new("TextButton")
	button.Name = props.name or "Button"
	button.Size = props.size or UDim2.fromOffset(140, 32)
	button.Position = props.position or UDim2.fromOffset(0, 0)
	button.Text = props.text or "Button"
	button.Font = props.font or Enum.Font.GothamSemibold
	button.TextSize = props.textSize or 14
	button.TextScaled = props.textScaled or false
	button.TextColor3 = props.textColor3 or Color3.fromRGB(245, 245, 245)
	button.BackgroundColor3 = props.backgroundColor3 or Color3.fromRGB(45, 45, 45)
	button.AutoButtonColor = true
	button.Parent = parent
	GuiFactory.CreateCorner(button, props.cornerRadius or 8)
	return button
end

function GuiFactory.CreateFrame(parent, props)
	props = props or {}
	local frame = Instance.new("Frame")
	frame.Name = props.name or "Frame"
	frame.Size = props.size or UDim2.fromOffset(100, 100)
	frame.Position = props.position or UDim2.fromOffset(0, 0)
	frame.BackgroundColor3 = props.backgroundColor3 or Color3.fromRGB(25, 25, 25)
	frame.BackgroundTransparency = props.backgroundTransparency or 0
	frame.BorderSizePixel = props.borderSizePixel or 0
	frame.Parent = parent
	if props.cornerRadius then
		GuiFactory.CreateCorner(frame, props.cornerRadius)
	end
	return frame
end

return GuiFactory
