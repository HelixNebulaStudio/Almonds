local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");
local TweenService = game:GetService("TweenService");

local camera = workspace.CurrentCamera;

local modWeatherService = shared.require(game.ReplicatedStorage.Library.WeatherService);
local modAudio = shared.require(game.ReplicatedStorage.Library.Audio);

local DamageData = shared.require(game.ReplicatedStorage.Data.DamageData);

local eventPackage = {
	Id = "redcrowstorm";
	Name = "Red Crow Storm";
};

local templateRedCrowStormField;
--==
function eventPackage.onRequire()
	templateRedCrowStormField = game.ReplicatedStorage.Prefabs:WaitForChild("Misc"):WaitForChild("redCrowStormField");


end

function eventPackage.newInstance(worldEventHandler: WorldEventInstance)
	Debugger:Warn(`newInstance {eventPackage.Id}`);

	local scheduler: Scheduler = worldEventHandler.Scheduler;
	local properties: PropertiesVariable<{}> = worldEventHandler.Properties;
	local garbageHandler: GarbageHandler = worldEventHandler.Garbage;
	local publicData = worldEventHandler.Public;

    local function OnStateUpdate(state, oldState)
		Debugger:Warn(`{eventPackage.Id} State Update: {state}`);

		publicData.State = state;
        if state == "Idle" then
            scheduler:ScheduleFunction(function()
				if properties.State ~= "Idle" then return end;
                properties.State = "Start";
            end, tick()+480);

			workspace:SetAttribute("StormCycleTick", workspace:GetServerTimeNow() + (60*12));


        elseif state == "Start" then
			scheduler:ScheduleFunction(function()
				if properties.State ~= "Start" then return end;
				properties.State = "Active";
			end, tick()+120);

			scheduler:ScheduleFunction(function()
				local sound: Sound = modAudio.Play("Soundtrack:Invisible Threat", workspace);
				sound.Ended:Once(function()
					sound:Destroy();
				end);
			end, tick()+60);

			modWeatherService:SetWeather{
				Id = "redcrowstorm";
				Priority = 5;
				Expire = 240;
			};
			
			if properties.SndBlizzardWinds then
				properties.SndBlizzardWinds:Destroy();
			end
			local sound: Sound = modAudio.Play("Ambience:BlizzardWinds", workspace);
			sound.Volume = 0;
			sound.Looped = true;
			sound.SoundGroup = game:GetService("SoundService"):FindFirstChild("Ambient");
			sound:AddTag("WeatherSound");
			properties.SndBlizzardWinds = sound;
			TweenService:Create(sound, TweenInfo.new(100), {Volume = 2}):Play();


        elseif state == "Active" then
			scheduler:ScheduleFunction(function()
				if properties.State ~= "Active" then return end;
				properties.State = "End";
			end, tick()+120);

			local function doActiveTick()
				if properties.State ~= "Active" then return end;
				scheduler:ScheduleFunction(doActiveTick, tick()+1);

				for _, player in pairs(game.Players:GetPlayers()) do
					local playerClass: PlayerClass = shared.modPlayers.get(player);
					if playerClass.HealthComp.IsDead then continue end;

					playerClass.StatusComp:Apply("RedCrowStorm", {});
				end

				if math.random(1, 20) ~= 1 then return end;

				local crowSound = modAudio.Play(`DistanceCrows{math.random(1, 5)}`, workspace);
				crowSound.Name = "DistanceCrows";
				local reverb = Instance.new("ReverbSoundEffect");
				reverb.WetLevel = -math.random(70, 80);
				reverb.DryLevel = -math.random(22, 32);
				reverb.Parent = crowSound;
				crowSound.PlaybackSpeed = math.random(97, 103)/100;
				crowSound:AddTag("WeatherSound");
			end
			scheduler:ScheduleFunction(doActiveTick, tick()+1);

			if properties.SndApocalyticDreams then
				properties.SndApocalyticDreams:Destroy();
			end
			local sound: Sound = modAudio.Play("Soundtrack:Apocalyptic Dreams", workspace);
			sound.Volume = 0;
			sound.Looped = true;
			sound.SoundGroup = game:GetService("SoundService"):FindFirstChild("Ambient");
			sound:AddTag("WeatherSound");
			properties.SndApocalyticDreams = sound;
			TweenService:Create(sound, TweenInfo.new(5), {Volume = 0.7}):Play();


        elseif state == "End" then
			scheduler:ScheduleFunction(function()
				if properties.State ~= "End" then return end;
				properties.State = "Idle";
				modWeatherService:ClearWeather("redcrowstorm");
			end, tick()+10);

			if properties.SndBlizzardWinds then
				local tween = TweenService:Create(properties.SndBlizzardWinds, TweenInfo.new(10), {Volume = 0});
				tween.Completed:Connect(function()
					properties.SndBlizzardWinds:Destroy();
					properties.SndBlizzardWinds = nil;
				end);
				tween:Play();
			end
			if properties.SndApocalyticDreams then
				local tween = TweenService:Create(properties.SndApocalyticDreams, TweenInfo.new(10), {Volume = 0});
				tween.Completed:Connect(function()
					properties.SndApocalyticDreams:Destroy();
					properties.SndApocalyticDreams = nil;
				end);
				tween:Play();
			end


        end
    end
	properties.OnChanged:Connect(function(k, v, ov)
		if k == "State" then
			OnStateUpdate(v, ov);
		end
	end)
	properties.State = "Idle";

end

local weatherStartTick, weatherEndTick;
function eventPackage.WeatherClientTick(delta, weatherData)
	local redCrowStormField = camera:FindFirstChild("redCrowStormField");
	if redCrowStormField == nil then
		redCrowStormField = templateRedCrowStormField:Clone();
		redCrowStormField.Name = "redCrowStormField";
		redCrowStormField.Parent = camera;
		redCrowStormField.Transparency = 1;
	end

	local eventPublicData = shared.WorldCore.WorldEventsData and shared.WorldCore.WorldEventsData.redcrowstorm;
	if eventPublicData == nil then return end;

	local eventState = eventPublicData.State;

	if weatherStartTick == nil then
		weatherStartTick = tick();

		weatherData.Atmosphere.Density = 0;
		weatherData.Atmosphere.DensityIndoors = 0;
		weatherData.Atmosphere.Haze = 0;

		TweenService:Create(
			redCrowStormField, 
			TweenInfo.new(60), 
			{
				Transparency = 0.95;
			}
		):Play();
	end
	redCrowStormField.CFrame = CFrame.new(camera.CFrame.Position);

	if eventState == "Start" then
		local progress = math.clamp((tick()-weatherStartTick)/120, 0, 1);
		
		weatherData.Atmosphere.Density = 0.7 * progress;
		weatherData.Atmosphere.DensityIndoors = 0.5 * progress;
		weatherData.Atmosphere.Haze = 3 * progress;

	elseif eventState == "Active" then
		
	elseif eventState == "End" then
		if weatherEndTick == nil then
			weatherEndTick = tick();
		end

		local progress = 1-math.clamp((tick()-weatherEndTick)/10, 0, 1);
		weatherData.Atmosphere.Density = 0.7 * progress;
		weatherData.Atmosphere.DensityIndoors = 0.5 * progress;
		weatherData.Atmosphere.Haze = 3 * progress;
	end
end

function eventPackage.WeatherRemove(weatherData)
	weatherStartTick = nil;
	weatherEndTick = nil;	

	for _, obj in pairs(camera:GetChildren()) do
		if obj.Name ~= "redCrowStormField" then continue end;
		game.Debris:AddItem(obj, 0);
	end
end

return eventPackage;