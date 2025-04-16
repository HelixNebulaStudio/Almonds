local modStatusClass = require(game.ReplicatedStorage.Library.StatusLibrary.StatusClass);
--==
local RunService = game:GetService("RunService");

local DamageData: DamageData = require(game.ReplicatedStorage.Data.DamageData);

--==
local statusPackage = {
    Id="Dehydration";
    Icon="rbxassetid://12017531752";
    Name="Dehydration";
    Description="You are dehydrated, you need to consume items that gives hydration.";
};

function statusPackage.OnTick(statusClass: StatusClassInstance, tickData: TickData)
    if RunService:IsClient() then return end;
    if tickData.s5 == false then return end;

    local healthComp: HealthComp? = statusClass.StatusOwner.HealthComp;
    if healthComp == nil then return end;

    healthComp:TakeDamage(DamageData.new{
        Damage = 3;
        DamageType = "Dehydration";
    });
end

return modStatusClass.new(statusPackage);