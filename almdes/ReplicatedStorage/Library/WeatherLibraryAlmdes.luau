local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==

local modWeatherLibrary = shared.require(game.ReplicatedStorage.Library.WeatherLibrary);
local modEventLibrary = shared.require(game.ReplicatedStorage.Library.EventsLibrary);
--==

function modWeatherLibrary.onRequire()
    for weatherId, weatherLib in pairs(modWeatherLibrary:GetAll()) do
        local eventLib = modEventLibrary:Find(weatherId);
        if eventLib == nil then continue end;

        weatherLib.OnServerTick = eventLib.WeatherServerTick;
        weatherLib.OnClientTick = eventLib.WeatherClientTick;
        weatherLib.BindRemove = eventLib.WeatherRemove;
    end
end

modWeatherLibrary:Add{
    Id = "redcrowstorm";

    CameraEffect = {
        Atmosphere = {
            Color = Color3.fromRGB(122, 0, 0);
            
            Density = 0.7;
            DensityIndoors = 0.5;
            Offset = 1;
            Haze = 3;
        };
        
        SunRaysIntensity = 0;

        ScreenParticles = {
            {Id = "WeatherRedCrowStorm"};
            {Id = "WeatherRedCrowStorm2"};
        };
    };

    WeatherSounds = {};

    SkipDevTest=true;
};

return modWeatherLibrary;