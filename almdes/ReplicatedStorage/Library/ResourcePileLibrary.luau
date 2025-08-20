local ResourcePileLibrary = {};
ResourcePileLibrary.__index = ResourcePileLibrary;
--==
local RunService = game:GetService("RunService");

local modLibraryManager = shared.require(game.ReplicatedStorage.Library.LibraryManager);
local modItemsLibrary = shared.require(game.ReplicatedStorage.Library.ItemsLibrary);

local modDropRateCalculator = shared.require(game.ReplicatedStorage.Library.DropRateCalculator);
local modRewardsLibrary = shared.require(game.ReplicatedStorage.Library.RewardsLibraryAlmdes);
local modVector = shared.require(game.ReplicatedStorage.Library.Util.Vector);

if RunService:IsServer() then
	modItemDrops = shared.require(game.ServerScriptService.ServerLibrary.ItemDrops);
end
--==

function ResourcePileLibrary.BindToolHit(handler: ToolHandlerInstance, packet)
    if RunService:IsClient() then return end;
    
    local toolPackage = handler.ToolPackage;
    if toolPackage.CompatiblePileType == nil then return end;

	local hitPart = packet.RayHit;
	local hitPoint = packet.RayPoint;
	if hitPart.Parent == nil then return end;

	local resourcePileConfig: Configuration? = hitPart.Parent:FindFirstChild("ResourcePile") :: Configuration;
	if resourcePileConfig == nil then return end;

	local pileType = resourcePileConfig:GetAttribute("PileType");
	if table.find(toolPackage.CompatiblePileType, pileType) == nil then return end;

	local mainToolModel = handler.MainToolModel;
	local hitDistance = (hitPoint - mainToolModel.PrimaryPart.Position).Magnitude;

	if hitDistance > toolPackage.Configurations.HitRange then return end;
	
	local isValidRayPoint = modVector.IsInBoundingBox(
		hitPart.CFrame, 
		hitPart.Size + Vector3.new(0.5, 0.5, 0.5),
		hitPoint
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

		local spawnDir = (mainToolModel.PrimaryPart.Position-hitPoint).Unit
		local spawnPos = hitPoint + spawnDir;

		modItemDrops.spawn{
			ItemId = itemId;
			Quantity = quantity;
			SpawnCFrame = CFrame.new(spawnPos);
			DespawnDuration = false;
		};
	end

    return;
end

return ResourcePileLibrary;