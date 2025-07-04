local SPEED = 10;

local start = script.Parent:WaitForChild("Start");
local finish = script.Parent:WaitForChild("Finish");

local attach0 = Instance.new("Attachment");
attach0.CFrame = CFrame.new();
attach0.Parent = script.Parent;

local attach1 = Instance.new("Attachment");
attach1.CFrame = finish.CFrame;
attach1.Parent = game.Workspace.Terrain;

local pris = Instance.new("PrismaticConstraint");
pris.ActuatorType = Enum.ActuatorType.Motor;
pris.MotorMaxForce = math.huge;
pris.Attachment0 = attach1;
pris.Attachment1 = attach0;
pris.Parent = script.Parent;

local forward = true;
pris.Velocity = SPEED;
attach1.CFrame = finish.CFrame

start.Touched:Connect(function(hit)
	if (hit == script.Parent and not forward) then
		forward = true;
		pris.Velocity = SPEED;
		attach1.CFrame = finish.CFrame
	end
end)

finish.Touched:Connect(function(hit)
	if (hit == script.Parent and forward) then
		forward = false;
		pris.Velocity = -SPEED;
		attach1.CFrame = start.CFrame
	end
end)