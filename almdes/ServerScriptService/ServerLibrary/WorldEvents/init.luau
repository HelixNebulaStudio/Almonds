local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local CollectionService = game:GetService("CollectionService");

local modEventsLibrary = shared.require(game.ReplicatedStorage.Library.EventsLibrary);
local modScheduler = shared.require(game.ReplicatedStorage.Library.Scheduler);
local modPropertiesVariable = shared.require(game.ReplicatedStorage.Library.PropertiesVariable);

local mapEventsFolder: Folder = workspace.Environment.Game.Events;
local eventsPrefabs: Folder = game.ServerStorage.Prefabs.Events;

local WorldEvents = {};
WorldEvents.__index = WorldEvents;

local scheduler = modScheduler.new("WorldEvents", 0.2);
WorldEvents.Scheduler = scheduler;
WorldEvents.Instances = {};
--==

function WorldEvents:Instance(eventPackage)
    eventPackage.__index = eventPackage;

    local instance = {
        WorldEvents = WorldEvents;
        Scheduler = scheduler;

        Properties = modPropertiesVariable.new({});
        Public = {};
    };

    setmetatable(instance, eventPackage);
    return instance;
end

function WorldEvents.onRequire()
    task.spawn(function()
        while #game.Players:GetPlayers() <= 0 do
            task.wait();
        end
        for _, mapObjectFolder in pairs(mapEventsFolder:GetChildren()) do
            local eventId = mapObjectFolder.Name;
            local eventLib = modEventsLibrary:Find(eventId);
            if eventLib == nil then continue end;
            
            eventLib.TemplateEventMap = mapObjectFolder;
            mapObjectFolder.Parent = script;

            WorldEvents.load(eventLib);
        end
    end)
end

function WorldEvents.load(eventPackage)
    local eventId = eventPackage.Id;
    Debugger:Warn(`Loading event {eventId}.`);

    local instance = WorldEvents.Instances[eventId];
    if instance == nil then
        instance = WorldEvents:Instance(eventPackage);

        if instance.newInstance then
            instance:newInstance();
        end

        WorldEvents.Instances[eventId] = instance;
    end
    
    return instance;
end

return WorldEvents;