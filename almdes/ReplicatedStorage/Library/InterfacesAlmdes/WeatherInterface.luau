local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local TweenService = game:GetService("TweenService");

local interfacePackage = {
    Type = "Character";
};
--==


function interfacePackage.newInstance(interface: InterfaceInstance)
    local frame = script:WaitForChild("WeatherIndicator"):Clone();
    frame.Parent = interface.ScreenGui;

    local templateNeedle = script:WaitForChild("Needle");
    local templateSmokeParticle = script:WaitForChild("SmokeImageParticle");
    local templateGlareParticle = script:WaitForChild("GlareImageParticle");
    local templateDirtParticle = script:WaitForChild("DirtImageParticle");

    local interfaceElement: InterfaceElement = interface:GetOrDefaultElement("WeatherIndicator", {
        Frame = frame;
        Visible = true;
    });

    interfaceElement.OnChanged:Connect(function(k, v, ov)
        if k == "Visible" then
            frame.Visible = v;
        end
    end)

    local function spawnGlare(alpha)
        local tweenInInfo = TweenInfo.new(3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out);
        local tweenOutInfo = TweenInfo.new(3, Enum.EasingStyle.Quad, Enum.EasingDirection.In);

        local new:ImageLabel = templateGlareParticle:Clone();
        new.ImageTransparency = 1;
        new.Rotation = math.random(1, 360);
        new.Parent = frame;

        local s = math.random(400, 500);
        TweenService:Create(new, TweenInfo.new(tweenInInfo.Time + tweenOutInfo.Time), {
            ImageColor3 = Color3.fromRGB(100, 0, 0);
            Size = UDim2.new(0, s, 0, s);
        }):Play();

        local tween: Tween = TweenService:Create(new, tweenInInfo, {
            ImageTransparency = 0.6;
        });
        tween.Completed:Connect(function(playbackState: Enum.PlaybackState)
            if playbackState ~= Enum.PlaybackState.Completed then return end;
            local tween:Tween = TweenService:Create(new, tweenOutInfo, {
                ImageTransparency = 1;
            })
            tween.Completed:Connect(function()
                new:Destroy();
            end)
            tween:Play();
        end)
        tween:Play();
        Debugger.Expire(new, 7);
    end

    local function spawnSmoke(alpha)
        local tweenInInfo = TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out);
        local tweenOutInfo = TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.In);

        local new:ImageLabel = templateSmokeParticle:Clone();
        new.ImageTransparency = 1;
        new.Rotation = math.random(1, 360);
        new.Size = UDim2.new(0, 60, 0, 60);
        new.Parent = frame;

        local s = math.random(60, 100);
        local d = math.random(180, 210)/100;
        TweenService:Create(new, TweenInfo.new(d), {
            Rotation = new.Rotation + (math.random(1, 2) == 1 and 90 or -90);
            Size = UDim2.new(0, s, 0, s);
        }):Play();

        local tween: Tween = TweenService:Create(new, tweenInInfo, {
            ImageTransparency = 0.1 + (alpha*0.2);
        });
        tween.Completed:Connect(function(playbackState: Enum.PlaybackState)
            if playbackState ~= Enum.PlaybackState.Completed then return end;
            local tween:Tween = TweenService:Create(new, tweenOutInfo, {
                ImageTransparency = 1;
            })
            tween.Completed:Connect(function()
                new:Destroy();
            end)
            tween:Play();
        end)
        tween:Play();
        Debugger.Expire(new, 2);
    end

    local function spawnDirt(alpha)
        local nS = math.random(10, 20);
        local new:ImageLabel = templateDirtParticle:Clone();
        new.ImageTransparency = 0;
        new.Rotation = math.random(1, 360);
        new.Size = UDim2.new(0, nS, 0, nS);
        new.Parent = frame;

        new.Position = UDim2.new(0.5, math.random(-30, 30), 0.5, math.random(-30, 30));
        local tween: Tween = TweenService:Create(new, TweenInfo.new(2.1), {
            Rotation = new.Rotation + (math.random(1, 2) == 1 and 90 or -90);
            Size = UDim2.new(0, 1, 0, 1);
            Position = UDim2.new(0.5, new.Position.X.Offset+math.random(-10, 10), 0.5, new.Position.Y.Offset-100);
        })
        tween.Completed:Connect(function(playbackState: Enum.PlaybackState)
            if playbackState ~= Enum.PlaybackState.Completed then return end;
            new:Destroy();
        end)
        tween:Play();

        Debugger.Expire(new, 2);
    end

    --MARK: RedCrowStorm
    local redStormFrame = frame:WaitForChild("RedCrowStorm");
    local frameStartColor = Color3.fromRGB(90, 90, 90);
    local frameEndColor = Color3.fromRGB(90, 0, 0);
    local redStormNeedles = {};
    local prevProgress = 0;

    interface.Scheduler.OnStepped:Connect(function(tickData: TickData)
        local eventPublicData = shared.WorldCore.WorldEventsData and shared.WorldCore.WorldEventsData.redcrowstorm;
        if eventPublicData then 
            redStormFrame.Visible = true;

            if eventPublicData.State == "End" and #redStormNeedles > 0 then
                local rngGuiObject = redStormNeedles[math.random(1, #redStormNeedles)];
                if rngGuiObject then
                    rngGuiObject:Destroy();
                end
                return;
            end

            local cycleDuration = eventPublicData.CycleDuration;
            local timelapsed = cycleDuration - math.round(workspace:GetAttribute("StormCycleTick")-workspace:GetServerTimeNow());

            if timelapsed <= 10 and #redStormNeedles >0 then
                prevProgress = 0;
                for a=1, #redStormNeedles do
                    redStormNeedles[a]:Destroy();
                end
                redStormFrame.BackgroundColor3 = frameStartColor;
            end

            local safeDuration = (eventPublicData.PeaceDuration + eventPublicData.RaiseDuration);
            local newProgressRatio = math.clamp((timelapsed-10)/safeDuration, 0, 1);
            local progressRatio = math.lerp(prevProgress, newProgressRatio, 0.1);
            prevProgress = progressRatio;

            if timelapsed > 10 then
                local needleCount = math.ceil((progressRatio^2)*45);
                if #redStormNeedles < needleCount then
                    for a=#redStormNeedles, needleCount do
                        local needle: Frame = templateNeedle:Clone();
                        needle.Visible = true;
                        table.insert(redStormNeedles, needle);
                        needle.Rotation = math.random(0, 360);
                        needle.Parent = redStormFrame.Clock;
                    end
                end

                redStormFrame.BackgroundColor3 = frameStartColor:Lerp(frameEndColor, progressRatio);
                
                if progressRatio > math.random(1, 10000)/10000 then
                    if math.random(1, 22) == 1 then
                        spawnGlare(progressRatio);
                    end
                    if math.random(1, 12) == 1 then
                        spawnSmoke(progressRatio);
                    end
                    if math.random(1, 6) == 1 then
                        spawnDirt(progressRatio);
                    end
                end
            end
        else
            redStormFrame.Visible = false;
        end;
    end)

end

return interfacePackage;

