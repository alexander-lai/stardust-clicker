-- Util (ModuleScript in ReplicatedStorage > Shared)
-- Small helpers used by both server and client.

local Util = {}

local SUFFIXES = { "", "K", "M", "B", "T", "Qa", "Qi", "Sx", "Sp", "Oc", "No", "Dc" }

-- 1234 -> "1.23K", 5600000 -> "5.60M"
function Util.FormatNumber(n)
	n = math.floor(tonumber(n) or 0)
	if n < 1000 then
		return tostring(n)
	end
	local value = n
	local index = 1
	while value >= 1000 and index < #SUFFIXES do
		value = value / 1000
		index = index + 1
	end
	if value >= 100 then
		return string.format("%d%s", math.floor(value), SUFFIXES[index])
	elseif value >= 10 then
		return string.format("%.1f%s", value, SUFFIXES[index])
	end
	return string.format("%.2f%s", value, SUFFIXES[index])
end

-- 250000 -> "250,000"
function Util.FormatCommas(n)
	local text = tostring(math.floor(n))
	local formatted = text
	repeat
		local count
		formatted, count = string.gsub(formatted, "^(-?%d+)(%d%d%d)", "%1,%2")
	until count == 0
	return formatted
end

-- 2.5 -> "2.5", 3 -> "3", 1.25 -> "1.25"
function Util.FormatMultiplier(m)
	local text = string.format("%.2f", m)
	text = string.gsub(text, "0+$", "")
	text = string.gsub(text, "%.$", "")
	return text
end

return Util
