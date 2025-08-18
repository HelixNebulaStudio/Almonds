local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");
local TweenService = game:GetService("TweenService");

local modInteractables = shared.require(game.ReplicatedStorage.Library.InteractablesAlmdes)
local modStatusClass = shared.require(game.ReplicatedStorage.Library.StatusLibrary.StatusClass);
local modMath = shared.require(game.ReplicatedStorage.Library.Util.Math);

local localPlayer = game.Players.LocalPlayer;
--==
local statusPackage = {
    Id = "Campfire";
    Icon = "rbxassetid://6734447412";
    Name = "Campfire";
    Description = "You are near a campfire.";
    Buff = true;
    ExpiresOnDeath = true;

    BuffDistance = 50;
};

function statusPackage.BindApply(statusClass: StatusClassInstance)
end

function statusPackage.BindExpire(statusClass: StatusClassInstance)
end

function statusPackage.BindTickUpdate(statusClass: StatusClassInstance, tickData: TickData)
    local campfireModel = statusClass.Values.CampfireModel;
    if campfireModel == nil 
    or not workspace:IsAncestorOf(campfireModel) then
        statusClass.IsExpired = true;
        return;
    end

    if RunService:IsClient() then
        if tickData.ms100 ~= true then return end;

        local playerClass: PlayerClass = statusClass.StatusOwner;

        local playerPos = playerClass.RootPart.Position;
        local campfirePos = campfireModel:GetPivot().Position;

        local distance = (playerPos - campfirePos).Magnitude;
        statusClass.Alpha = modMath.MapNum(distance, statusPackage.BuffDistance, 8, 0, 1, true);

    end
end

return modStatusClass.new(statusPackage);