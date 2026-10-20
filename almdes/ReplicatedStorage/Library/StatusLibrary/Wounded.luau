local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local modStatusClass = shared.require(game.ReplicatedStorage.Library.StatusLibrary.StatusClass);
local modConfigurations = shared.require(game.ReplicatedStorage.Library.Configurations);
local modInteractables = shared.require(game.ReplicatedStorage.Library.Interactables);

local localPlayer = game.Players.LocalPlayer;
--==
local statusPackage = {
	Id = "Wounded";
	Icon = "rbxassetid://7482205902";
	Name = "Wounded";
	Description = "You are wounded! You can't passively heal or regenerate armor.";
	Buff = false;
};

function statusPackage.BindApply(statusClass: StatusClassInstance)
    local characterClass: CharacterClass = statusClass.StatusOwner :: CharacterClass;
    if characterClass == nil then return end;
	local healthComp: HealthComp = characterClass.HealthComp;

	if RunService:IsClient() then
		if characterClass.ClassName ~= "PlayerClass" then return end;

		local playerClass: PlayerClass = characterClass :: PlayerClass;
		if playerClass:GetInstance() ~= localPlayer then return; end

		local modData = shared.require(localPlayer:WaitForChild("DataModule") :: ModuleScript);
		local modCharacter = modData:GetModCharacter();

		modCharacter.CharacterProperties.IsWounded = true;

	else
		local new = modInteractables.createInteractable("Revive");
		new.Parent = characterClass.Character;

		statusClass.Values.ReviveInteractable = new;
	end

	healthComp:SetHealth(0);

	if RunService:IsClient() then return end;

	if characterClass.ClassName == "NpcClass" then
		local npcClass: NpcClass = characterClass :: NpcClass;
		npcClass:ToggleInteractable(false);
		npcClass.PlayAnimation("WoundedIdle");
	end
end

function statusPackage.BindExpire(statusClass: StatusClassInstance)
    local characterClass: CharacterClass = statusClass.StatusOwner :: CharacterClass;
    if characterClass == nil then return end;

	local statusComp: StatusComp = characterClass.StatusComp;
	local healthComp: HealthComp = characterClass.HealthComp;

	if RunService:IsServer() then
		if healthComp.CurHealth > 0 then
			-- Character was revived
			if statusClass.Values.ReviveInteractable then
				statusClass.Values.ReviveInteractable:Destroy();
				statusClass.Values.ReviveInteractable = nil;
			end

		else
			if characterClass.Kill then
				characterClass:Kill();
			end
			
		end


	elseif RunService:IsClient() then
		if characterClass.ClassName ~= "PlayerClass" then return end;

		local playerClass: PlayerClass = characterClass :: PlayerClass;
		if playerClass:GetInstance() ~= localPlayer then return; end

		local modData = shared.require(localPlayer:WaitForChild("DataModule") :: ModuleScript);
		local modCharacter = modData:GetModCharacter();

		modCharacter.CharacterProperties.IsWounded = false;
	end

	if characterClass.ClassName == "NpcClass" then
		local npcClass: NpcClass = characterClass :: NpcClass;
		npcClass:ToggleInteractable(true);
		npcClass.StopAnimation("WoundedIdle");

	end
end

function statusPackage.BindTickUpdate(statusClass: StatusClassInstance, tickData: TickData)
    local characterClass: CharacterClass = statusClass.StatusOwner :: CharacterClass;
    if characterClass == nil then return end;

	if characterClass.HealthComp.CurHealth > 0 then
		statusClass.IsExpired = true;
		statusClass:Sync();
	end

	return;
end

return modStatusClass.new(statusPackage);
