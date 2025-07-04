local core = script.Parent;
local remotes = core:WaitForChild("Remotes");
local particleStorage = core:WaitForChild("ParticleStorage");

local initParticles = remotes:WaitForChild("initParticles");
local setParticleEnabledEvent = remotes:WaitForChild("setParticleEnabled");
local airPuffEvent = remotes:WaitForChild("airPuff");

--

local RUNSERVICE = game:GetService("RunService");

local PART = Instance.new("Part");
PART.Transparency = 1;
PART.CanCollide = false;
PART.Name = "Particle Part";

--

local function initTrail(parent)
	local attach0 = Instance.new("Attachment");
	attach0.Name = "Trail0";
	attach0.CFrame = CFrame.new(0, 0, 0);
	attach0.Parent = parent;
	
	local attach1 = Instance.new("Attachment");
	attach1.Name = "Trail1";
	attach1.CFrame = CFrame.new(0, parent.Size.y/2, 0);
	attach1.Parent = parent;
	
	local trail = particleStorage:WaitForChild("AirTrail"):Clone();
	trail.Name = "AirTrail";
	trail.Attachment0 = attach0;
	trail.Attachment1 = attach1;
	trail.Parent = parent;
	
	return trail;
end

local function initFloorParticle(self)
	local accesory = Instance.new("Accessory"); -- massless
	accesory.Name = "FloorAccessory";
	accesory.Parent = self.character;
	
	local floorPart = PART:Clone();
	floorPart.Name = "FloorParticlePart";
	floorPart.Size = Vector3.new(2, 1, 1);
	floorPart.Parent = accesory;
	
	local weld = Instance.new("Motor6D");
	weld.C0 = CFrame.new(0, -self.humanoid.HipHeight - self.hrp.Size.y/2 + 0.5, 0);
	weld.Part0 = self.hrp;
	weld.Part1 = floorPart;
	weld.Parent = floorPart;
	
	local floorParticle = particleStorage:WaitForChild("FloorParticle"):Clone();
	floorParticle.Name = "FloorParticle";
	floorParticle.Parent = floorPart;
	
	return floorParticle;
end

local function initPuffParticle(self)
	local accesory = Instance.new("Accessory"); -- massless
	accesory.Name = "PuffAccessory";
	accesory.Parent = self.character;
	
	local puffPart = PART:Clone();
	puffPart.Name = "AirPuffPart";
	puffPart.Size = Vector3.new(4, 2, 4);
	puffPart.Anchored = false;
	puffPart.Parent = accesory;
	
	local particle = particleStorage:WaitForChild("AirPuffParticle"):Clone();
	particle.Name = "AirPuffParticle";
	particle.Enabled = false;
	particle.Parent = puffPart;
	
	local weld = Instance.new("Weld");
	weld.C0 = CFrame.new(0, -self.humanoid.HipHeight, 0);
	weld.Part0 = self.upperTorso;
	weld.Part1 = puffPart;
	weld.Parent = puffPart;

	return puffPart;
end


--

local particles = {};
local particles_mt = {__index = particles};

function particles.new(player)
	local self = {};
	
	if (RUNSERVICE:IsClient()) then
		initParticles:InvokeServer();
	end
	
	self.character = player.Character;
	self.humanoid = self.character:WaitForChild("Humanoid");
	self.hrp = self.character:WaitForChild("HumanoidRootPart");
	self.upperTorso = self.character:WaitForChild("UpperTorso");
	
	--
	
	self.airTrail = self.upperTorso:FindFirstChild("AirTrail") or initTrail(self.upperTorso);
	self.floorParticle = self.character:FindFirstChild("FloorParticle", true) or initFloorParticle(self);
	
	self.airPuffPart = self.character:FindFirstChild("AirPuffPart", true) or initPuffParticle(self);
	self.airPuffParticle = self.airPuffPart:WaitForChild("AirPuffParticle");
	
	return setmetatable(self, particles_mt);
end

--

function particles:setParticleEnabled(key, bool)
	if (self[key].Enabled ~= bool) then
		self[key].Enabled = bool;
		if (RUNSERVICE:IsClient()) then
			setParticleEnabledEvent:FireServer(key, bool);
		end
	end
end

function particles:airPuff()
	local puffPart = self.airPuffPart;
	local particle = self.airPuffParticle;
	particle.Enabled = true;
	
	delay(0.3, function()
		particle.Enabled = false;
	end)

	if (RUNSERVICE:IsClient()) then
		airPuffEvent:FireServer();
	end
end

-- 

return particles;