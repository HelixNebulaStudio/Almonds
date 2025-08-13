local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");
local TweenService = game:GetService("TweenService");

local modScheduler = shared.require(game.ReplicatedStorage.Library.Scheduler);
local modVehicles = shared.require(game.ReplicatedStorage.Entity.Vehicles);
local modRemotesManager = shared.require(game.ReplicatedStorage.Library.RemotesManagerAlmdes);

if RunService:IsServer() then
    prefabStorage = game.ServerStorage.Prefabs;
end

local exfilScheduler: Scheduler = modScheduler.new("ExfilSystem", 1/5);
local ExfilSystem = {};
ExfilSystem.__index = ExfilSystem;
ExfilSystem.Scheduler = exfilScheduler;

local remoteMainMenuRemote;
--==

function ExfilSystem.onRequire()
    remoteMainMenuRemote = modRemotesManager:Get("MainMenuRemote");

	shared.modCommandsLibrary.bind{
		["exfil"] = {
			Permission = shared.modCommandsLibrary.PermissionLevel.DevBranch;
			Description = [[Exfil player.
            
            /exfil [reason]
            ]];

			RequiredArgs = 0;
			UsageInfo = "/exfil [args]";
			Function = function(player, args)
                local reason = args[1] or "HeliExfil";

                ExfilSystem:ExfilPlayer(player, reason);

				return true;
			end;
		};
	};
end

function ExfilSystem:ExfilPlayer(player: Player, exfilType: string)
    if player == nil or not game.Players:IsAncestorOf(player) then return end;
    Debugger:Warn(`ExfilPlayer {player.Name}`);

    local playerClass: PlayerClass = shared.modPlayers.get(player);
    
    local playRunSession = playerClass.Properties.PlayRunSession;

    playRunSession:EndRun("Success", exfilType);

    task.spawn(function()
        local rPacket = remoteMainMenuRemote:InvokeClient(player, "endrun", {
            RunSummary = playRunSession:GetSummary();
        });
        Debugger:Warn(`ExfilPlayer {player.Name}`, typeof(rPacket), rPacket);
    end)

    playerClass:Despawn();
end

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
    local enterStage2Cf: CFrame = descendCf * CFrame.Angles(math.rad(-10), 0, 0) * CFrame.new(0, 0, 1500);
    local exitStage2Cf: CFrame = descendCf * CFrame.Angles(math.rad(-10), 0, 0) * CFrame.new(0, 0, 500);

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
    
    local seatOccupants: {[Seat]: Humanoid} = {};

    local playFlyStage = nil;
    local leaveTickDown = nil;

    local tAU = 0;
    local tl = tick();
    local function flyinComplete()
        Debugger:Warn(`Fly in complete in {tick()-tl}s`);

        for _, seat in pairs(heliVehicle.Seats) do
            seat:GetPropertyChangedSignal("Occupant"):Connect(function()
                seatOccupants[seat] = seat.Occupant;
            end)
            seatOccupants[seat] = seat.Occupant;
        end

        local leaveTime = workspace:GetServerTimeNow()+30;
        corePart:SetAttribute("LeaveTime", leaveTime);

        leaveTickDown();

        local openDoorsTrack: AnimationTrack = heliVehicle.AnimationTracks["OpenDoors"];
        openDoorsTrack:Play();
    end

    local function flyoutComplete()
        Debugger:Warn(`Fly out complete in {tick()-tl}s`);
    end

    local FLYOUT_STAGES = {
        [1] = {
            CurPosition = lzCf.Position;
            NexPosition = descendCf.Position;
            Speed = 10;
        };
        [2] = {
            CurPosition = descendCf.Position;
            NexPosition = exitStage2Cf.Position;
            Speed = 35;
        };
        [3] = {
            CurPosition = exitStage2Cf.Position;
            NexPosition = spawnCf.Position;
            Speed = 60;
        };
        FlyComplete = flyoutComplete;
        StageComplete = function(stageDict, n)
            if n == 1 then
                local openDoorsTrack: AnimationTrack = heliVehicle.AnimationTracks["OpenDoors"];
                openDoorsTrack:Stop();

            elseif n == 2 then
                for _, occupant in pairs(seatOccupants) do
                    local character = occupant.Parent;
                    if not character:HasTag("PlayerCharacters") then continue end;
                    local player = game.Players:GetPlayerFromCharacter(character);
                    ExfilSystem:ExfilPlayer(player, "HeliExfil");
                end

            end
        end
    };

    local FLYIN_STAGES = {
        [1] = {
            CurPosition = spawnCf.Position;
            NexPosition = enterStage2Cf.Position;
            Speed = 60;
        };
        [2] = {
            CurPosition = enterStage2Cf.Position;
            NexPosition = descendCf.Position;
            Speed = 60;
        };
        [3] = {
            CurPosition = descendCf.Position;
            NexPosition = lzCf.Position;
            Speed = 15;
        };
        FlyComplete = flyinComplete;
    };

    local stage = 1;
    playFlyStage = function(n, stageTable)
        local stageDict = stageTable[n];
        if stageDict == nil then
            if stageTable.FlyComplete then
                stageTable.FlyComplete();
            end
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

            if stageTable.StageComplete then
                stageTable.StageComplete(stageDict, n);
            end

            stage = stage+1;
            playFlyStage(stage, stageTable);
        end);
        travelTween:Play();
    end

    local flyoutStarted = false;
    leaveTickDown = function()
        local leaveTime = corePart:GetAttribute("LeaveTime");
        local timeRemaining = leaveTime - workspace:GetServerTimeNow();

        if next(seatOccupants) then
            local readyLeaveTime = corePart:GetAttribute("ReadyLeaveTime");
            if readyLeaveTime == nil then
                readyLeaveTime = workspace:GetServerTimeNow()+8;
                corePart:SetAttribute("ReadyLeaveTime", readyLeaveTime);
            end

            timeRemaining = readyLeaveTime - workspace:GetServerTimeNow();
        else
            corePart:SetAttribute("ReadyLeaveTime", nil);
        end
    
        Debugger:Warn(`LeaveTickDown:`, timeRemaining);

        if timeRemaining >= 0 then
            exfilScheduler:ScheduleFunction(leaveTickDown, tick()+1);
            return;
        end

        if flyoutStarted then return end;
        flyoutStarted = true;

        tl = tick();
        Debugger:Warn(`Fly out starts`);
        stage = 1;
        playFlyStage(stage, FLYOUT_STAGES);
    end

    playFlyStage(stage, FLYIN_STAGES);
end

return ExfilSystem;