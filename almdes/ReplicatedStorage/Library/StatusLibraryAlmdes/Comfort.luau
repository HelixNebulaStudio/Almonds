local RunService = game:GetService("RunService");

local modStatusClass = shared.require(game.ReplicatedStorage.Library.StatusLibrary.StatusClass);
--==
local statusPackage = {
    Id = "Comfort";
    Icon = "rbxassetid://12017533036";
    Name = "Comfort";
    Description = "This is your comfort level, your healing will be reduced if this is below 50%.\n\nTo increase your comfort, maintain your hunger level and be near a heat source.";

    MetaStatus = true;
    HudVisibleBelow = 49;
    HudVisibleOnIncrease = true;
    Order = 3;
};

local ComfortWeights = {
    Hunger = {Weight = 0.4; Threshold = 50};
    Thirst = {Weight = 0.2; Threshold = 30};
    Campfire = {Weight = 0.4; Threshold = 100};
};
statusPackage.ComfortWeights = ComfortWeights;

function statusPackage.BindTickUpdate(statusClass: StatusClassInstance, tickData: TickData)
    if RunService:IsClient() then return end;

    local statusComp: StatusComp = statusClass.StatusOwner.StatusComp;

    if tickData.ms100 == true then
        local newComfort = 0;

        for statusId, statusClass in pairs(statusComp.List) do
            local weightData = ComfortWeights[statusId];
            if weightData == nil then continue end;

            local curValue = statusClass.Values.CurValue;
            local ratio = math.clamp(curValue / weightData.Threshold, 0, 1) * weightData.Weight;
            newComfort += ratio;
        end

        newComfort = math.clamp(newComfort, 0, 1) * 100;
        statusClass.Values.CurValue = newComfort;

        statusClass:Sync();
    end
end

return modStatusClass.new(statusPackage);