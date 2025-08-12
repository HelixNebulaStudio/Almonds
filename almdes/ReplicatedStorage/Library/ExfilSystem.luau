local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");
local TweenService = game:GetService("TweenService");

local modVehicles = shared.require(game.ReplicatedStorage.Entity.Vehicles);

if RunService:IsServer() then
    prefabStorage = game.ServerStorage.Prefabs;
end

local ExfilSystem = {};
ExfilSystem.__index = ExfilSystem;
--==

function ExfilSystem:SpawnExfilHelicopter(lz: Vector3, final: boolean?)
    Debugger:Warn(`SpawnExfilHelicopter {lz} {final}`);

    local corePart = Instance.new("Part");
    corePart.Name = `ExfilHeliCore`;
    corePart.Size = Vector3.zero;
    corePart.Transparency = 1;
    corePart.Anchored = true;
    corePart.CanCollide = false;
    corePart.CanQuery = false;
    corePart.CFrame = CFrame.new(lz) * CFrame.Angles(0, math.rad(math.random(0, 360)), 0);
    corePart:AddTag("ActiveExfil");
    corePart:SetAttribute("Type", "Helicopter");

    corePart.Parent = workspace.Environment.Game;

    local coreCf: CFrame = corePart.CFrame;

    local lzCf: CFrame = coreCf * CFrame.new(0, 4, 0);
    local descendCf: CFrame = lzCf * CFrame.new(0, 100, 0);
    
    local spawnCf: CFrame = descendCf * CFrame.Angles(math.rad(-15), 0, 0) * CFrame.new(0, 0, 2500);
    local stage2Cf: CFrame = descendCf * CFrame.Angles(math.rad(-10), 0, 0) * CFrame.new(0, 0, 1500);

    local heliControlAtt: Attachment = Instance.new("Attachment");
    heliControlAtt.Name = "ExfilHeliControl";
    heliControlAtt.Parent = corePart;
    heliControlAtt.WorldCFrame = spawnCf;

    local heliVehicle: Vehicle = modVehicles.new("LynxHelicopter");

    local heliModel: Model = heliVehicle.Model;
    local heliRoot: BasePart = heliModel.PrimaryPart :: BasePart;

    heliRoot.Anchored = true;

    heliModel.Parent = workspace.Environment.Vehicles;
	heliVehicle:SetCFrame(spawnCf);
    heliModel.ModelStreamingMode = Enum.ModelStreamingMode.Persistent;

    function heliVehicle.BindStepped(vehicle: Vehicle, timeTotal: number, timeDelta: number)
        heliModel:PivotTo(CFrame.new(heliControlAtt.WorldPosition, heliRoot.CFrame.LookVector));
    end
    
    local FLYIN_STAGES = {
        [1] = {
            CurPosition = spawnCf.Position;
            NexPosition = stage2Cf.Position;
            Speed = 60;
        };
        [2] = {
            CurPosition = stage2Cf.Position;
            NexPosition = descendCf.Position;
            Speed = 60;
        };
        [3] = {
            CurPosition = descendCf.Position;
            NexPosition = lzCf.Position;
            Speed = 15;
        };
    }

    local tAU = 0;
    local tl = tick();
    local function flyinComplete()
        Debugger:Warn(`Fly in complete in {tick()-tl}s`);
    end

    local stage = 1;
    local function playStage(n)
        local stageDict = FLYIN_STAGES[n];
        if stageDict == nil then
            flyinComplete();
            return;
        end;
        
        local distance = (stageDict.NexPosition-stageDict.CurPosition).Magnitude;
        local travelTweenInfo = TweenInfo.new(distance/stageDict.Speed, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut);

        tAU = tAU + travelTweenInfo.Time;

        local travelTween: Tween = TweenService:Create(heliControlAtt, travelTweenInfo, {
            WorldPosition = stageDict.NexPosition;
        });
        travelTween.Completed:Connect(function(playbackState: Enum.PlaybackState)
            if playbackState ~= Enum.PlaybackState.Completed then return end;
            stage = stage+1;
            playStage(stage);
        end);
        travelTween:Play();
    end

    playStage(stage);
end

return ExfilSystem;