local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local CollectionService = game:GetService("CollectionService");

local eventPackage = {
	Id = "carparkraid";
	Name = "Car Park Raid";
	
	Type = "Raid";
	CycleTimer = 120;
	
	Icon = "rbxassetid://7304930076";
	
	RewardsId = "carparkraid";
	LootMarkOnMap = true;
};
--==

function eventPackage.load()

end


return eventPackage;