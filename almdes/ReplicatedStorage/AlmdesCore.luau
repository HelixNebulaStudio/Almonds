local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local AlmdesCore = {};
--==
local modGlobalVars = shared.require(game.ReplicatedStorage.GlobalVariables);
modGlobalVars.DevVersion="0.0.x";
modGlobalVars.GameVersion = "0.0.1";
modGlobalVars.GameBuild = "2";
modGlobalVars.ModeVerLabel = `Almonds {modGlobalVars.GameVersion}.{modGlobalVars.GameBuild} InDev $UpTime`;

local modBranchConfigs = shared.require(game.ReplicatedStorage.Library.BranchConfigurations);
if game.GameId == 1971060599 then
	modBranchConfigs.CurrentBranch = modBranchConfigs.LiveBranch;
elseif game.GameId == 5119363835 then
	modBranchConfigs.CurrentBranch = modBranchConfigs.DevBranch;
end
modBranchConfigs.BranchColor = Color3.fromRGB(92, 16, 255);

---==

local modAudio = shared.require(game.ReplicatedStorage.Library.Audio);
local modKeyBindsHandler = shared.require(game.ReplicatedStorage.Library:WaitForChild("KeyBindsHandlerAlmdes"));
local modOnEventsHandlers = shared.require(game.ReplicatedStorage.Library:WaitForChild("OnEventHandlersAlmdes"));
local modRemotesManager = shared.require(game.ReplicatedStorage.Library:WaitForChild("RemotesManagerAlmdes"));
local modPlayers = shared.require(game.ReplicatedStorage.Library:WaitForChild("PlayersAlmdes"));
local modInteractables = shared.require(game.ReplicatedStorage.Library:WaitForChild("InteractablesAlmdes"));
local modBranchConfigurations = shared.require(game.ReplicatedStorage.Library:WaitForChild("BranchConfigurationsAlmdes"));
local modItemsLibrary = shared.require(game.ReplicatedStorage.Library:WaitForChild("ItemsLibraryAlmdes"));
local modWeaponsLibrary = shared.require(game.ReplicatedStorage.Library:WaitForChild("WeaponsLibraryAlmdes"));
local modClothingLibrary = shared.require(game.ReplicatedStorage.Library:WaitForChild("ClothingLibraryAlmdes"));
local modToolsLibrary = shared.require(game.ReplicatedStorage.Library:WaitForChild("ToolsLibraryAlmdes"));
local modStatusLibrary = shared.require(game.ReplicatedStorage.Library:WaitForChild("StatusLibraryAlmdes"));
local modRewardsLibrary = shared.require(game.ReplicatedStorage.Library:WaitForChild("RewardsLibraryAlmdes"));
local modStoragePresetsLibrary = shared.require(game.ReplicatedStorage.Library:WaitForChild("StoragePresetsLibraryAlmdes"));
local modCrateLibrary = shared.require(game.ReplicatedStorage.Library:WaitForChild("CrateLibraryAlmdes"));
local modStatusEffects = shared.require(game.ReplicatedStorage.Library:WaitForChild("StatusEffectsAlmdes"));

if RunService:IsServer() then
    local modProfile = shared.require(game.ServerScriptService.ServerLibrary.ProfileAlmdes);
    local modGameSave = shared.require(game.ServerScriptService.ServerLibrary.GameSaveAlmdes);
    local modApiRequestLibrary = shared.require(game.ServerScriptService.ServerLibrary.ApiRequestLibraryAlmdes);
    local modBaseBuildingSystem = shared.require(game.ServerScriptService.ServerLibrary.BaseBuildingSystem);
    local modWorldEvents = shared.require(game.ServerScriptService.ServerLibrary.WorldEvents);
end

local stormCycleTick = nil;
local function startStormCycle()
    if stormCycleTick == nil then
        stormCycleTick = workspace:GetServerTimeNow() + (60*8);
        task.spawn(function()
            while true do
                task.wait(10);
                if workspace:GetServerTimeNow() >= stormCycleTick then
                    stormCycleTick = workspace:GetServerTimeNow() + (60*8);
                end
                workspace:SetAttribute("StormCycleTick", stormCycleTick);
            end
        end)
    end
end

function AlmdesCore.OnPlayerAdded(player)
    if RunService:IsServer() then
    elseif RunService:IsClient() then
    end
end

function AlmdesCore.OnCharacterAdded(player, character)
    if RunService:IsServer() then
        startStormCycle();
    elseif RunService:IsClient() then
    end
end

function AlmdesCore.OnPlayerRemoving(player)
    if RunService:IsServer() then
    elseif RunService:IsClient() then
    end
end


Debugger:Warn("Init AlmdesCore.");
return AlmdesCore;