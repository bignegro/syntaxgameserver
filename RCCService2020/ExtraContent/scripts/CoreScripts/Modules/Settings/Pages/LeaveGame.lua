--[[
		Filename: LeaveGame.lua
		Written by: jeditkacheff
		Version 1.0
		Description: Takes care of the leave game in Settings Menu
--]]


-------------- CONSTANTS -------------
local LEAVE_GAME_ACTION = "LeaveGameCancelAction"
local LEAVE_GAME_FRAME_WAITS = 2

-------------- SERVICES --------------
local CoreGui = game:GetService("CoreGui")
local ContextActionService = game:GetService("ContextActionService")
local RobloxGui = CoreGui:WaitForChild("RobloxGui")
local GuiService = game:GetService("GuiService")
local RunService = game:GetService("RunService")
local AnalyticsService = game:GetService("RbxAnalyticsService")

----------- UTILITIES --------------
local utility = require(RobloxGui.Modules.Settings.Utility)
local RobloxTranslator = require(RobloxGui.Modules.RobloxTranslator)

------------ Variables -------------------
local PageInstance = nil
RobloxGui:WaitForChild("Modules"):WaitForChild("TenFootInterface")
local isTenFootInterface = require(RobloxGui.Modules.TenFootInterface):IsEnabled()

local FFlagUpdateSettingsHubGameText = require(RobloxGui.Modules.Flags.FFlagUpdateSettingsHubGameText)
local GetFFlagAppUsesAutomaticQualityLevel = require(RobloxGui.Modules.Flags.GetFFlagAppUsesAutomaticQualityLevel)
local FFlagCollectAnalyticsForSystemMenu = settings():GetFFlag("CollectAnalyticsForSystemMenu")

local GetDefaultQualityLevel = require(RobloxGui.Modules.Common.GetDefaultQualityLevel)

local Constants
if FFlagCollectAnalyticsForSystemMenu then
  Constants = require(RobloxGui.Modules:WaitForChild("InGameMenu"):WaitForChild("Resources"):WaitForChild("Constants"))
end

----------- CLASS DECLARATION --------------

local function Initialize()
	local settingsPageFactory = require(RobloxGui.Modules.Settings.SettingsPageFactory)
	local this = settingsPageFactory:CreateNewPage()

	this.LeaveFunc = function()
		GuiService.SelectedCoreObject = nil -- deselects the button and prevents spamming the popup to save in studio when using gamepad

		if FFlagCollectAnalyticsForSystemMenu then
			AnalyticsService:SetRBXEventStream(Constants.AnalyticsTargetName, Constants.AnalyticsInGameMenuName,
												Constants.AnalyticsLeaveGameName, {confirmed = Constants.AnalyticsConfirmedName, universeid = tostring(game.GameId)})
		end

		-- need to wait for render frames so on slower devices the leave button highlight will update
		-- otherwise, since on slow devices it takes so long to leave you are left wondering if you pressed the button
		for i = 1, LEAVE_GAME_FRAME_WAITS do
			RunService.RenderStepped:wait()
		end

		game:Shutdown()

		if GetFFlagAppUsesAutomaticQualityLevel() then
			settings().Rendering.QualityLevel = GetDefaultQualityLevel()
		end
	end
	this.DontLeaveFunc = function(isUsingGamepad)
		if this.HubRef then
			this.HubRef:PopMenu(isUsingGamepad, true)
		end

		if FFlagCollectAnalyticsForSystemMenu then
			AnalyticsService:SetRBXEventStream(Constants.AnalyticsTargetName, Constants.AnalyticsInGameMenuName,
												Constants.AnalyticsLeaveGameName, {confirmed = Constants.AnalyticsCancelledName, universeid = tostring(game.GameId)})
		end
	end
	this.DontLeaveFromHotkey = function(name, state, input)
		if state == Enum.UserInputState.Begin then
			local isUsingGamepad = input.UserInputType == Enum.UserInputType.Gamepad1 or input.UserInputType == Enum.UserInputType.Gamepad2
				or input.UserInputType == Enum.UserInputType.Gamepad3 or input.UserInputType == Enum.UserInputType.Gamepad4

			this.DontLeaveFunc(isUsingGamepad)
		end
	end
	this.DontLeaveFromButton = function(isUsingGamepad)
		this.DontLeaveFunc(isUsingGamepad)
	end

	------ TAB CUSTOMIZATION -------
	this.TabHeader = nil -- no tab for this page

	------ PAGE CUSTOMIZATION -------
	this.Page.Name = "LeaveGamePage"
	this.ShouldShowBottomBar = false
	this.ShouldShowHubBar = false

	local leaveGameConfirmationText = "Are you sure you want to leave the game?"
	if FFlagUpdateSettingsHubGameText then
		leaveGameConfirmationText = RobloxTranslator:FormatByKey("InGame.HelpMenu.ConfirmLeaveGame")
	end

	local leaveGameText =  utility:Create'TextLabel'
	{
		Name = "LeaveGameText",
		Text = leaveGameConfirmationText,
		Font = Enum.Font.SourceSansBold,
		FontSize = Enum.FontSize.Size36,
		TextColor3 = Color3.new(1,1,1),
		BackgroundTransparency = 1,
		Size = UDim2.new(1,0,0,200),
		TextWrapped = true,
		ZIndex = 2,
		Parent = this.Page,
		Position = isTenFootInterface and UDim2.new(0,0,0,100) or UDim2.new(0,0,0,0)
	};

	local leaveButtonContainer = utility:Create"Frame"
	{
		Name = "LeaveButtonContainer",
		Parent = leaveGameText,
		Size = UDim2.new(1,0,0,400),
		BackgroundTransparency = 1,
		Position = UDim2.new(0,0,1,0)
	};

	local _leaveButtonLayout = utility:Create'UIGridLayout'
	{
		Name = "LeavetButtonsLayout",
		CellSize = isTenFootInterface and UDim2.new(0, 300, 0, 80) or UDim2.new(0, 200, 0, 50),
		CellPadding = UDim2.new(0,20,0,20),
		FillDirection = Enum.FillDirection.Horizontal,
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		SortOrder = Enum.SortOrder.LayoutOrder,
		VerticalAlignment = Enum.VerticalAlignment.Top,
		Parent = leaveButtonContainer
	};

	if utility:IsSmallTouchScreen() then
		leaveGameText.FontSize = Enum.FontSize.Size24
		leaveGameText.Size = UDim2.new(1,0,0,100)
	elseif isTenFootInterface then
		leaveGameText.FontSize = Enum.FontSize.Size48
	end

	this.LeaveGameButton = utility:MakeStyledButton("LeaveGame", "Leave", nil, this.LeaveFunc)
	this.LeaveGameButton.NextSelectionRight = nil
	this.LeaveGameButton.Parent = leaveButtonContainer

	------------- Init ----------------------------------

	local dontleaveGameButton = utility:MakeStyledButton("DontLeaveGame", "Don't Leave", nil, this.DontLeaveFromButton)
	dontleaveGameButton.NextSelectionLeft = nil
	dontleaveGameButton.Parent = leaveButtonContainer

	this.Page.Size = UDim2.new(1,0,0,dontleaveGameButton.AbsolutePosition.Y + dontleaveGameButton.AbsoluteSize.Y)

	return this
end


----------- Public Facing API Additions --------------
PageInstance = Initialize()

PageInstance.Displayed.Event:connect(function()
	GuiService.SelectedCoreObject = PageInstance.LeaveGameButton
	ContextActionService:BindCoreAction(LEAVE_GAME_ACTION, PageInstance.DontLeaveFromHotkey, false, Enum.KeyCode.ButtonB)
end)

PageInstance.Hidden.Event:connect(function()
	ContextActionService:UnbindCoreAction(LEAVE_GAME_ACTION)
end)


return PageInstance