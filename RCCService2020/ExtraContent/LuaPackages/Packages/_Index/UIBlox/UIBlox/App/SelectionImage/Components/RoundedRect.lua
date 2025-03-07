local UIBloxRoot = script.Parent.Parent.Parent.Parent
local Packages = UIBloxRoot.Parent

local Roact = require(Packages.Roact)

local ImageSetComponent = require(UIBloxRoot.Core.ImageSet.ImageSetComponent)
local Images = require(UIBloxRoot.App.ImageSet.Images)

local INSET_ADJUSTMENT = 6
local ASSET_NAME = "component_assets/circle_17_stroke_3"

return function(props)
	return Roact.createElement(ImageSetComponent.Label, {
		Image = Images[ASSET_NAME],
		BackgroundTransparency = 1,
		Size = UDim2.new(1, INSET_ADJUSTMENT * 2, 1, INSET_ADJUSTMENT * 2),
		Position = UDim2.new(0, -INSET_ADJUSTMENT, 0, -INSET_ADJUSTMENT),
		ScaleType = Enum.ScaleType.Slice,
		SliceCenter = Rect.new(8, 8, 9, 9),

		[Roact.Ref] = props[Roact.Ref],
	})
end