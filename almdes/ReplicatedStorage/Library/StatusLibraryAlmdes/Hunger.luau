local RunService = game:GetService("RunService");

local modStatusClass = shared.require(game.ReplicatedStorage.Library.StatusLibrary.StatusClass);
local DamageData: DamageData = shared.require(game.ReplicatedStorage.Data.DamageData);

local statusPackage = {
    Id="Hunger";
    Icon="rbxassetid://12017530629";
    Name="Hunger";
    Description="This is your hunger level, you will start losing health if this hits 0.\n\nYou can replenish this by eating.";

    MetaStatus=true;
    HudVisibleBelow=10;
    
    Order=0;
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

    local curVal = statusClass.Values.CurValue;
    local maxVal = statusClass.Values.MaxValue;

    if tickData.s10 == true then 
        local hungerRate = 5/6; -- * per min;
        statusClass.Values.CurValue = math.clamp(curVal-hungerRate, 0, maxVal);
        
        statusClass:Sync();
    end;

    if tickData.s5 == true and statusClass.Values.CurValue <= 0 then
        healthComp:TakeDamage(DamageData.new{
            Damage = 3;
            DamageType = "Starvation";
        });
    end
end

return modStatusClass.new(statusPackage);