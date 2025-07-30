local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local modVector = shared.require(game.ReplicatedStorage.Library.Util.Vector);

--== Script;
local Component = {};

function Component.new(npcClass: NpcClass)
    return function()
        local wieldComp: WieldComp = npcClass.WieldComp;
        if wieldComp.ToolHandler == nil then return end;
        
        for a=1, #wieldComp.ToolHandler.Prefabs do
            local prefab: Model = wieldComp.ToolHandler.Prefabs[a];
            
            local prefabCf: CFrame = prefab:GetPivot();
            prefab.Parent = workspace.Debris;
            
            for _, obj in pairs(prefab:GetDescendants()) do
                if obj:IsA("JointInstance") then
                    obj:Destroy();

                elseif obj:IsA("BasePart") then
                    if obj.Name == "Clip" or obj.Name == "Debris" or obj.Name == "PrimaryPart" then
                        obj:Destroy();
                        continue;
                    end
                    obj.CollisionGroup = "Debris";
                    obj.CanCollide = true;
                    obj.Anchored = false;

                    local dir = (obj.Position - prefabCf.Position).Unit;
                    if shared.IsNan(dir) then
                        dir = modVector.RandomUnitVector(3);
                    end

                    local mass = obj:GetMass();
                    obj:ApplyImpulse(dir * mass * 50);
                end
            end

            game.Debris:AddItem(prefab, 10);
        end
    end
end

return Component;