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

local function findDescendantByName(root, targetName, maxDepth)
	local queue = {{node = root, depth = 0}}
	while #queue > 0 do
		local item = table.remove(queue, 1)
		if item.node.Name == targetName then
			return item.node
		end
		if item.depth < maxDepth then
			for _, child in ipairs(item.node:GetChildren()) do
				queue[#queue + 1] = {node = child, depth = item.depth + 1}
			end
		end
	end
	return nil
end

local function resolveBasePart(instance)
	if not instance then
		return nil
	end
	if instance:IsA("BasePart") then
		return instance
	end
	if instance:IsA("Model") and instance.PrimaryPart then
		return instance.PrimaryPart
	end
	return instance:FindFirstChildWhichIsA("BasePart", true)
end

function GuiFactory.FindWorkspacePart(names, maxDepth)
	local candidates = type(names) == "table" and names or {names}
	for _, partName in ipairs(candidates) do
		local direct = resolveBasePart(workspace:FindFirstChild(partName))
		if direct then
			return direct
		end
	end

	for _, partName in ipairs(candidates) do
		local found = resolveBasePart(findDescendantByName(workspace, partName, maxDepth or 8))
		if found then
			return found
		end
	end
	return nil
end

function GuiFactory.CreateSurfaceGui(playerGui, name, adorneePart, face, pixelsPerStud)
	local oldPlayerGui = playerGui and playerGui:FindFirstChild(name)
	if oldPlayerGui then
		oldPlayerGui:Destroy()
	end

	local oldOnPart = adorneePart and adorneePart:FindFirstChild(name)
	if oldOnPart then
		oldOnPart:Destroy()
	end

	local surfaceGui = Instance.new("SurfaceGui")
	surfaceGui.Name = name
	surfaceGui.Face = face or Enum.NormalId.Front
	surfaceGui.AlwaysOnTop = true
	surfaceGui.LightInfluence = 0
	surfaceGui.Brightness = 2
	surfaceGui.MaxDistance = 250
	surfaceGui.PixelsPerStud = pixelsPerStud or 70
	surfaceGui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	surfaceGui.ResetOnSpawn = false
	surfaceGui.Parent = adorneePart or playerGui
	if surfaceGui.Parent == playerGui then
		surfaceGui.Adornee = adorneePart
	end
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
