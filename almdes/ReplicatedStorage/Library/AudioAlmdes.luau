local modAudio = shared.require(game.ReplicatedStorage.Library.Audio);

local function loadSound(snd: Sound)
    if not snd:IsA("Sound") then return end;
    
    snd.Parent = modAudio.ServerAudio;
end

function modAudio.onRequire()
    task.spawn(function()
        local serverAudio = script:WaitForChild("ServerAudio");
        for _, sound in pairs(script:WaitForChild("ServerAudio"):GetChildren()) do
            loadSound(sound);
        end
        serverAudio.ChildAdded:Connect(loadSound);
    end)
end

return modAudio;