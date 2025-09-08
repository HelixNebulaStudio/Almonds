local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local modClientGuis = shared.require(game.ReplicatedStorage.PlayerScripts.ClientGuis);
local modStatusClass = shared.require(game.ReplicatedStorage.Library.StatusLibrary.StatusClass);
local DamageData: DamageData = shared.require(game.ReplicatedStorage.Data.DamageData);

local statusPackage = {
    Id = "Workbench";
    Name = "Workbench";
    Icon = `rbxassetid://12122151861`;
    Description = ``;
    Buff = true;
    Visible = false;
    
    Order=0;
};
--==

function statusPackage.BindTickUpdate(statusClass: StatusClassInstance, tickData: TickData)
    if RunService:IsClient() then return end;
    if tickData.ms500 ~= true then return end;

    local workbenchInteractable = statusClass.Values.ActiveInteractable;
    if workbenchInteractable == nil then 
        statusClass.IsExpired = true;
        return;
    end;
    
    local dist = statusClass.StatusOwner:DistanceFromCharacter(workbenchInteractable.Part.Position);
    if dist <= 10 then 
        return;
    end;

    statusClass.Values.ActiveInteractable = nil;
    statusClass.IsExpired = true;

    statusClass:Sync();
end

function statusPackage.BindApply(statusClass: StatusClassInstance)
    if RunService:IsServer() then return end;

    task.delay(0.1, function()
        modClientGuis.fireEvent("UpdateCraftingStatus");
    end)
end

function statusPackage.BindExpire(statusClass: StatusClassInstance)
    if RunService:IsServer() then return end;

    task.delay(0.1, function()
        modClientGuis.fireEvent("UpdateCraftingStatus");
    end)
end

return modStatusClass.new(statusPackage);