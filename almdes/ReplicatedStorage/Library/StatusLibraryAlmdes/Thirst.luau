local RunService = game:GetService("RunService");

local modStatusClass = shared.require(game.ReplicatedStorage.Library.StatusLibrary.StatusClass);
local DamageData: DamageData = shared.require(game.ReplicatedStorage.Data.DamageData);

local statusPackage = {
    Id = "Thirst";
    Icon = "rbxassetid://12017531752";
    Name = "Thirst";
    Description = "This is your thirst level, you will start losing health if this hits 0.\n\nYou can replenish this by consuming items that gives hydration.";

    MetaStatus = true;
    HudVisibleBelow = 20;
    
    Order = 1;
};
--==

function statusPackage.SetValue(statusClass: StatusClassInstance, value: number)
    statusClass.Values.CurValue = value;
    statusClass.Values.LastSet = workspace:GetServerTimeNow();
    statusClass:Sync();
end

function statusPackage.BindTickUpdate(statusClass: StatusClassInstance, tickData: TickData)
    if RunService:IsClient() then return end;

    local healthComp: HealthComp? = statusClass.StatusOwner.HealthComp;
    if healthComp == nil or healthComp.IsDead then return end;

    local statusComp: StatusComp = statusClass.StatusOwner.StatusComp;

    local curVal = statusClass.Values.CurValue;
    local maxVal = statusClass.Values.MaxValue;

    if tickData.s10 == true then 
        local thirstRate = 7.5/6;

        local hungerStatus: StatusClassInstance = statusComp:GetOrDefault("Hunger");
        if hungerStatus.Values.CurValue <= 0 then
            thirstRate = thirstRate * 2;
        end

        statusClass.Values.CurValue = math.clamp(curVal-thirstRate, 0, maxVal);

        statusClass:Sync();
    end;

    if tickData.s5 == true and statusClass.Values.CurValue <= 0 then
        healthComp:TakeDamage(DamageData.new{
            Damage = 1.5;
            DamageType = "Starvation";
        });
    end
end

return modStatusClass.new(statusPackage);