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
modBranchConfigs.BranchColor = modBranchConfigs.CurrentBranch.Color;

local modAudio = shared.require(game.ReplicatedStorage.Library.Audio);
local modInteractables = shared.require(game.ReplicatedStorage.Library.InteractablesAlmdes);
local modRemotesManager = shared.require(game.ReplicatedStorage.Library.RemotesManagerAlmdes);

if RunService:IsServer() then
    local modProfile = shared.require(game.ServerScriptService.ServerLibrary.ProfileAlmdes);
    local modGameSave = shared.require(game.ServerScriptService.ServerLibrary.GameSaveAlmdes);
    local modApiRequestLibrary = shared.require(game.ServerScriptService.ServerLibrary.ApiRequestLibraryAlmdes);

end

Debugger:Warn("Init AlmdesCore.");
return AlmdesCore;