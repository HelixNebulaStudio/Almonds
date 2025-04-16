local modStatusClass = require(game.ReplicatedStorage.Library.StatusLibrary.StatusClass);
--==
local RunService = game:GetService("RunService");

local DamageData: DamageData = require(game.ReplicatedStorage.Data.DamageData);

--==
local statusPackage = {
    Id="Starvation";
    Icon="rbxassetid://12017530629";
    Name="Starvation";
    Description="You are starving, you need to eat food.";
};

function statusPackage.OnTick(statusClass: StatusClassInstance, tickData: TickData)
    if RunService:IsClient() then return end;
    if tickData.s5 == false then return end;

    local healthComp: HealthComp? = statusClass.StatusOwner.HealthComp;
    if healthComp == nil then return end;

    healthComp:TakeDamage(DamageData.new{
        Damage = 2.5;
        DamageType = "Starvation";
    });
end

return modStatusClass.new(statusPackage);