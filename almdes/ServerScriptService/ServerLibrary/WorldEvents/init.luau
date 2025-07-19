local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local CollectionService = game:GetService("CollectionService");

local modEventsLibrary = shared.require(game.ReplicatedStorage.Library.EventsLibrary);
local modScheduler = shared.require(game.ReplicatedStorage.Library.Scheduler);

local mapEventsFolder: Folder = workspace.Environment.Game.Events;
local eventsPrefabs: Folder = game.ServerStorage.Prefabs.Events;

local WorldEvents = {};
WorldEvents.__index = WorldEvents;
--==

function WorldEvents.onRequire()
    task.spawn(function()
        game.Players.PlayerAdded:Wait();
        Debugger:Warn(`Init WorldEvents.`);
        
        for _, mapObjectFolder in pairs(mapEventsFolder:GetChildren()) do
            
        end
    end)
end

function WorldEvents.load(eventPackage)
        
end

return WorldEvents;