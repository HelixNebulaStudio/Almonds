local modStatusClass = shared.require(game.ReplicatedStorage.Library.StatusLibrary.StatusClass);
--==
local statusPackage = {
    Id="Thirst";
    Icon="rbxassetid://12017531752";
    Name="Thirst";
    Description="This is your thirst level, if your thirst is below 5% and start losing health.\n\nYou can replenish this by consuming items that gives hydration.";

    MetaStatus=true;
    HudVisibleBelow=5;
    HudVisibleOnIncrease=true;
    Order=1;
};

return modStatusClass.new(statusPackage);