local MissionLibrary = shared.require(game.ReplicatedStorage.Library.MissionLibrary);
--==
local RunService = game:GetService("RunService");


-- MARK: 1 - Shoot on Sight
MissionLibrary.New{
	MissionId = 1;
	MissionType = MissionLibrary.MissionTypes.Core;
	Name = "Shoot on Sight";
	Description = "Kill Bandits.";
	Checkpoint = {
		{Text="Kill $Kills Bandits";};
		{Text="Exfil";};
	};
	SaveData = {Kills=5;};
	Rewards = {};
};

-- MARK: 2 - Unlocking Loot
MissionLibrary.New{
	MissionId = 2;
	MissionType = MissionLibrary.MissionTypes.Core;
	Name = "Unlocking Loot";
	Description = "Find and use tier 1 key and unlock a Small Bandit Camp Crate.";
	Checkpoint = {
		{Text="Find"; CompleteText="Open a Bandit Camp Crate with the Tier 1 Key"; Objectives={"Objective1"};};
		{Text="Exfil";};
	};
	Objectives = {
		["Objective1"]={Index=1; Description="$Amount Tier 1 Key"; CompleteText=nil; Type="RequireItem"; ItemId="t1key"; Amount=1;};
	};
	SaveData = {};
	Rewards = {};
};

-- MARK: 3 - Car Park Cache
MissionLibrary.New{
	MissionId = 3;
	MissionType = MissionLibrary.MissionTypes.Core;
	Name = "Car Park Cache";
	Description = "Raid the Car Park and loot the Crate.";
	Checkpoint = {
		{Text="Raid the Car Park and loot the Crate";};
		{Text="Exfil";};
	};
	SaveData = {};
	Rewards = {};
};

-- MARK: 4 - Lost Delicacy
MissionLibrary.New{
	MissionId = 4;
	MissionType = MissionLibrary.MissionTypes.Core;
	Name = "Lost Delicacy";
	Description = "Find a Cupcake";
	Checkpoint = {
		{Text="Find"; CompleteText="Exfil"; Objectives={"Objective1"};};
	};
	Objectives = {
		["Objective1"]={Index=1; Description="$Amount Cupcake"; Type="RequireItem"; ItemId="cupcake"; Amount=1;};
	};
	SaveData = {};
	Rewards = {};
};

-- MARK: 5 - Lethal Attitude
MissionLibrary.New{
	MissionId = 5;
	MissionType = MissionLibrary.MissionTypes.Core;
	Name = "Lethal Attitude";
	Description = "Find and kill a player.";
	Checkpoint = {
		{Text="Find and kill a player";};
		{Text="Exfil";};
	};
	SaveData = {};
	Rewards = {};
};

-- MARK: 6 - Rise of the Dead
MissionLibrary.New{
	MissionId = 6;
	MissionType = MissionLibrary.MissionTypes.Core;
	Name = "Rise of the Dead";
	Description = "Revive a wounded or dead player.";
	Checkpoint = {
		{Text="Find and revive a wounded or dead player";};
		{Text="Exfil";};
	};
	SaveData = {};
	Rewards = {};
};

return MissionLibrary;
