local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local modDamageTag = shared.require(game.ReplicatedStorage.Library.DamageTag);

local DamageData = shared.require(game.ReplicatedStorage.Data.DamageData);
--==

return function(event: EventPacket, ...)
    local npcClass: NpcClass = ...;
    if npcClass == nil then return end;

	local deathPosition = npcClass.Properties.DeathPosition;
	
	local playerTags = modDamageTag:Get(npcClass.Character, "Player");
	for a=1, #playerTags do
		local playerTag = playerTags[a];
		task.spawn(function()
			local player: Player = playerTag.Player;
			if player == nil or not game.Players:IsAncestorOf(player) then return end;

			local profile: ProfileAlmdes = shared.modProfile:Get(player) :: ProfileAlmdes;
			local gameSave: GameSaveAlmdes = profile:GetActiveSave() :: GameSaveAlmdes;

			local playRunSession: PlayRunSession = gameSave.Session;
			if playRunSession == nil then return end;

			playRunSession:AddStat("NpcKills", 1);
		end)
	end
end;
