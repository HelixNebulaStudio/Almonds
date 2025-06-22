local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local modLibraryManager = shared.require(game.ReplicatedStorage.Library.LibraryManager);
local library = modLibraryManager.new();

library.EventType = {
	Raid = {Name="Raid";};
	Camp = {Name="Camp";};
}

library:Add{
	Id="carparkraid";
	Name="Car Park Raid";
	
	Type=library.EventType.Raid;
	CycleTimer=120;
	
	Icon="rbxassetid://7304930076";
	
	RewardsId="carparkraid";
	LootMarkOnMap=true;
}

library:Add{
	Id="smallbanditcamp";
	Name="Small Bandit Camp";

	Type=library.EventType.Camp;
	CycleTimer=60;

	Icon="rbxassetid://13111861634";
	IconSize=0.7;

	RewardsId="smallbanditcamp";
	LootMarkOnMap=true;
}

return library;
