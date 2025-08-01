local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local modEquipmentClass = shared.require(game.ReplicatedStorage.Library.EquipmentClass);
local modDropRateCalculator = shared.require(game.ReplicatedStorage.Library.DropRateCalculator);
local modRewardsLibrary = shared.require(game.ReplicatedStorage.Library.RewardsLibraryAlmdes);
local modVector = shared.require(game.ReplicatedStorage.Library.Util.Vector);

if RunService:IsServer() then
	modItemDrops = shared.require(game.ServerScriptService.ServerLibrary.ItemDrops);
end
--==

local toolPackage = {
	ItemId=script.Name;
	Class="Melee";
	HandlerType="MeleeTool";

	Animations={
		Core={Id=16923739633;};
		PrimaryAttack={Id=17765553002};
		Load={Id=16923742307};
		Inspect={Id=16923747582; WaistStrength=0.2;};
		Charge={Id=16923735442;};
		Throw={Id=16923753693};
		Unequip={Id=16923756581};
	};
	Audio={
		Throw={Id=5083063763; Pitch=1; Volume=1;};

		Load={Id=4601593953; Pitch=1; Volume=2;};
		PrimaryHit={Id=4844105915; Pitch=1; Volume=2;};
		PrimarySwing={Id=4601593953; Pitch=1.4; Volume=2;};
	};

	Configurations={
		Category = "Pointed";
		Type="Tool";

		EquipLoadTime=0.5;
		Damage=300;

		PrimaryAttackSpeed=0.5;
		PrimaryAttackAnimationSpeed=0.5;

		HitRange=8;

		WaistRotation=math.rad(0);
		StaminaCost = 25;
		StaminaDeficiencyPenalty = 0.5;

		UseViewmodel = false;

		-- Throwable
		Throwable = true;
		ThrowDamagePercent = 0.04;

		ChargeDuration = 0.5;
		ThrowStaminaCost = 25;

		ThrowRate = 1;
		ThrowWaistRotation=math.rad(0);

		--== Projectile
		ProjectileId = "pickaxe";
		ProjectileConfig = {
			Velocity = 30;
			Bounce = 0;
			LifeTime = 10;
		};
		VelocityBonus = 30;

		ConsumeOnThrow=false;
	};
	Properties={};
};

function toolPackage.newClass()
	return modEquipmentClass.new(toolPackage);
end

function toolPackage.BindMeleePointHit(handler: ToolHandlerInstance, packet)
	if packet == nil then return end;

	local rayHit = packet.RayHit;
	local rayPoint = packet.RayPoint;
	if rayHit.Parent == nil then return end;

	local resourcePileConfig: Configuration? = rayHit.Parent:FindFirstChild("ResourcePile") :: Configuration;
	if resourcePileConfig == nil then return end;

	local pileType = resourcePileConfig:GetAttribute("PileType");
	if pileType ~= "MetalPile" then return end;

	if RunService:IsClient() then
		packet.Action = "call";
		packet.CallFuncName = "BindMeleePointHit";
		return packet;
	end

	local mainToolModel = handler.MainToolModel;
	local hitDistance = (rayPoint - mainToolModel.PrimaryPart.Position).Magnitude;

	if hitDistance > toolPackage.Configurations.HitRange then return end;
	
	local isValidRayPoint = modVector.IsInBoundingBox(
		rayHit.CFrame, 
		rayHit.Size + Vector3.new(0.5, 0.5, 0.5),
		rayPoint
	);
	if not isValidRayPoint then return end;

	local rewardId = resourcePileConfig:GetAttribute("RewardId");

	local rewardsLib = modRewardsLibrary:Find(rewardId);
	if rewardId == nil or rewardsLib == nil then return end;

	local rewards = modDropRateCalculator.RollDrop(rewardsLib);
	for b=1, #rewards do
		local item = rewards[b];
		local itemId = item.ItemId;
		local quantity = 1;

		if type(item.Quantity) == "table" then
			quantity = math.random(item.Quantity.Min, item.Quantity.Max);
		elseif item.Quantity then
			quantity = item.Quantity;
		end

		local spawnDir = (mainToolModel.PrimaryPart.Position-rayPoint).Unit
		local spawnPos = rayPoint + spawnDir;

		modItemDrops.Spawn({Type="Custom"; ItemId=itemId; Quantity=quantity}, CFrame.new(spawnPos), nil, false);
	end

	return;
end

return toolPackage;