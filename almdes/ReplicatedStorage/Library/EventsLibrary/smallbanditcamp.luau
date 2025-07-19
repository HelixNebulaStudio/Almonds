local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local CollectionService = game:GetService("CollectionService");

local eventPackage = {
	Id = "smallbanditcamp";
	Name = "Small Bandit Camp";

	Type = "Camp";
	CycleTimer = 60;

	Icon = "rbxassetid://13111861634";
	IconSize = 0.7;

	RewardsId = "smallbanditcamp";
	LootMarkOnMap = true;
};
--==


return eventPackage;