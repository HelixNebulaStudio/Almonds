local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");
local TweenService = game:GetService("TweenService");

local localPlayer = game.Players.LocalPlayer;

local modAudio = shared.require(game.ReplicatedStorage.Library.Audio);
local modStatusClass = shared.require(game.ReplicatedStorage.Library.StatusLibrary.StatusClass);
local modRaycastUtil = shared.require(game.ReplicatedStorage.Library.Util.RaycastUtil);
local modClientGuis = shared.require(game.ReplicatedStorage.PlayerScripts.ClientGuis);

local DamageData = shared.require(game.ReplicatedStorage.Data.DamageData);

if RunService:IsClient() then
	modCameraGraphics = shared.require(game.ReplicatedStorage.PlayerScripts.CameraGraphics);

end

local templateScreenEffect, templateAtmosphereParticle;
--==
local statusPackage = {
	Id="RedCrowStorm";
	Icon="rbxassetid://15948741680";
	Name="Red Crow Storm";
	Description="The Red Crow Storm is consuming the atmosphere, get indoor and light a campfire quick!";
	Buff=false;
	Tags = {"DOT";};
};

function statusPackage.onRequire()
	templateScreenEffect = script:WaitForChild("witheringEye");
	templateAtmosphereParticle = script:WaitForChild("WeatherRedCrowStorm3");
end

function statusPackage.BindApply(statusClass: StatusClassInstance)
	statusClass.Values.StormStartTick = workspace:GetServerTimeNow();

	if RunService:IsServer() then return end;
	
	local redCrowEffect: InterfaceElement = modClientGuis.ActiveInterface:GetOrDefaultElement("RedCrowEffect", {
		Frame = templateScreenEffect:Clone();
		Transparency = 0;
	});

	local rootLayer = redCrowEffect.Frame;
	local layer2 = rootLayer:WaitForChild("layer2") :: ImageLabel;

	local tweenInfo = TweenInfo.new(1);
	redCrowEffect.OnChanged:Connect(function(k, v, ov)
		if k == "Transparency" then
			TweenService:Create(rootLayer, tweenInfo, {ImageTransparency=v}):Play();
			TweenService:Create(layer2, tweenInfo, {ImageTransparency=v}):Play();
		end
	end)

	rootLayer.Parent = modClientGuis.ActiveInterface.ScreenGui;

	local atmosphereParticle: ParticleEmitter = modCameraGraphics.CameraParticlePart:FindFirstChild("WeatherRedCrowStorm3");
	if atmosphereParticle == nil then
		atmosphereParticle = templateAtmosphereParticle:Clone();
		atmosphereParticle.Parent = modCameraGraphics.CameraParticlePart;

		atmosphereParticle:GetAttributeChangedSignal("SizeValue"):Connect(function()
			local size = atmosphereParticle:GetAttribute("SizeValue");
			
			local numSeq: NumberSequence = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 0);
				NumberSequenceKeypoint.new(0.5, size);
				NumberSequenceKeypoint.new(1, 0);
			});
			atmosphereParticle.Size = numSeq;
		end)
	end

	statusClass.Values.AtmosphereParticle = atmosphereParticle;
end

function statusPackage.BindExpire(statusClass: StatusClassInstance)
	if RunService:IsServer() then return end;

	local redCrowEffect: InterfaceElement = modClientGuis.ActiveInterface:GetOrDefaultElement("RedCrowEffect");
	if redCrowEffect then
		redCrowEffect.Transparency = 1;
	end;

	local atmosphereParticle = statusClass.Values.AtmosphereParticle;
	if atmosphereParticle then
		atmosphereParticle:Destroy();
	end
end

function statusPackage.BindTickUpdate(statusClass: StatusClassInstance, tickData: TickData)
	local characterClass: CharacterClass = statusClass.StatusOwner;
	if characterClass == nil then return end;

	local stormTimeLapsed = workspace:GetServerTimeNow() - statusClass.Values.StormStartTick;

	if RunService:IsServer() then
		if tickData.ms500 ~= true then return end;

		local redCrowStormEventData = shared.WorldCore.WorldEventsData and shared.WorldCore.WorldEventsData.redcrowstorm;
		if redCrowStormEventData == nil or redCrowStormEventData.State ~= "Active" then
			Debugger:Warn(`RedCrowStorm status expires.`);
			statusClass.IsExpired = true;
			return;
		end

		local rootPart = characterClass.RootPart;
		local isInDoor = modRaycastUtil.GetCeiling(rootPart.CFrame.Position, 64);
		local campfireStatus: StatusClassInstance = characterClass.StatusComp:GetOrDefault("Campfire");
		
		local damage = 2;
		if isInDoor then
			damage = 1;
		end
		if campfireStatus then 
			damage = 0;
		end;
		
		if statusClass.Values.ExposureScale ~= damage then
			statusClass.Values.ExposureScale = damage;
			statusClass:Sync();
		end

		if damage <= 0 then return; end

		local damageScale = 1 * math.max((stormTimeLapsed)/60, 1);
		damage = damage * damageScale;

		local healthComp: HealthComp? = characterClass.HealthComp;
		if healthComp == nil then return end;

		local dmgData = DamageData.new{
			Damage = damage;
			DamageType = "IgnoreArmor";
		};

		healthComp:TakeDamage(dmgData);

		local woundedStatus: StatusClassInstance = characterClass.StatusComp:GetOrDefault("Wounded");
		if woundedStatus and woundedStatus.Values.DiedInRedCrowStorm ~= true then
			woundedStatus.Values.DiedInRedCrowStorm = true;
			woundedStatus.Expires = workspace:GetServerTimeNow() + 15;
			woundedStatus.Duration = 15;
			woundedStatus:Sync();
		end
		
	elseif RunService:IsClient() then
		local explosureScale = statusClass.Values.ExposureScale or 1;

		if statusClass.Values.LastCrowSound == nil or tick() - statusClass.Values.LastCrowSound > 1 then
			statusClass.Values.LastCrowSound = tick();

			if (explosureScale == 2 and math.random(1, 100) == 1)
			or (explosureScale == 1 and math.random(1, 300) == 1) then
				local crowSound = modAudio.Play(`DistanceCrows{math.random(1, 5)}`, workspace);
				crowSound.Name = `MentalCrows`;
				local reverb = Instance.new("ReverbSoundEffect");
				reverb.WetLevel = -math.random(70, 80);
				reverb.DryLevel = -math.random(4, 10);
				reverb.Parent = crowSound;
				crowSound.PlaybackSpeed = math.random(97, 103)/100;
				crowSound.Volume = 0.5;
			end
		end

		local redCrowEffect: InterfaceElement = modClientGuis.ActiveInterface:GetOrDefaultElement("RedCrowEffect");
		if redCrowEffect == nil then return end;

		redCrowEffect.Frame:SetAttribute("Alpha", explosureScale);

		if explosureScale == 2 then
			redCrowEffect.Transparency = 0.65;
		elseif explosureScale == 1 then
			redCrowEffect.Transparency = 0.85;
		else
			redCrowEffect.Transparency = 1;
		end
		
		local atmosphereParticle: ParticleEmitter = statusClass.Values.AtmosphereParticle;
		if atmosphereParticle then
			if explosureScale <= 1 then
				atmosphereParticle.Enabled = false;
			else
				atmosphereParticle.Enabled = true;
			end
			atmosphereParticle:SetAttribute("SizeValue", math.max((stormTimeLapsed)/60, 1)*0.3);
		end
	end;
end

return modStatusClass.new(statusPackage);