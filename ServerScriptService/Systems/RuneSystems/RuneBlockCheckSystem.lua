local RuneBlockCheckSystem = {}

function RuneBlockCheckSystem.IsCharacterOnBlock(player, block, tolerance)
	if not block then return false end
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then return false end
	local hrp = character and character:FindFirstChild("HumanoidRootPart")
	if not hrp then return false end
	local tol = tolerance or Vector3.new(1.2, 3.5, 1.2)
	local localPos = block.CFrame:PointToObjectSpace(hrp.Position)
	local half = block.Size * 0.5
	return math.abs(localPos.X) <= (half.X + tol.X)
		and math.abs(localPos.Z) <= (half.Z + tol.Z)
		and math.abs(localPos.Y) <= (half.Y + tol.Y)
end

return RuneBlockCheckSystem
