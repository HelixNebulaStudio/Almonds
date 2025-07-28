local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==

local treePackage = {
    LogicString = {
        Default = "HasEnemy & EquipWeapon & AlertTree | IdleTree";
        AlertTree = "IsUsingMelee & MeleeTree | RangeTree";
        MeleeTree = "InMeleeRange & [SwingMelee] | [RunToMeleeRange]";
        RangeTree = "CanFireGun & (RunToFireRange & [FireGun]) | (RunToCover & [ReloadGun])";
        IdleTree = "[Idle]";
    };
}

function treePackage.HasEnemy(npcClass: NpcClass)
    local targetHandlerComp = npcClass:GetComponent("TargetHandler");
    if targetHandlerComp == nil then return false; end;

    local enemyTargetData = targetHandlerComp:MatchFirstTarget(function(targetData)
        if targetData.HealthComp == nil then return end;
        local targetNpcClass: NpcClass = targetData.HealthComp.CompOwner;

        local isAlive = targetNpcClass.HealthComp.IsDead ~= true;
        local isInVision = npcClass:IsInVision(targetNpcClass.RootPart);

        return isAlive and isInVision;
    end);
    npcClass.Properties.EnemyTargetData = enemyTargetData;
    
    return enemyTargetData ~= nil;
end

function treePackage.EquipWeapon(npcClass: NpcClass)
    local wieldComp: WieldComp = npcClass.WieldComp;
    if wieldComp.EquipmentClass then return true; end;

    local primaryWeaponItemId = npcClass.Properties.PrimaryWeaponItemId;
    wieldComp:Equip{
        ItemId = primaryWeaponItemId;
        OnSuccessFunc = function(toolHandler)
            local equipmentClass: EquipmentClass = toolHandler.EquipmentClass;
            if equipmentClass.Class == "Gun" then
                local modifier = equipmentClass.Configurations.newModifier("BanditGun");
                modifier.SetValues.Damage = math.random(3, 5);
                modifier.SetValues.AmmoCapacity = math.random(10, 20);
                equipmentClass.Configurations:AddModifier(modifier, true);
            end
        end;
    };

    return true;
end

function treePackage.IsUsingMelee(npcClass: NpcClass)
    local wieldComp: WieldComp = npcClass.WieldComp;
    if wieldComp.EquipmentClass and wieldComp.EquipmentClass.Class == "Melee" then return true end;
    return false;
end

function treePackage.InMeleeRange(npcClass: NpcClass)
    local enemyTargetData = npcClass.Properties.EnemyTargetData;
    return enemyTargetData.Distance <= 10;
end

function treePackage.RunToMeleeRange(npcClass: NpcClass)
    local enemyTargetData = npcClass.Properties.EnemyTargetData;
    local enemyNpcClass: NpcClass = enemyTargetData.HealthComp.CompOwner;

    npcClass.Move:SetMoveSpeed("set", "sprint", 18, 2, 5);
    npcClass.Move:Follow(enemyNpcClass.RootPart, 2);
end


function treePackage.SwingMelee(npcClass: NpcClass)
    local wieldComp: WieldComp = npcClass.WieldComp;

    local enemyTargetData = npcClass.Properties.EnemyTargetData;
    local enemyNpcClass: NpcClass = enemyTargetData.HealthComp.CompOwner;

    npcClass.Move:HeadTrack(enemyNpcClass.RootPart, 2);
    npcClass.Move:Face(enemyNpcClass.RootPart.Position);

    wieldComp:InvokeToolAction("PrimarySwingRequest");
end

function treePackage.CanFireGun(npcClass: NpcClass)
    local wieldComp: WieldComp = npcClass.WieldComp;
    if wieldComp.EquipmentClass == nil then return false end;
    if wieldComp.EquipmentClass.Properties.Ammo <= 0 then return false end;

    return true;
end

function treePackage.RunToFireRange(npcClass: NpcClass)
    local enemyTargetData = npcClass.Properties.EnemyTargetData;
    local enemyNpcClass: NpcClass = enemyTargetData.HealthComp.CompOwner;

    npcClass.Move:SetMoveSpeed("set", "sprint", 14, 2, 5);
    npcClass.Move:Follow(enemyNpcClass.RootPart, 16, 24);

    return true;
end

function treePackage.FireGun(npcClass: NpcClass)
    local wieldComp: WieldComp = npcClass.WieldComp;
    
    local enemyTargetData = npcClass.Properties.EnemyTargetData;

    local healthComp: HealthComp = enemyTargetData.HealthComp;
    local enemyNpcClass: NpcClass = healthComp.CompOwner;

    npcClass.Move:HeadTrack(enemyNpcClass.RootPart, 2);
    npcClass.Move:Face(enemyNpcClass.RootPart.Position);

    local shootDirection = (enemyNpcClass.RootPart.Position - npcClass.RootPart.Position).Unit;
    
    if not npcClass:IsInVision(enemyTargetData.Model.PrimaryPart, 45) then return end;

    wieldComp:InvokeToolAction(
        "PrimaryFireRequest", 
        shootDirection, 
        enemyNpcClass.Humanoid
    );
end

function treePackage.RunToCover(npcClass: NpcClass)
    local enemyTargetData = npcClass.Properties.EnemyTargetData;
    local enemyNpcClass: NpcClass = enemyTargetData.HealthComp.CompOwner;

    npcClass.Move:SetMoveSpeed("set", "sprint", 18, 2, 5);
    npcClass.Move:Follow(enemyNpcClass.RootPart, 24, 32);

    return true;
end

function treePackage.ReloadGun(npcClass: NpcClass)
    local wieldComp: WieldComp = npcClass.WieldComp;
    if wieldComp.EquipmentClass == nil then return end;
    
    if wieldComp.EquipmentClass.Class == "Gun" 
    and wieldComp.EquipmentClass.Properties.MaxAmmo <= 0 then
        Debugger:Warn(`Out of ammo`);

        wieldComp:Equip{
            ItemId = "machete";
        };
        return;
    end

    wieldComp:InvokeToolAction("ReloadRequest");
end

function treePackage.Idle(npcClass: NpcClass)
end

return treePackage;