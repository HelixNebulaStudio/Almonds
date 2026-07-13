local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local TweenService = game:GetService("TweenService");

local modSyncTime = shared.require(game.ReplicatedStorage.Library.SyncTime);


local TimeDownUI = {};
TimeDownUI.__index = TimeDownUI;
--==

local templateTimer;
local templateTextlabel = Instance.new("TextLabel");
templateTextlabel.AnchorPoint = Vector2.new(0.5, 0);
templateTextlabel.BackgroundTransparency = 1;
templateTextlabel.TextColor3 = Color3.fromRGB(255, 255, 255);
templateTextlabel.Font = Enum.Font.ArimoBold;
templateTextlabel.TextStrokeTransparency = 0.7;
templateTextlabel.RichText = true;
templateTextlabel.TextScaled = true;
templateTextlabel.Size = UDim2.new(0, 1000, 0.15, 0);


function TimeDownUI.new()
    local self = {
        Frame = nil;
        Tweens = {};
    };

    if templateTimer == nil then
        local containFrame = Instance.new("Frame");
        containFrame.Name = "TimeDownFrame";
        containFrame.BackgroundTransparency = 1;
        containFrame.Visible = false;

        local uiAspectRatioConstraint = Instance.new("UIAspectRatioConstraint");
        uiAspectRatioConstraint.Parent = containFrame;

        local bkFrame = Instance.new("Frame");
        bkFrame.Name = "BkFrame";
        bkFrame.AnchorPoint = Vector2.new(0.5, 0.5);
        bkFrame.Position = UDim2.new(0.5, 0, 0.5, 0);
        bkFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 35);
        bkFrame.BackgroundTransparency = 0.3;
        bkFrame.Size = UDim2.new(1, 0, 1, 0);
        bkFrame.Parent = containFrame;

        local uiCorner = Instance.new("UICorner");
        uiCorner.CornerRadius = UDim.new(1, 0);
        uiCorner.Parent = bkFrame;

        local ftFrame = bkFrame:Clone();
        ftFrame.Name = "FtFrame";
        ftFrame.AnchorPoint = Vector2.new(0.5, 0.5);
        ftFrame.Position = UDim2.new(0.5, 0, 0.5, 0);
        ftFrame.BackgroundColor3 = Color3.fromRGB(255, 90, 90);
        ftFrame.Size = UDim2.new(0.3, 0, 0.3, 0);
        ftFrame.BackgroundTransparency = 0.2;
        ftFrame.Parent = containFrame;

        local textLabel = Instance.new("TextLabel");
        textLabel.AnchorPoint = Vector2.new(0.5, 0.5);
        textLabel.Position = UDim2.new(0.5, 0, 0.5, 0);
        textLabel.TextColor3 = Color3.fromRGB(255, 255, 255);
        textLabel.BackgroundTransparency = 1;
        textLabel.Font = Enum.Font.RobotoMono;
        textLabel.FontFace.Bold = true;
        textLabel.Text = "99";
        textLabel.Size = UDim2.new(1, 0, 1, 0);
        textLabel.TextTransparency = 0;
        textLabel.TextScaled = true;
        textLabel.Parent = containFrame;

        local uiPadding = Instance.new("UIPadding");
        uiPadding.PaddingTop = UDim.new(0.2, 0);
        uiPadding.PaddingBottom = UDim.new(0.2, 0);
        uiPadding.PaddingLeft = UDim.new(0.2, 0);
        uiPadding.PaddingRight = UDim.new(0.2, 0);
        uiPadding.Parent = textLabel;


        templateTimer = containFrame;
    end

    local new = templateTimer:Clone();
    self.Frame = new;

    local textLabel = self.Frame:WaitForChild("TextLabel");
    self.TextLabel = textLabel;

    setmetatable(self, TimeDownUI);

    new.Destroying:Connect(function()
        self:Destroy();
    end)

    return self;
end

local TWEENINFO = TweenInfo.new(1, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out, -1, false);
local TWEENINFO2 = TweenInfo.new(1, Enum.EasingStyle.Exponential, Enum.EasingDirection.In, -1, false);

function TimeDownUI:PromptText(text, duration)
    local newText = templateTextlabel:Clone();

    newText.Text = text;
    newText.Position = UDim2.new(0.5, 0, 1.1, 0);
    newText.TextTransparency = 0;
    newText.Parent = self.Frame;

    local dur = duration or 3;
    TweenService:Create(
        newText, 
        TweenInfo.new(dur, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out, 0, false, 1), 
        {
            Position = UDim2.new(0.5, 0, 1.1, 20);
            TextTransparency = 1;
        }
    ):Play();
    Debugger.Expire(newText, dur+2+0.2);
end

function TimeDownUI:Set(packet)
    if packet.EndTime then
        local ftFrame = self.Frame:WaitForChild("FtFrame");
        local textLabel = self.TextLabel;

        local function newTweens()
            ftFrame.Size = UDim2.new(0.3, 0, 0.3, 0);
            ftFrame.BackgroundTransparency = 0.2;
            textLabel.TextTransparency = 0;

            for a=1, #self.Tweens do
                local tween: Tween = self.Tweens[a];
                if tween.PlaybackState == Enum.PlaybackState.Playing then
                    tween:Cancel();
                end
            end
            table.clear(self.Tweens); 
            table.insert(self.Tweens, TweenService:Create(ftFrame, TWEENINFO, {
                Size = UDim2.new(1.4, 0, 1.4, 0);
                BackgroundTransparency = 1;
            }));
            table.insert(self.Tweens, TweenService:Create(textLabel, TWEENINFO2, {
                TextTransparency = 1;
            }));

        end
        newTweens();

        if self.ClockConn then
            self.ClockConn:Disconnect();
            self.ClockConn = nil;
        end
	    self.ClockConn = modSyncTime.GetClock():GetPropertyChangedSignal("Value"):Connect(function()
            local timeLeft = math.ceil(packet.EndTime - workspace:GetServerTimeNow());

            if timeLeft%10 == 0 then
                newTweens();
            end

            if timeLeft <= 0 then
                if self.ClockConn then
                    self.ClockConn:Disconnect();
                    self.ClockConn = nil;
                end
                self.Frame.Visible = false;
                return;
            end
                
            self.Frame.Visible = true;
            textLabel.Text = tostring(timeLeft);

            for _, tween in ipairs(self.Tweens) do
                if tween.PlaybackState == Enum.PlaybackState.Playing then continue end;
                tween:Play();
            end

            if self.BindOnTick then
                self.BindOnTick(self, timeLeft);
            end
        end)
    end

    if packet.Text then
        self:PromptText(packet.Text, packet.TextDuration);
    end
end

function TimeDownUI:Destroy()
    if self.ClockConn then
        self.ClockConn:Disconnect();
        self.ClockConn = nil;
    end
end

return TimeDownUI;