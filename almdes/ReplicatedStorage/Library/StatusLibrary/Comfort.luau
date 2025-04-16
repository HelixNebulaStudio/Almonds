local modStatusClass = require(game.ReplicatedStorage.Library.StatusLibrary.StatusClass);
--==
local statusPackage = {
    Id="Comfort";
    Icon="rbxassetid://12017533036";
    Name="Comfort";
    Description="This is your comfort level, you will heal faster from food if your comfort level is higher than 50%.\n\nTo increase your comfort level, you need to be near a heat source and friendlies.";

    MetaStatus=true;
    HudVisibleBelow=5;
    HudVisibleOnIncrease=true;
    Order=1;
};

return modStatusClass.new(statusPackage);