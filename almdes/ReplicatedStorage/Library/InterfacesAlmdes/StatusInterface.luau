local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local localPlayer = game.Players.localPlayer;

local modGlobalVars = shared.require(game.ReplicatedStorage:WaitForChild("GlobalVariables"));
local modRemotesManager = shared.require(game.ReplicatedStorage.Library.RemotesManager);
local modBranchConfigs = shared.require(game.ReplicatedStorage.Library.BranchConfigurations);
local modStatusLibrary = shared.require(game.ReplicatedStorage.Library.StatusLibrary);
local modSyncTime = shared.require(game.ReplicatedStorage.Library.SyncTime);

local modItemInterface = shared.require(game.ReplicatedStorage.Library.UI.ItemInterface);
local modRadialImage = shared.require(game.ReplicatedStorage.Library.UI.RadialImage);

local radialConfig = '{"version":1,"size":128,"count":128,"columns":8,"rows":8,"images":["rbxassetid://4467212179","rbxassetid://4467212459"]}';

local interfacePackage = {
    Type = "Character";
};
--==


function interfacePackage.newInstance(interface: InterfaceInstance)
	local playerClass: PlayerClass = shared.modPlayers.get(localPlayer);
    local modData = shared.require(localPlayer:WaitForChild("DataModule"));

	local newWindowFrame = script:WaitForChild("StatusHud"):Clone();
	newWindowFrame.Parent = interface.ScreenGui;
	
	local statusFrame = newWindowFrame:WaitForChild("StatusBars");
	armorBar = statusFrame:WaitForChild("ArmorBar");
	healthBar = statusFrame:WaitForChild("HealthBar");
	
	local statusHudWindow: InterfaceWindow = interface:NewWindow("StatusWindow", newWindowFrame);
	statusHudWindow.IgnoreHideAll = true;
	statusHudWindow.ReleaseMouse = false;
	statusHudWindow:Open();

	local statusEffectsBar = script:WaitForChild("StatusEffectsBar"):Clone();
	statusEffectsBar.Parent = interface.ScreenGui;

	local statusEffectsWindow: InterfaceWindow = interface:NewWindow("StatusEffectsBar", statusEffectsBar);
	statusEffectsWindow.IgnoreHideAll = true;
	statusEffectsWindow.ReleaseMouse = false;
	statusEffectsWindow:Open();

    interface:BindConfigKey("DisableStatusHud", {statusEffectsWindow, statusHudWindow});



end

return interfacePackage;

