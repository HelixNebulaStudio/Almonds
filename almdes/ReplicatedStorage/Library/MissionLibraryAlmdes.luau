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
	SaveData = {Kills=10;};
	Rewards = {};
};


return MissionLibrary;
