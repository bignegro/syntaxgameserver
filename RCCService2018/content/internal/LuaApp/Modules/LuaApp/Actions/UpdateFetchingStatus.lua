local Modules = game:GetService("CoreGui").RobloxGui.Modules
local Action = require(Modules.Common.Action)

return Action(script.Name, function(key, status)
	return {
		key = key,
		status = status
	}
end)
