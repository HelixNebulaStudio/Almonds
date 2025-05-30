local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");
local StarterGui = game:GetService("StarterGui");
local GuiService = game:GetService("GuiService");
local UserInputService = game:GetService("UserInputService");
local ContextActionService = game:GetService("ContextActionService");
local TweenService = game:GetService("TweenService");
local CollectionService = game:GetService("CollectionService");

local camera = workspace.CurrentCamera;
local localPlayer = game.Players.LocalPlayer;

local modGlobalVars = shared.require(game.ReplicatedStorage.GlobalVariables);
local modRemotesManager = shared.require(game.ReplicatedStorage.Library.RemotesManager);
local modConfigurations = shared.require(game.ReplicatedStorage.Library.Configurations);
local modAudio = shared.require(game.ReplicatedStorage.Library.Audio);
local modBranchConfigs = shared.require(game.ReplicatedStorage.Library.BranchConfigurations);
local modCameraGraphics = shared.require(game.ReplicatedStorage.PlayerScripts.CameraGraphics);

local AlmdesInterface = shared.require(game.ReplicatedStorage.Library.UI.InterfaceClass).new(script.Parent);
--==
function AlmdesInterface.clientGuisLoad()
    local self: Interface = AlmdesInterface;

    self:Init();

    if localPlayer.Character then
        if modConfigurations.AutoOpenBlinds then 
            self:ToggleGameBlinds(true, 3);
        end;

    else
        local mainMenuWindow: InterfaceWindow = self:GetWindow("MainMenu");
        mainMenuWindow:Open();

    end

    self.Garbage:Tag(function()
    end)
end

return AlmdesInterface;