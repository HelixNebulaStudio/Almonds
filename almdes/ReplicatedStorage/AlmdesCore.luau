local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local AlmdesCore = {};
--==
local modAudio = shared.require(game.ReplicatedStorage.Library.Audio);
local modInteractables = shared.require(game.ReplicatedStorage.Library.InteractablesAlmdes);
local modRemotesManager = shared.require(game.ReplicatedStorage.Library.RemotesManagerAlmdes);

if RunService:IsServer() then
    local modProfile = shared.require(game.ServerScriptService.ServerLibrary.ProfileAlmdes);
    local modGameSave = shared.require(game.ServerScriptService.ServerLibrary.GameSaveAlmdes);
end

Debugger:Warn("Init AlmdesCore.");
return AlmdesCore;