local CoinVisualService = {}

function CoinVisualService.applyCoinVisuals(coin)
	if not coin:FindFirstChild("CoinLight") then
		local light = Instance.new("PointLight")
		light.Name = "CoinLight"
		light.Color = Color3.fromRGB(255, 222, 88)
		light.Brightness = 1.8
		light.Range = 8
		light.Parent = coin
	end

	if not coin:FindFirstChild("CoinHighlight") then
		local highlight = Instance.new("Highlight")
		highlight.Name = "CoinHighlight"
		highlight.Adornee = coin
		highlight.FillColor = Color3.fromRGB(255, 217, 82)
		highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
		highlight.FillTransparency = 0.35
		highlight.OutlineTransparency = 0.05
		highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
		highlight.Parent = coin
	end
end

return CoinVisualService
