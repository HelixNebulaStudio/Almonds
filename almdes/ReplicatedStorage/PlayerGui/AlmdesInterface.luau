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
local modRemotesManager = shared.require(game.ReplicatedStorage.Library.RemotesManagerAlmdes);
local modConfigurations = shared.require(game.ReplicatedStorage.Library.Configurations);
local modAudio = shared.require(game.ReplicatedStorage.Library.Audio);
local modBranchConfigs = shared.require(game.ReplicatedStorage.Library.BranchConfigurations);
local modCameraGraphics = shared.require(game.ReplicatedStorage.PlayerScripts.CameraGraphics);
local modClientLighting = shared.require(game.ReplicatedStorage.PlayerScripts.ClientLighting);

local interface = shared.require(game.ReplicatedStorage.Library.UI.InterfaceClass).new(script.Parent);
--==
function interface.onRequire()
    remoteItemProcessor = modRemotesManager:Get("ItemProcessor");
end

function interface.clientGuisLoad()
    local modData = shared.require(localPlayer:WaitForChild("DataModule"));
    local interface: InterfaceInstance = interface;

    interface.Colors.ForepanelBackground = Color3.fromRGB(47, 49, 65);
    interface.Colors.BorderColorPrimary = Color3.fromRGB(108, 91, 170);
    
	--==MARK: ItemProcessor
    interface:BindEvent("DataItemProcessorUpdate", function(returnPacket)
        if returnPacket == nil or returnPacket.Data == nil then return end;
        Debugger:StudioLog(`ItemProcessor returnPacket`, returnPacket);

        modData.ItemProcessor = returnPacket.Data;
    end)
	function remoteItemProcessor.OnClientInvoke(action, packet)
		if action == "sync" then
            interface:FireEvent("DataItemProcessorUpdate", packet);
		end
	end
    --==

    interface:Init();

    if localPlayer.Character then
        if modConfigurations.AutoOpenBlinds then 
            interface:ToggleGameBlinds(true, 3);
        end;

    else
        local mainMenuWindow: InterfaceWindow = interface:GetWindow("MainMenu");
        mainMenuWindow:Open();

    end

    local playerClass: PlayerClass = shared.modPlayers.get(localPlayer);
    interface.Garbage:Tag(function()
        playerClass.HealthComp.OnIsDeadChanged:Connect(function()
            if playerClass.HealthComp.IsDead == false then return end;

            modClientLighting:SetAtmosphere("Death");
        end)
    end)

	task.spawn(function()
        local rPacket = remoteItemProcessor:InvokeServer("sync");
		interface:FireEvent("DataItemProcessorUpdate", rPacket);
	end);
end

return interface;