local Modules = game:GetService("CoreGui").RobloxGui.Modules
local Action = require(Modules.Common.Action)

return Action(script.Name, function(avatarData)
	return {
		avatarData = avatarData
	}
end)