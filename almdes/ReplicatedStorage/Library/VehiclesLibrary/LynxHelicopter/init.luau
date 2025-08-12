local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local vehiclePackage = {
    Id = "LynxHelicopter";
    PrefabName = "LynxHelicopter";
};

function vehiclePackage.BindNew(vehicle: Vehicle)
    local topRotorTrack: AnimationTrack = vehicle.AnimationTracks["TopRotor"];
    topRotorTrack:Play();

    vehicle:PlaySound("HelicopterCore");
end

function vehiclePackage.BindStepped(vehicle: Vehicle, timeTotal: number, timeDelta: number)

end

return vehiclePackage;