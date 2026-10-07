local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local CollectionService = game:GetService("CollectionService");

local modScheduler = shared.require(game.ReplicatedStorage.Library.Scheduler);
local modRaycastUtil = shared.require(game.ReplicatedStorage.Library.Util.RaycastUtil);

local spawnerScheduler: Scheduler;

local NpcSpawner = {};

local SPAWN_CONFIG = {
    ["footsolider"] = {
        NpcNames = {"Bandit"};
        PerPlayerCount = NumberRange.new(3, 5);
        RespawnCooldown = 60;
        DespawnRange = 128;
    };
};
local DEFAULT_CONFIG = SPAWN_CONFIG["footsolider"];
--==

local MIN_SPAWN_RANGE = 32;
local FOV_COS = math.cos(math.rad(90));

local activeNpcs: {[NpcClass]: {SpawnId: string, Config: any}} = {};
local cooldownUntil: {[string]: number} = {};

--==

local function getConfigForPlatform(platformPart: BasePart)
    local spawnId = platformPart:GetAttribute("SpawnId");
    if spawnId == nil then
        return DEFAULT_CONFIG, "default";
    end
    local config = SPAWN_CONFIG[spawnId];
    if config == nil then
        return DEFAULT_CONFIG, tostring(spawnId);
    end
    return config, tostring(spawnId);
end

local function getTopSurfaceCFrame(part: BasePart): CFrame
    local padding = 3;
    local halfX = math.max(part.Size.X / 2 - padding, 0);
    local halfZ = math.max(part.Size.Z / 2 - padding, 0);

    local offsetX = halfX > 0 and (math.random() * 2 - 1) * halfX or 0;
    local offsetZ = halfZ > 0 and (math.random() * 2 - 1) * halfZ or 0;

    return part.CFrame * CFrame.new(offsetX, part.Size.Y / 2, offsetZ);
end

local function getNearbyPlayerClasses(position: Vector3, maxRange: number): {PlayerClass}
    local playerClasses = {};

    for _, player in pairs(game.Players:GetPlayers()) do
        local playerClass: PlayerClass = shared.modPlayers.get(player);
        if playerClass == nil or playerClass.Character == nil then continue end;
        if playerClass.HealthComp ~= nil and playerClass.HealthComp.IsDead then continue end;

        local rootPart = playerClass.RootPart;
        if rootPart == nil then continue end;

        local distance = (rootPart.Position - position).Magnitude;
        if distance <= maxRange then
            table.insert(playerClasses, playerClass);
        end
    end

    return playerClasses;
end

local function isInLineOfSight(playerClass: PlayerClass, spawnPos: Vector3): boolean
    local camCFrame: CFrame? = (playerClass :: any).CameraCFrame;
    if camCFrame == nil then return false end;

    local camPos = camCFrame.Position;
    local toSpawn = spawnPos - camPos;
    local distance = toSpawn.Magnitude;
    if distance <= 0 then return true end;

    local dir = toSpawn / distance;
    if camCFrame.LookVector:Dot(dir) > FOV_COS then
        return not modRaycastUtil.isOccluded(camPos, spawnPos + Vector3.yAxis*2);
    end

    return false;
end

--==

function NpcSpawner.onRequire()
    spawnerScheduler = modScheduler.new("NpcSpawner", 1);

    spawnerScheduler.OnStepped:Connect(function(tickData: TickData)
        if tickData.ms1000 ~= true then return end;

        local curTime = os.clock();

        --MARK: Despawn too fars
        for npcClass: NpcClass, info in pairs(activeNpcs) do
            local config = info.Config;

            local character = npcClass.Character;
            if character == nil then
                activeNpcs[npcClass] = nil;
                continue;
            end

            local npcPos = character:GetPivot().Position;
            local nearby = getNearbyPlayerClasses(npcPos, config.DespawnRange);
            if #nearby <= 0 then
                activeNpcs[npcClass] = nil;
                cooldownUntil[info.SpawnId] = curTime + config.RespawnCooldown;

                npcClass:Destroy();
            end
        end

        -- Population
        local countPerConfig: {[string]: number} = {};
        for _, info in pairs(activeNpcs) do
            countPerConfig[info.SpawnId] = (countPerConfig[info.SpawnId] or 0) + 1;
        end


        --MARK: Try Spawn
        local playerCount = #game.Players:GetPlayers();
        if playerCount <= 0 then return end;

        local spawnPlatforms = CollectionService:GetTagged("SpawnPlatform");

        local platformsPerConfig: {[string]: {BasePart}} = {};
        local configPerId: {[string]: any} = {};
        for _, platformPart in pairs(spawnPlatforms) do
            if not platformPart:IsA("BasePart") then continue end;

            local config, configId = getConfigForPlatform(platformPart);

            platformsPerConfig[configId] = platformsPerConfig[configId] or {};
            table.insert(platformsPerConfig[configId], platformPart);

            configPerId[configId] = config;
        end


        for configId, platforms in pairs(platformsPerConfig) do
            local config = configPerId[configId];

            if cooldownUntil[configId] ~= nil and curTime < cooldownUntil[configId] then continue end;

            local targetCount = math.random(
                math.floor(config.PerPlayerCount.Min),
                math.ceil(config.PerPlayerCount.Max)
            ) * playerCount;

            local currentCount = countPerConfig[configId] or 0;
            if currentCount >= targetCount then continue end;

            local candidates: {BasePart} = {};
            for _, platformPart in pairs(platforms) do
                local spawnPos = getTopSurfaceCFrame(platformPart).Position;

                local nearby = getNearbyPlayerClasses(spawnPos, config.DespawnRange);
                if #nearby <= 0 then continue end;

                local minDistance = math.huge;
                for _, playerClass in pairs(nearby) do
                    local rootPart = playerClass.RootPart;
                    if rootPart == nil then continue end;
                    local d = (rootPart.Position - spawnPos).Magnitude;
                    if d < minDistance then minDistance = d; end
                end
                if minDistance <= MIN_SPAWN_RANGE then continue end;

                local visible = false;
                for _, playerClass in pairs(nearby) do
                    if isInLineOfSight(playerClass, spawnPos) then
                        visible = true;
                        break;
                    end
                end
                if visible then continue end;

                table.insert(candidates, platformPart);
            end

            if #candidates <= 0 then continue end;

            local picked = candidates[math.random(1, #candidates)];
            local spawnCFrame = getTopSurfaceCFrame(picked) * CFrame.new(0, 1.5, 0);

            local npcName = config.NpcNames[math.random(1, #config.NpcNames)];
            local npcClass: NpcClass = shared.modNpcs.spawn2{
                Name = npcName;
                CFrame = spawnCFrame;
            };
            if npcClass == nil then continue end;

            activeNpcs[npcClass] = {SpawnId = configId; Config = config;};

            npcClass.HealthComp.OnIsDeadChanged:Connect(function(isDead)
                if not isDead then return end;
                if activeNpcs[npcClass] == nil then return end;

                activeNpcs[npcClass] = nil;
                cooldownUntil[configId] = os.clock() + config.RespawnCooldown;
            end)
        end
    end)
end

return NpcSpawner;