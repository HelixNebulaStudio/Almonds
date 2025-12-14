local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local TweenService = game:GetService("TweenService");

local modAudio = shared.require(game.ReplicatedStorage.Library.Audio);

local FLARE_STAGE_HEIGHT = 100;
local FLARE_STAGES = {
    [1]={
        Glare = {
            Brightness = 10;
            Size = 1;
            Squash = 2;
            Transparency = 0.95;
        };
        Halo = {
            Brightness = 1;
            Size = 2;
            Transparency = 0.95;
        };
        Sparks = {
            Brightness = 10;
            Size = NumberSequence.new{
                NumberSequenceKeypoint.new(0, 2, 0.2);
                NumberSequenceKeypoint.new(0.02, 0.5);
                NumberSequenceKeypoint.new(1, 0);
            };
            Speed = NumberRange.new(5);
        };
    };
    [2]={
        Glare = {
            Brightness = 50;
            Size = 20;
            Squash = 2;
            Transparency = NumberSequence.new{
                NumberSequenceKeypoint.new(0, 1);
                NumberSequenceKeypoint.new(0.2, 0.95);
                NumberSequenceKeypoint.new(1, 1);
            };
        };
        Halo = {
            Brightness = 10;
            Size = 40;
            Transparency = 0.98;
        };
        Sparks = {
            Brightness = 100;
            Size = NumberSequence.new{
                NumberSequenceKeypoint.new(0, 7);
                NumberSequenceKeypoint.new(0.03, 3);
                NumberSequenceKeypoint.new(1, 0);
            };
            Speed = NumberRange.new(20);
        };
    };
    [3]={
        Glare = {
            Brightness = 100;
            Size = 50;
            Squash = 2.5;
            Transparency = NumberSequence.new{
                NumberSequenceKeypoint.new(0, 1);
                NumberSequenceKeypoint.new(0.1, 0.96);
                NumberSequenceKeypoint.new(1, 1);
            };
        };
        Halo = {
            Brightness = 100;
            Size = 120;
            Transparency = 0.985;
        };
        Sparks = {
            Brightness = 100;
            Size = NumberSequence.new{
                NumberSequenceKeypoint.new(0, 10);
                NumberSequenceKeypoint.new(0.05, 10);
                NumberSequenceKeypoint.new(0.06, 5);
                NumberSequenceKeypoint.new(0.7, 2.5);
                NumberSequenceKeypoint.new(1, 0);
            };
            Speed = NumberRange.new(40);
        };
    }
};
local TWEENINFO = TweenInfo.new(1, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut);

local FlareParticle = {};
FlareParticle.__index = FlareParticle;
--==

function FlareParticle.new(origin: Vector3)
    local self = {
        Attachment = script:WaitForChild("FlareParticles"):Clone();
        Origin = origin;
    };

    self.Attachment.WorldPosition = origin;

    setmetatable(self, FlareParticle);
    return self;
end

function FlareParticle:Destroy()
    task.delay(5, function()
        Debugger.Expire(self.Attachment, 0);
    end)

    local flareAtt = self.Attachment;

    local glare: ParticleEmitter = flareAtt:FindFirstChild("Glare") :: ParticleEmitter;
    local halo: ParticleEmitter = flareAtt:FindFirstChild("Halo") :: ParticleEmitter;
    local sparks: ParticleEmitter = flareAtt:FindFirstChild("Sparks") :: ParticleEmitter;

    if glare then
        glare.Enabled = false;
    end
    if halo then
        halo.Enabled = false;
    end
    if sparks then
        sparks.Enabled = false;
    end
end

function FlareParticle:SetStage(n, a: number)
    local prevStage = FLARE_STAGES[n-1];
    local newStage = FLARE_STAGES[n];
    if prevStage == nil or newStage == nil then return end;

    local flareAtt = self.Attachment;
    local glare: ParticleEmitter = flareAtt:WaitForChild("Glare") :: ParticleEmitter;
    local halo: ParticleEmitter = flareAtt:WaitForChild("Halo") :: ParticleEmitter;
    local sparks: ParticleEmitter = flareAtt:WaitForChild("Sparks") :: ParticleEmitter;

    glare.Brightness = math.lerp(prevStage.Glare.Brightness, newStage.Glare.Brightness, a);

    local newGlareSize = NumberSequence.new(math.lerp(prevStage.Glare.Size, newStage.Glare.Size, a));
    glare.Size = newGlareSize;

    local newGlareSquash = math.lerp(prevStage.Glare.Squash, newStage.Glare.Squash, a);
    glare.Squash = NumberSequence.new(newGlareSquash);
    glare.Transparency = newStage.Glare.Transparency;


    halo.Brightness = math.lerp(prevStage.Halo.Brightness, newStage.Halo.Brightness, a);

    local newHaloSize = math.lerp(prevStage.Halo.Size, newStage.Halo.Size, a);
    halo.Size = NumberSequence.new(newHaloSize);

    local newHaloTransparency = math.lerp(prevStage.Halo.Transparency, newStage.Halo.Transparency, a);
    halo.Transparency = NumberSequence.new(newHaloTransparency);

    sparks.Brightness = math.lerp(prevStage.Sparks.Brightness, newStage.Sparks.Brightness, a);
    local newSparkSpeed = math.lerp(prevStage.Sparks.Speed.Min, newStage.Sparks.Speed.Min, a)
    sparks.Speed = NumberRange.new(newSparkSpeed);
    sparks.Size = newStage.Sparks.Size;
end

function FlareParticle:Launch()
    local flareAtt = self.Attachment;
    local origin = self.Origin;

    modAudio.Play("FlareLoop", flareAtt);
    modAudio.Play("FlareLaunch", flareAtt);

    local trail: ParticleEmitter = flareAtt:WaitForChild("Trail") :: ParticleEmitter;

    local function topReached()
        trail.Enabled = false;
    end

    local function playStage(n)
        local position = origin + Vector3.new(0, FLARE_STAGE_HEIGHT*(n-1), 0);
        local moveTween: Tween = TweenService:Create(flareAtt, TWEENINFO, {
            WorldPosition = position;
        });

        moveTween.Completed:Connect(function(playbackState: Enum.PlaybackState)
            if playbackState ~= Enum.PlaybackState.Completed then return end;
            n = n+1;
            if n > #FLARE_STAGES then 
                topReached();
                return;
            end;

            playStage(n);
        end);

        moveTween:Play();
        task.spawn(function()
            local fps = 10;
            local frames = TWEENINFO.Time/(1/fps);
            for a=0.2, 1, 1/frames do
                task.wait(1/fps);
                self:SetStage(n, a);
            end
            self:SetStage(n, 1);
        end)
    end
    playStage(2);

    flareAtt.Parent = workspace.Terrain;
    Debugger.Expire(flareAtt, 60);
end

return FlareParticle;