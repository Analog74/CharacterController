local core = script.Parent;
local utility = core:WaitForChild("Utility");
local remotes = core:WaitForChild("Remotes");

local spring = require(utility:WaitForChild("Spring"));
local updateLookAtEvent = remotes:WaitForChild("UpdateLookAt");

--

local RUNSERVICE = game:GetService("RunService");

local SERVER_UPDATE = 0.2;
local ZERO = Vector3.new();

local SETTINGS = {
	horizontalRange = math.rad(160);
	verticalRange = math.rad(120);
	maxHorizontalWaist = math.rad(22.5);
	maxHorizontalHead = math.rad(105);
}

--

local lookAt = {};
local lookAt_mt = {__index = lookAt};

function lookAt.new(character)
	local self = {};
	
	self.character = character;
	self.hrp = character:WaitForChild("HumanoidRootPart");
	self.neck = character:WaitForChild("Head"):WaitForChild("Neck");
	self.waist = character:WaitForChild("UpperTorso"):WaitForChild("Waist");
	
	self.isActive = true;
	
	self._eyeOffset = self.hrp.CFrame:inverse() * character:WaitForChild("Head").CFrame;
	self._neckC0 = self.neck.C0;
	self._waistC0 = self.waist.C0;
	
	self._timer = 0;
	self._spring = spring.new(ZERO, ZERO, ZERO, 0.05, 1, 1E-3);
	
	return setmetatable(self, lookAt_mt);
end

--

function lookAt:setActive(bool)
	if (bool ~= self.isActive) then
		self.isActive = bool;
		updateLookAtEvent:FireServer(ZERO);
	end
end

function lookAt:getEyeCF()
	return self.hrp.CFrame * self._eyeOffset;
end

function lookAt:calcGoal(target)
	local goal = ZERO;
	
	local eye = self:getEyeCF():pointToObjectSpace(target).unit;
	local horizontal = -math.atan2(eye.x, -eye.z);
	local vertical = math.asin(eye.y);
	
	if not (math.abs(horizontal) > SETTINGS.horizontalRange or math.abs(vertical) > SETTINGS.verticalRange) then
		local hsign, habs = math.sign(horizontal), math.abs(horizontal);
		local hneck, hwaist = habs*0.5, habs*0.5;
		
		if (hwaist > SETTINGS.maxHorizontalWaist) then
			local remainder = hwaist - SETTINGS.maxHorizontalWaist;
			hwaist = SETTINGS.maxHorizontalWaist;
			hneck = math.clamp(hneck + remainder, 0, SETTINGS.maxHorizontalHead);
		end
		
		goal = Vector3.new(hsign*hneck, hsign*hwaist, vertical);
	end
	
	self._spring.target = goal;
end

function lookAt:update(dt)
	self._spring.target = self.isActive and self._spring.target or ZERO;
	self._spring:update(dt);
	
	local set = self._spring.position;
	self.neck.C0 = self._neckC0 * CFrame.fromEulerAnglesYXZ(set.z*0.5, set.x, 0);
	self.waist.C0 = self._waistC0 * CFrame.fromEulerAnglesYXZ(set.z*0.5, set.y, 0);
	
	self._timer = self._timer + dt;
	if (self.isActive and self._timer >= SERVER_UPDATE and RUNSERVICE:IsClient()) then
		self._timer = 0;
		updateLookAtEvent:FireServer(self._spring.target);
	end
end

--

return lookAt;