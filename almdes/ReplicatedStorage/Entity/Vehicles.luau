local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local modVehiclesLibrary = shared.require(game.ReplicatedStorage.Library.VehiclesLibrary);
local modGarbageHandler = shared.require(game.ReplicatedStorage.Library.GarbageHandler);
local modPropertiesVariable = shared.require(game.ReplicatedStorage.Library.PropertiesVariable);
local modDestructibles = shared.require(game.ReplicatedStorage.Entity.Destructibles);
local modAudio = shared.require(game.ReplicatedStorage.Library.Audio);

if RunService:IsServer() then
    prefabStorage = game.ServerStorage.Prefabs;
end

local Vehicles = {};
Vehicles.ClassName = "Vehicle";
Vehicles.IdCount = 0;
--==
function Vehicles.onRequire()

end

function Vehicles.createVehicles()
    local new = Instance.new("Configuration");
    new.Name = `Vehicles`;
    new:AddTag("Vehicles");
    return new;
end

-- MARK: __index
function Vehicles:__index(k)
    local v = rawget(self, k);
    if v ~= nil then return v end;

    if k == "HealthComp" then
        return rawget(self, "Destructible").HealthComp;
    end

    local package = rawget(self, "Package");
    if package[k] ~= nil then
        return package[k];
    end

    return Vehicles[k];
end

-- MARK: new
function Vehicles.new(id)
    local vehiclePackage = modVehiclesLibrary:Find(id);
    Vehicles.IdCount = Vehicles.IdCount +1;

    local vehiclePrefab = prefabStorage.Vehicles:WaitForChild(vehiclePackage.PrefabName);
    local newModel: Model = vehiclePrefab:Clone();

    local destructibleConfig: Configuration = modDestructibles.createDestructible();
    destructibleConfig.Parent = newModel;

    local vehicleConfig: Configuration = Vehicles.createVehicles();
    vehicleConfig.Parent = newModel;

    local destructibleInstance: DestructibleInstance = modDestructibles.getOrNew(destructibleConfig);

    local animator: Animator = newModel:WaitForChild("AnimationController"):WaitForChild("Animator") :: Animator; 

    local self = {
        Model = newModel;
        Package = vehiclePackage;
        Destructible = destructibleInstance;
        Config = vehicleConfig;
        Animator = animator;
        AnimationTracks = {};

        Properties = modPropertiesVariable.new({});
        Garbage = modGarbageHandler.new();

        HealthComp = nil;

        BindStepped = nil;
    };
    setmetatable(self, Vehicles);

    local animationsFolder = vehiclePackage.Script:FindFirstChild("Animations");
    if animationsFolder then
        for _, anim in pairs(animationsFolder:GetChildren()) do
            if not anim:IsA("Animation") then continue end;
            self.AnimationTracks[anim.Name] = animator:LoadAnimation(anim);
        end
    end

    self.Garbage:Tag(RunService.Stepped:Connect(function(timeTotal, timeDelta)
        if self.BindStepped then
            self:BindStepped(timeTotal, timeDelta);
        end
        if self.Package.BindStepped then
            self.Package:BindStepped(timeTotal, timeDelta);
        end
    end))

    if self.Package.BindNew then
        self.Package.BindNew(self);
    end


    return self;
end

function Vehicles:PlaySound(sndName: string, params: anydict?)
    if params == nil then
        params = {};
    end
    if params == nil then return end;

    local snd: Sound = modAudio.Play(sndName, params.Parent or self.Model.PrimaryPart);
    self.Garbage:Tag(snd);
    return snd;
end

function Vehicles:SetCFrame(cf: CFrame)
    self.Model:PivotTo(cf);
end

function Vehicles:ToggleVelocityDamp(v: boolean)
    local primaryPart: BasePart = self.Model.PrimaryPart :: BasePart;
    local velocityDamp: LinearVelocity = primaryPart:FindFirstChild("VelocityDamp") :: LinearVelocity;
    if velocityDamp == nil then return end;

    velocityDamp.Enabled = v;
end

function Vehicles:Destroy()
    self.Garbage:Destruct();
    self.Properties:Destroy();
end

return Vehicles;