local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local CollectionService = game:GetService("CollectionService");
local HttpService = game:GetService("HttpService");

local modEventsLibrary = shared.require(game.ReplicatedStorage.Library.EventsLibrary);
local modScheduler = shared.require(game.ReplicatedStorage.Library.Scheduler);
local modPropertiesVariable = shared.require(game.ReplicatedStorage.Library.PropertiesVariable);
local modGarbageHandler = shared.require(game.ReplicatedStorage.Library.GarbageHandler);

local mapEventsFolder: Folder = workspace.Environment.Game.Events;
local eventsPrefabs: Folder = game.ServerStorage.Prefabs.Events;

local WorldEvents = {};
WorldEvents.__index = WorldEvents;

local scheduler: Scheduler = modScheduler.new("WorldEvents", 0.2);
WorldEvents.Scheduler = scheduler;
WorldEvents.Instances = {};
--==

function WorldEvents:Instance(eventPackage)
    eventPackage.__index = eventPackage;

    local instance = {
        WorldEvents = WorldEvents;
        Scheduler = scheduler;

        Garbage = modGarbageHandler.new();
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

    scheduler.OnStepped:Connect(function()
        local publicData = {};

        for eventId, eventInstance: WorldEventInstance in pairs(WorldEvents.Instances) do
            local public = eventInstance.Public;
            if public == nil or next(public) == nil then continue end;

            publicData[eventId] = public;
        end

        local eventLibScr: ModuleScript = modEventsLibrary.Script;
        eventLibScr:SetAttribute("Public", HttpService:JSONEncode(publicData));
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