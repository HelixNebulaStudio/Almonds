local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local modCrates = shared.require(game.ReplicatedStorage.Library.Crates);
local modDropRateCalculator = shared.require(game.ReplicatedStorage.Library.DropRateCalculator);
local modRewardsLibrary = shared.require(game.ReplicatedStorage.Library.RewardsLibrary);

--== Script;
local Component = {};

function Component.new(npcClass: NpcClass)
    npcClass.Character:SetAttribute("SkipLocalDespawn", true);
    local healthComp: HealthComp = npcClass.HealthComp;

    healthComp.OnIsDeadChanged:Connect(function(isDead)
        if isDead == false then return end;
        
        local interactable: InteractableInstance;
        local storage: Storage;

        _, interactable, storage = modCrates.Create("npcinventory", nil, npcClass.Character);
        storage.Name = `{npcClass.Name}'s Inventory`;
        interactable.Config:SetAttribute("Label", `Loot {npcClass.Name}`);

        local rewardId = npcClass.Properties.LootableRewardId;
        if rewardId == nil then return end;

        local rewardsLib = modRewardsLibrary:Find(rewardId);
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

            storage:Add(itemId, {Quantity=quantity;});
        end

        npcClass.Character.Destroying:Connect(function()
            Debugger:Warn(`Destroying {storage.Id}`);
            storage:Destroy();
        end)
    end)

end

return Component;