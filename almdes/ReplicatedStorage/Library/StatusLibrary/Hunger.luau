local modStatusClass = shared.require(game.ReplicatedStorage.Library.StatusLibrary.StatusClass);
--==
local statusPackage = {
    Id="Hunger";
    Icon="rbxassetid://12017530629";
    Name="Hunger";
    Description="This is your hunger level, if your hunger is below 10% and start losing health.\n\nYou can replenish this by eating.";

    MetaStatus=true;
    HudVisibleBelow=10;
    HudVisibleOnIncrease=true;
    Order=0;
};

return modStatusClass.new(statusPackage);