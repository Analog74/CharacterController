-- heavily inspired by x_o's bmx
-- https://devforum.roblox.com/t/giving-out-my-bike-system/132716

local core = script.Parent;
local utility = core:WaitForChild("Utility");
local remotes = core:WaitForChild("Remotes");

local Enum = require(utility:WaitForChild("Enums"));

local initChasis = remotes:WaitForChild("initChasis");

--

local CAMERA = game.Workspace.CurrentCamera;
local TERRAIN = game.Workspace:WaitForChild("Terrain");

local UP = Vector3.new(0, 1, 0);
local FLOOR_CHECK = 10;
local HEIGHT = 3.5;

--

local function lerpNumber(a, b, t)
	return (1-t)*a + t*b;
end

local function initAttachments(self)
	local worldAttach = Instance.new("Attachment");
	worldAttach.Name = "diveAttachment"
	worldAttach.Parent = TERRAIN;
	
	local alignPosition = Instance.new("AlignPosition");
	alignPosition.RigidityEnabled = true;
	alignPosition.Enabled = false;
	alignPosition.Attachment0 = self.rootAttach;
	alignPosition.Attachment1 = worldAttach;
	alignPosition.Parent = self.chasis;
	
	local alignOrientation = Instance.new("AlignOrientation");
	alignOrientation.RigidityEnabled = true;
	alignOrientation.Enabled = false;
	alignOrientation.Attachment0 = self.rootAttach;
	alignOrientation.Attachment1 = worldAttach;
	alignOrientation.Parent = self.chasis;
	
	self.humanoid.Died:Connect(function() worldAttach:Destroy(); end);
	
	return worldAttach, alignPosition, alignOrientation;
end

--

local physBall = {};
local physBall_mt = {__index = physBall};

function physBall.new(player)
	local self = {};
	
	self.control = require(player.PlayerScripts:WaitForChild("PlayerModule")):GetControls();
	
	self.character = player.Character;
	self.humanoid = self.character:WaitForChild("Humanoid");
	self.hrp = self.character:WaitForChild("HumanoidRootPart");
	self.rootAttach = self.hrp:WaitForChild("RootRigAttachment");
	
	self.chasis = initChasis:InvokeServer(self.humanoid);
	self.force = self.chasis:WaitForChild("VectorForce");
	
	self.chasis.Anchored = true;
	
	local wAttach, alignPos, alignOri = initAttachments(self);
	
	self._mass = self.chasis:GetMass();
	self._worldAttach = wAttach;
	self._alignPosition = alignPos;
	self._alignOrientation = alignOri;
	
	--
	
	self.isActive = false;
	self.isGrounded = false;
	self.floorMaterial = Enum.Material.Air;
	
	self._floorNormal = Vector3.new(0, 1, 0);
	self._targetVelocity = Vector3.new(0, 0, 0);
	self._orientation = CFrame.new();
	self._mode = Enum.PhysBallType.Default;
	
	-- tuning
	
	self.acceleration = 2;
	self.speed = 50;
	self.jumpPower = 55;
	
	return setmetatable(self, physBall_mt);
end

--

function physBall:setActive(bool, mode)
	self.chasis.Parent = bool and self.character or nil;
	self.chasis.Anchored = not bool;
	self.chasis.CFrame = self.hrp.CFrame;
	self.chasis.Velocity = Vector3.new();
	
	self.hrp.Velocity = Vector3.new();

	self._alignPosition.Enabled = bool;
	self._alignOrientation.Enabled = bool;
	
	self._orientation = self.hrp.CFrame - self.hrp.CFrame.p;
	
	self._mode = mode or Enum.PhysBallType.Default;
	self.isActive = bool;
end

function physBall:jump()
	if not (self.isJumpActive and self.isGrounded) then
		return;
	end
	
	if (self.mode == Enum.PhysBallType.Default) then
		self.chasis.Velocity = self.chasis.Velocity + self.floorNormal*self.jumpPower;
	end
end

function physBall:update(dt)
	if (not self.isActive) then
		return;
	end
	
	local ray = Ray.new(self.chasis.Position, -FLOOR_CHECK*self._floorNormal);
	local hit, pos, normal, material = game.Workspace:FindPartOnRay(ray, self.character);
	local floorDist = (pos - self.chasis.Position).magnitude;
	
	self.isGrounded = floorDist <= HEIGHT;
	self._floorMaterial = floorDist <= self.humanoid.HipHeight and material or Enum.Material.Air;
	self._floorNormal = hit and (self.isGrounded and normal or self._floorNormal:Lerp(normal, math.min(dt*5, 1)))
							or self._floorNormal:Lerp(Vector3.new(0, 1, 0), math.min(dt, 1));
	
	-- floor cframe
	
	local lookVector = (CAMERA.CFrame.lookVector * Vector3.new(1, 0, 1)).unit;
	local floorCFrame = CFrame.new(Vector3.new(0, 0, 0), lookVector);
	local localFloor = floorCFrame:vectorToObjectSpace(self._floorNormal);
	
	local x, y = math.atan2(-localFloor.X, localFloor.Y), math.atan2(localFloor.Z, localFloor.Y);
	local cfA = CFrame.Angles(y, 0, 0) * CFrame.Angles(0, 0, x);
	local cfB = CFrame.Angles(0, 0, x) * CFrame.Angles(y, 0, 0);
	
	floorCFrame	= floorCFrame * cfA:Lerp(cfB, 0.5);
	
	-- handle modes
	
	local speed = 0;
	local input = self.control:GetMoveVector();
	local grounded = self.isGrounded;
	
	local offset = Vector3.new(0, 0.6, 0);
	local velocity = self.chasis.Velocity;
	local dot = UP:Dot(self._floorNormal);
	
	if (self._mode == Enum.PhysBallType.Default) then
		speed = self.speed;
		input = input:Dot(input) > 0 and input.unit or input;
	elseif (self._mode == Enum.PhysBallType.Dive) then
		local velMag = math.min(self.speed, self.chasis.Velocity.magnitude);
		speed = (dot < 1 or not self.isGrounded) and velMag or velMag*0.1;
		input = input:Dot(input) > 0 and input.unit or Vector3.new(0, 0, -1);
		grounded = velocity.magnitude > 0 and not (velocity.unit:Dot(UP) < -0.8);
	end
	
	-- set values
	
	self._orientation = velocity.magnitude > 1 and self._orientation:lerp(CFrame.new(Vector3.new(), velocity), math.min(dt*10, 1)) or self._orientation;
	self._targetVelocity = floorCFrame:vectorToWorldSpace(input * speed);
	self.force.Force = grounded and (self._targetVelocity - velocity) * self._mass * self.acceleration or Vector3.new(0, 0, 0);
	
	local cf = CFrame.new(self.chasis.CFrame.p + offset) * self._orientation;
	self.hrp.CFrame = cf;
	self._worldAttach.CFrame = cf; -- need this so replication happens
	
	-- w/o this the ball physics can go crazy for a split second b4 we disable
	if (self._floorMaterial == Enum.Material.Water) then
		self.chasis.Anchored = true;
	end
end

--

return physBall;