-- Example locale-sensitive number formatting:
-- https://docs.oracle.com/cd/E19455-01/806-0169/overview-9/index.html

--[[
	Locale specification:
	[DECIMAL_SEPARATOR] = string for decimal point, if needed
	[GROUP_DELIMITER] = string for groupings of numbers left of the decimal
	List section = abbreviations for language, in increasing order

	Missing features in this code:
	- No support for differences in number of digits per GROUP_DELIMITER.
	Some Chinese dialects group by 10000 instead of 1000.
	- No support for variable differences in number of digits per GROUP_DELIMITER.
	Indian natural language groups the first 3 to left of decimal, then every 2 after that.

	See https://en.wikipedia.org/wiki/Decimal_separator#Digit_grouping
]]
local CorePackages = game:GetService("CorePackages")
local Logging = require(CorePackages.Logging)

local localeInfos = {}

local DEFAULT_LOCALE = "en-us"

-- Separator aliases to help avoid spelling errors
local DECIMAL_SEPARATOR = "decimalSeparator"
local GROUP_DELIMITER = "groupDelimiter"

localeInfos["en-us"] = {
	[DECIMAL_SEPARATOR] = ".",
	[GROUP_DELIMITER] = ",",
	{ 1, "", },
	{ 1e3, "K", },
	{ 1e6, "M", },
	{ 1e9, "B", },
}

localeInfos["es-es"] = {
	[DECIMAL_SEPARATOR] = ",",
	[GROUP_DELIMITER] = ".",
	{ 1, "", },
	{ 1e3, " mil", },
	{ 1e6, " M", },
}

localeInfos["fr-fr"] = {
	[DECIMAL_SEPARATOR] = ",",
	[GROUP_DELIMITER] = " ",
	{ 1, "", },
	{ 1e3, " k", },
	{ 1e6, " M", },
	{ 1e9, " Md", },
}

localeInfos["de-de"] = {
	[DECIMAL_SEPARATOR] = ",",
	[GROUP_DELIMITER] = " ",
	{ 1, "", },
	{ 1e3, " Tsd.", },
	{ 1e6, " Mio.", },
	{ 1e9, " Mrd.", },
}

localeInfos["pt-br"] = {
	[DECIMAL_SEPARATOR] = ",",
	[GROUP_DELIMITER] = ".",
	{ 1, "", },
	{ 1e3, " mil", },
	{ 1e6, " mi", },
	{ 1e9, " bi", },
}

localeInfos["zh-cn"] = {
	[DECIMAL_SEPARATOR] = ".",
	[GROUP_DELIMITER] = ",", -- Chinese commonly uses 3 digit groupings, despite 10000s rule
	{ 1, "", },
	{ 1e3, "千", },
	{ 1e4, "万", },
	{ 1e8, "亿", },
}

localeInfos["zh-tw"] = {
	[DECIMAL_SEPARATOR] = ".",
	[GROUP_DELIMITER] = ",", -- Chinese commonly uses 3 digit groupings, despite 10000s rule
	{ 1, "", },
	{ 1e3, "千", },
	{ 1e4, "萬", },
	{ 1e8, "億", },
}

localeInfos["ko-kr"] = {
	[DECIMAL_SEPARATOR] = ".",
	[GROUP_DELIMITER] = ",",
	{ 1, "", },
	{ 1e3, "천", },
	{ 1e4, "만", },
	{ 1e8, "억", },
}

localeInfos["ja-jp"] = {
	[DECIMAL_SEPARATOR] = ".",
	[GROUP_DELIMITER] = ",",
	{ 1, "", },
	{ 1e3, "千", },
	{ 1e4, "万", },
	{ 1e8, "億", },
}

localeInfos["it-it"] = {
	[DECIMAL_SEPARATOR] = ",",
	[GROUP_DELIMITER] = " ",
	{ 1, "", },
	{ 1e3, " mila", },
	{ 1e6, " Mln", },
	{ 1e9, " Mld", },
}

localeInfos["ru-ru"] = {
	[DECIMAL_SEPARATOR] = ",",
	[GROUP_DELIMITER] = ".",
	{ 1, "", },
	{ 1e3, " тыс", },
	{ 1e6, " млн", },
	{ 1e9, " млрд", },
}

localeInfos["id-id"] = {
	[DECIMAL_SEPARATOR] = ",",
	[GROUP_DELIMITER] = ".",
	{ 1, "", },
	{ 1e3, " rb", },
	{ 1e6, " jt", },
	{ 1e9, " M", },
}

localeInfos["vi-vn"] = {
	[DECIMAL_SEPARATOR] = ".",
	[GROUP_DELIMITER] = " ",
	{ 1, "", },
	{ 1e3, " N", },
	{ 1e6, " Tr", },
	{ 1e9, " T", },
}

localeInfos["th-th"] = {
	[DECIMAL_SEPARATOR] = ".",
	[GROUP_DELIMITER] = ",",
	{ 1, "", },
	{ 1e3, " พ", },
	{ 1e4, " ม", },
	{ 1e5, " ส", },
	{ 1e6, " ล", },
}

localeInfos["tr-tr"] = {
	[DECIMAL_SEPARATOR] = ",",
	[GROUP_DELIMITER] = ".",
	{ 1, "", },
	{ 1e3, " B", },
	{ 1e6, " Mn", },
	{ 1e9, " Mr", },
}

-- Aliases for languages that use the same mappings.
localeInfos["en-gb"] = localeInfos["en-us"]
localeInfos["es-mx"] = localeInfos["es-es"]

local function findDecimalPointIndex(numberStr)
	return string.find(numberStr, "%.") or #numberStr + 1
end

-- Find the base 10 offset needed to make 0.1 <= abs(number) < 1
local function findDecimalOffset(number)
	if number == 0 then
		return 0
	end

	local offsetToOnesRange = math.floor(math.log10(math.abs(number)))
	return -(offsetToOnesRange + 1) -- Offset one more (or less) digit
end

local function roundToSignificantDigits(number, significantDigits)
	local offset = findDecimalOffset(number)
	local multiplier = 10^(significantDigits + offset)
	local significand = math.floor(number * multiplier + 0.5)
	return significand / multiplier;
end

local function addGroupDelimiters(numberStr, delimiter)
	local formatted = numberStr
	local delimiterSubStr = string.format("%%1%s%%2", delimiter)
	while true do
		local lFormatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", delimiterSubStr)
		formatted = lFormatted
		if k == 0 then
			break
		end
	end
	return formatted
end

local function findDenominationEntry(localeInfo, number)
	local denominationEntry = localeInfo[1] -- Default to base denominations
	local absOfNumber = math.abs(number)
	for i = #localeInfo, 2, -1 do
		local entry = localeInfo[i]
		local baseValue = entry[1] - (localeInfo[i - 1][1]) / 2
		if baseValue <= absOfNumber then
			denominationEntry = entry
			break
		end
	end
	return denominationEntry
end

return function(number, locale)
	if number == 0 then
		return "0"
	end

	local localeInfo = localeInfos[locale]
	if not localeInfo then
		localeInfo = localeInfos[DEFAULT_LOCALE]
		Logging.warn(string.format("Warning: Locale not found: '%s', reverting to '%s' instead.",
			tostring(locale), DEFAULT_LOCALE))
	end

	-- select which denomination we are going to use
	local denominationEntry = findDenominationEntry(localeInfo, number)
	local baseValue = denominationEntry[1]
	local symbol = denominationEntry[2]

	-- Round to required significant digits
	local significantQuotient = roundToSignificantDigits(number / baseValue, 3)

	-- trim to 1 decimal point
	local trimmedQuotient = math.floor(significantQuotient * 10 + 0.5) / 10
	local trimmedQuotientString = tostring(trimmedQuotient)

	-- Split the string into integer and fraction parts
	local decimalPointIndex = findDecimalPointIndex(trimmedQuotientString)
	local integerPart = string.sub(trimmedQuotientString, 1, decimalPointIndex - 1)
	local fractionPart = string.sub(trimmedQuotientString, decimalPointIndex + 1, #trimmedQuotientString)

	-- Add group delimiters to integer part
	if localeInfo.groupDelimiter then
		integerPart = addGroupDelimiters(integerPart, localeInfo.groupDelimiter)
	end

	if #fractionPart > 0 then
		return integerPart .. localeInfo.decimalSeparator .. fractionPart .. symbol
	else
		return integerPart .. symbol
	end
end
