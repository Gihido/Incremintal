local ResponsiveUI = {}

function ResponsiveUI.GetScaleForViewport(viewportSize)
	local width = viewportSize.X
	if width < 900 then
		return 0.85
	elseif width > 2200 then
		return 1.2
	end
	return 1
end

function ResponsiveUI.BindScale(frame)
	local camera = workspace.CurrentCamera
	if not camera then
		return
	end

	local uiScale = frame:FindFirstChildOfClass("UIScale")
	if not uiScale then
		uiScale = Instance.new("UIScale")
		uiScale.Parent = frame
	end

	local function apply()
		uiScale.Scale = ResponsiveUI.GetScaleForViewport(camera.ViewportSize)
	end

	apply()
	camera:GetPropertyChangedSignal("ViewportSize"):Connect(apply)
end

return ResponsiveUI
