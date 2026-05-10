local ClientFormatters = {}

function ClientFormatters.Compact(value)
	local n = tonumber(value) or 0
	if n >= 1000000 then
		return string.format("%.2fM", n / 1000000)
	elseif n >= 1000 then
		return string.format("%.1fK", n / 1000)
	end
	return tostring(math.floor(n + 0.5))
end

return ClientFormatters
