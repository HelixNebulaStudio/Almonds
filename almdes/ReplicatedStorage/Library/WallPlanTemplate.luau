local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local modGlobalVars = shared.require(game.ReplicatedStorage.GlobalVariables);
local modAudio = shared.require(game.ReplicatedStorage.Library.Audio);
local modInteractables = shared.require(game.ReplicatedStorage.Library.Interactables);
local modDestructibles = shared.require(game.ReplicatedStorage.Entity.Destructibles);
local modMath = shared.require(game.ReplicatedStorage.Library.Util.Math);


local BLUE_COLOR = Color3.fromRGB(124, 161, 200);
local RED_COLOR = Color3.fromRGB(200, 124, 124);

local WALL_THICKNESS = 2.01;
local WALL_WIDTH = 11.2;

local DOOR_HEIGHT = 9.8;
local DOOR_WIDTH = 5.9;

local WallPlanTemplate = {};
WallPlanTemplate.__index = WallPlanTemplate;
WallPlanTemplate.ClassName = "WallPlan";

WallPlanTemplate.BuildingCost = {
    Wall = {ItemId="wood"; Amount=5;};
    Doorway = {ItemId="wood"; Amount=5;};
    WallFrame = {ItemId="wood"; Amount=5;};
    WindowFrame = {ItemId="wood"; Amount=5;};
};
--==

function WallPlanTemplate.onRequire()
    gameFoundations = workspace.Environment:WaitForChild("Game"):WaitForChild("Foundations");
    gameAttachments = workspace.Interactables:WaitForChild("StructureAttachments");
	wallTemplate = game.ReplicatedStorage.Prefabs.Buildings:WaitForChild("WallTemplate");

    envRayParams = RaycastParams.new();
    envRayParams.FilterType = Enum.RaycastFilterType.Include;
    envRayParams.IgnoreWater = true;
    envRayParams.FilterDescendantsInstances = {workspace.Environment.Scene};

    foundationRayParams = RaycastParams.new();
    foundationRayParams.FilterType = Enum.RaycastFilterType.Include;
    foundationRayParams.IgnoreWater = true;
    foundationRayParams.FilterDescendantsInstances = {gameFoundations};
end

function WallPlanTemplate:SetType(t)
	self.Type = t;
end

function WallPlanTemplate:SetColor(c)
	for _, obj in pairs(self.Model:GetChildren()) do
		if obj:IsA("BasePart") then
			if c == "red" then
				c = RED_COLOR;
			end
			
			obj.Color = c or BLUE_COLOR;
		end
	end
end

function WallPlanTemplate:SetTransparency(v)
	local ot = {Base=1; L=1; R=1; B=1; T=1;};

	if self.Type == "Wall" then
		ot = {Base=0; L=1; R=1; B=1; T=1;};

	elseif self.Type == "Doorway" then
		ot = {Base=1; L=0; R=0; B=1; T=0;};

	elseif self.Type == "WallFrame" then
		ot = {Base=1; L=0; R=0; B=1; T=0;};

	elseif self.Type == "WindowFrame" then
		ot = {Base=1; L=0; R=0; B=0; T=0;};

	end

	for _, obj in pairs(self.Model:GetChildren()) do
		if obj:IsA("BasePart") then
			obj.Transparency = ot[obj.Name] == 1 and 1 or v;
		end
	end
end

local wallIdCounter = 0;
function WallPlanTemplate:Build(baseId)
	wallIdCounter = wallIdCounter +1;
	
	self.Id = wallIdCounter;
	
	self:Update();
	self:SetTransparency(0);
	
	local baseColor = Color3.fromRGB(132, 114, 93);
	for _, obj in pairs(self.Model:GetChildren()) do
		if obj:IsA("BasePart") then
			obj.Material = Enum.Material.WoodPlanks;
			obj.Color = baseColor;
			
			if obj.Transparency == 1 then
				if obj.Name == "PrimaryPart" then
					obj.CollisionGroup = "RaycastIgnore";
					
				else
					game.Debris:AddItem(obj, 0);
					
				end
				
			else
				obj.CanCollide = true;
				obj.CastShadow = true;
				
			end
		end
	end
	
	self.Model:SetAttribute("WallId", wallIdCounter);
	self.Model:SetAttribute("GridPoint", self.GridPoint);
	
	local attachmentParent = workspace.Interactables;
	if baseId then
		attachmentParent = gameAttachments:FindFirstChild(baseId);
		if attachmentParent == nil then
			attachmentParent = Instance.new("Folder");
			attachmentParent.Name = baseId;
			attachmentParent:SetAttribute("TerritoryGroup", true);
		end
	end

	if self.Type == "Doorway" and self.DoorwayPosition then
		local newAttachPart = script:WaitForChild("doorwayAttachment"):Clone();
		newAttachPart.Name = newAttachPart.Name..wallIdCounter;
		newAttachPart.CFrame = CFrame.new(self.DoorwayPosition) * self.CFrame.Rotation;
		newAttachPart.Parent = attachmentParent;
		self.AttachmentPart = newAttachPart;

	elseif self.Type == "WallFrame" and self.WallFramePosition then
		local newAttachPart = script:WaitForChild("wallframeAttachment"):Clone();
		newAttachPart.Name = newAttachPart.Name..wallIdCounter;
		newAttachPart.CFrame = CFrame.new(self.WallFramePosition) * self.CFrame.Rotation;
		newAttachPart.Parent = attachmentParent;

		self.AttachmentPart = newAttachPart;
		
	elseif self.Type == "WindowFrame" and self.WindowPosition then
		local newAttachPart = script:WaitForChild("windowAttachment"):Clone();
		newAttachPart.Name = newAttachPart.Name..wallIdCounter;
		newAttachPart.CFrame = CFrame.new(self.WindowPosition) * self.CFrame.Rotation;
		newAttachPart.Parent = attachmentParent;

		self.AttachmentPart = newAttachPart;
		
	end
	
	modAudio.Play("Repair", self.Base.Position);

	if self.AttachmentPart then
		local newInteractable = modInteractables.createInteractable("DeployableSocket", self.Type);
		newInteractable.Parent = self.AttachmentPart;
	end

    local newDestructible = modDestructibles.createDestructible();
    newDestructible.Parent = self.Model;
	
	return self;
end

function WallPlanTemplate:SetParent(p)
	self.Model.Parent = p;
end

function WallPlanTemplate:Clone(n)
	local newWallClass = WallPlanTemplate.new(self);

	newWallClass.Model = self.Model:Clone();
	newWallClass.Model.Name = n;
	newWallClass.Base = newWallClass.Model:WaitForChild("PrimaryPart");
	
	newWallClass:SetTransparency(0.8);

	return newWallClass;
end

function WallPlanTemplate:ToggleBillboard(v)
	if v == true then
		local newBillboard = script:WaitForChild("DetailsBillboard"):Clone();
		newBillboard.Parent = self.Model;
		newBillboard.Adornee = self.Base;

		self.Billboard = newBillboard;
		
	else
		if self.Billboard then
			game.Debris:AddItem(self.Billboard, 0);
		end
	end
end

function WallPlanTemplate:Destroy()
	game.Debris:AddItem(self.Model, 0);
	self.Model = nil;
	self.Base = nil;
end

function WallPlanTemplate:Update()
	local model = self.Model;
	model:PivotTo(self.CFrame);

	local gridSize = 14;
	local wallCFrame = self.CFrame;
	local rightGridSizeVec = wallCFrame.RightVector*gridSize/2;
	
	local leftWidthRay = workspace:Raycast(wallCFrame.Position, rightGridSizeVec, envRayParams);
	local rightWidthRay = workspace:Raycast(wallCFrame.Position, -rightGridSizeVec, envRayParams);
	
	local leftEndPos = leftWidthRay and leftWidthRay.Position or (wallCFrame.Position + rightGridSizeVec);
	local rightEndPos = rightWidthRay and rightWidthRay.Position or (wallCFrame.Position - rightGridSizeVec);

	local leftWallWidth = (leftEndPos-wallCFrame.Position).Magnitude;
	local rightWallWidth = (rightEndPos-wallCFrame.Position).Magnitude;
	
	--local debugPt = Debugger:Point(leftEndPos);
	--debugPt.Color = Color3.fromRGB(255, 111, 113)
	--game.Debris:AddItem(debugPt, 0.5);
	--local debugPt = Debugger:Point(rightEndPos);
	--debugPt.Color = Color3.fromRGB(103, 255, 113)
	--game.Debris:AddItem(debugPt, 0.5);
	
	local newWallWidth = leftWallWidth+rightWallWidth;
	local newWallCframe = wallCFrame + wallCFrame.RightVector * (leftWallWidth>rightWallWidth and (newWallWidth/2 - rightWallWidth) or -(newWallWidth/2 - leftWallWidth));

	self.Base.Size = Vector3.new(newWallWidth, self.Size.Y, 2);
	self.Base.CFrame = newWallCframe;
	
	if self.Type == "Doorway" then
		model.T.Size = Vector3.new(self.Base.Size.X, (self.Size.Y-DOOR_HEIGHT), WALL_THICKNESS);
		model.T.Position = self.Base.CFrame.Position + Vector3.new(0, self.Base.Size.Y/2 - (model.T.Size.Y/2), 0);

		local sideWallY = self.FloorPoint.Y + DOOR_HEIGHT/2;
		local sideWallHeight = self.Size.Y-model.T.Size.Y;
		
		local innerDir = (self.InnerPoint-leftEndPos).Unit;
		local innerDist = (self.InnerPoint-leftEndPos).Magnitude;
		
		local snappedDist = math.clamp(math.floor( (innerDist-DOOR_WIDTH/2) *5)/5, 1, math.clamp(math.floor((newWallWidth-DOOR_WIDTH-1) *10)/10, 1, 7));
		local snappedInnerPos = leftEndPos + innerDir * snappedDist;
		
		model.L.Size = Vector3.new((leftEndPos-snappedInnerPos).Magnitude, sideWallHeight, WALL_THICKNESS);
		model.L.Position = Vector3.new(leftEndPos.X, sideWallY, leftEndPos.Z) - self.CFrame.RightVector * model.L.Size.X/2;
		
		model.R.Size = Vector3.new((rightEndPos-snappedInnerPos).Magnitude - DOOR_WIDTH, sideWallHeight, WALL_THICKNESS);
		model.R.Position = Vector3.new(rightEndPos.X, sideWallY, rightEndPos.Z) + self.CFrame.RightVector * model.R.Size.X/2;
		
		self.DoorwayPosition = Vector3.new(snappedInnerPos.X, sideWallY, snappedInnerPos.Z) + innerDir * DOOR_WIDTH/2;

		if self.Billboard and self.Billboard.TextLabel then
			self.Billboard.TextLabel.Text = snappedDist;
		end

	elseif self.Type == "WallFrame" then
		model.T.Size = Vector3.new(self.Size.X, (self.Size.Y-DOOR_HEIGHT), WALL_THICKNESS);
		model.T.Position = self.FloorPoint + Vector3.new(0, DOOR_HEIGHT + (model.T.Size.Y/2), 0);

		local sideWallY = self.FloorPoint.Y + DOOR_HEIGHT/2;
		local sideWallHeight = self.Size.Y-model.T.Size.Y;
		local sideWallWidth = (self.Size.X-WALL_WIDTH)/2;

		model.L.Size = Vector3.new(sideWallWidth, sideWallHeight, WALL_THICKNESS);
		model.L.Position = Vector3.new(self.LPoint.X, sideWallY, self.LPoint.Z) + self.CFrame.RightVector * sideWallWidth/2;

		model.R.Size = Vector3.new(sideWallWidth, sideWallHeight, WALL_THICKNESS);
		model.R.Position = Vector3.new(self.RPoint.X, sideWallY, self.RPoint.Z) - self.CFrame.RightVector * sideWallWidth/2;
		
		self.WallFramePosition = Vector3.new(self.FloorPoint.X, sideWallY, self.FloorPoint.Z);

	elseif self.Type == "WindowFrame" then
		local windowHeight = 7;

		local offset = modMath.MapNum(self.MouseYDeg-10, -35, 35, 0, self.Size.Y);
		offset = math.clamp(math.floor(offset*5)/5, 1, math.floor((self.Size.Y-1-windowHeight) *10)/10);

		model.B.Size = Vector3.new(self.Size.X, offset, WALL_THICKNESS);
		model.B.Position = self.FloorPoint + Vector3.new(0, (model.B.Size.Y/2), 0);

		model.T.Size = Vector3.new(self.Size.X, self.Size.Y-model.B.Size.Y-windowHeight, WALL_THICKNESS);
		model.T.Position = self.FloorPoint + Vector3.new(0, self.Size.Y - (model.T.Size.Y/2), 0);

		local sideWallY = self.FloorPoint.Y + model.B.Size.Y + windowHeight/2;
		local sideWallWidth = (self.Size.X-WALL_WIDTH)/2;

		model.L.Size = Vector3.new(sideWallWidth, windowHeight, WALL_THICKNESS);
		model.L.Position = Vector3.new(self.LPoint.X, sideWallY, self.LPoint.Z) + self.CFrame.RightVector * sideWallWidth/2;

		model.R.Size = Vector3.new(sideWallWidth, windowHeight, WALL_THICKNESS);
		model.R.Position = Vector3.new(self.RPoint.X, sideWallY, self.RPoint.Z) - self.CFrame.RightVector * sideWallWidth/2;
		
		self.WindowPosition = Vector3.new(self.FloorPoint.X, sideWallY, self.FloorPoint.Z);
		
		if self.Billboard and self.Billboard.TextLabel then
			self.Billboard.TextLabel.Text = offset;
		end
	end
end

function WallPlanTemplate:AddInteractable()
    if self.Model:FindFirstChild("Interactable") then return end;

    local new = modInteractables.createInteractable("WallPlan", self.Type);
    new.Parent = self.Model;

	local interactable: InteractableInstance = modInteractables.getOrNew(new);
	
	interactable.Values.FoundationPart = self.FoundationPart;
	interactable.Values.GridPoint = self.GridPoint;

	return new;
end

function WallPlanTemplate.new(data)
	local self = {};

	setmetatable(self, WallPlanTemplate);

	if data then
		for k, v in pairs(data) do
			if self[k] == nil then
				self[k] = v;
			end
		end

	else
		self.Model = wallTemplate:Clone();
		self.Base = self.Model:WaitForChild("PrimaryPart");

	end

	return self;
end

return WallPlanTemplate;
