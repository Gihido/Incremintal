local RunService = game:GetService("RunService")

local CoinAnimationSystem = {}

function CoinAnimationSystem.Start(animatedCoins)
	RunService.Heartbeat:Connect(function()
		local now = os.clock()
		for coin, info in pairs(animatedCoins) do
			if coin and coin.Parent then
				local bobOffset = math.sin(now * 2 + info.seed) * 0.35
				local rotationY = now * info.spinSpeed + info.seed
				coin.CFrame = info.baseCFrame * CFrame.new(0, bobOffset, 0) * CFrame.Angles(0, rotationY, 0)
			else
				animatedCoins[coin] = nil
			end
		end
	end)
end

return CoinAnimationSystem
