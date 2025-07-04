local core = script.Parent;
local utility = core:WaitForChild("Utility");
local animations = core:WaitForChild("Animations");

local Enum = require(utility:WaitForChild("Enums"));
local spring = require(utility:WaitForChild("Spring"));
local lookAt = require(core:WaitForChild("LookAt"));
local physBall = require(core:WaitForChild("PhysBall"));
local particles = require(core:WaitForChild("Particles"));
local humanoidControl = require(core:WaitForChild("HumanoidControl"));

--

local CAMERA = game.Workspace.CurrentCamera;
local TERRAIN = game.Workspace:WaitForChild("Terrain");

local DEBOUNCE_TIME = 0.1;
local MIN_VEL = 4;

local UP = Vector3.new(0, 1, 0);

local JUMP_LANDED = {
	[Enum.HumanoidStateType.Landed] = true;
	[Enum.HumanoidStateType.Swimming] = true;
	[Enum.HumanoidStateType.Running] = true;
	[Enum.HumanoidStateType.RunningNoPhysics] = true;
}

local JUMP_DEBOUNCE = {
	[Enum.HumanoidStateType.Freefall] = true;
	[Enum.HumanoidStateType.Flying] = true;
}

local NO_STANCE_CHANGE = {
	[Enum.HumanoidStateType.Swimming] = true;
	[Enum.HumanoidStateType.Climbing] = true;
}

--

local function reflect(v, normal)
	return -2*v:Dot(normal)*normal + v;
end

local function deltaAngle(a, b)
	local A, B = (math.deg(a) + 360)%360, (math.deg(b) + 360)%360;
	
	local d = math.abs(B - A);
	local r = d > 180 and 360 - d or d;
	
	local ab = A - B;
	local sign = ((ab >= 0 and ab <= 180) or (ab <= -180 and ab >= -360)) and 1 or -1;

	return math.rad(r*sign);
end

local function onStateChange(old, new, self)
	if (JUMP_LANDED[new]) then
		self._canJump = true;
		self._prevFlip = true;
		self._jumpCount = 0;
		
		self._canSprint = true;
		self._canDive = true;
		self._diveCount = 0;

		self._lastWall = nil;
		
		self:cancelHighJump();
		self:cancelLongJump();
		
		self:setCrouch(not NO_STANCE_CHANGE[new] and self._crouch or false);
	elseif (JUMP_DEBOUNCE[new]) then
		wait(DEBOUNCE_TIME);
		self._canJump = true;
		self._canDive = true;
	end
end

--

local moveSet = {};
local moveSet_mt = {__index = moveSet};

function moveSet.new(player)
	local self = {};
	
	self.lookAt = lookAt.new(player.Character);
	self.physBall = physBall.new(player);
	self.particles = particles.new(player);
	self.humanControl = humanoidControl.new(player);
	
	self.character = player.Character;
	self.hrp = self.character:WaitForChild("HumanoidRootPart");
	self.humanoid = self.character:WaitForChild("Humanoid");
	self.root = self.character:WaitForChild("LowerTorso"):WaitForChild("Root");
	self.waist = self.character:WaitForChild("UpperTorso"):WaitForChild("Waist");
	
	
	--Sprint
	self._canSprint = true
	self.standSpeed = 100
	
	
	-- jump
	
	self._canJump = true;
	self._prevFlip = true;
	self._jumpCount = 0;
	
	self.isJumpActive = true;	
	self.jumpPower = 74;
	self.maxJumps = 4;
	
	-- high jump
	
	self._isHighJumping = false;
	self._canHighJump = true;
	
	self.isHighJumpActive = true;
	self.highJumpPower = 100;
	
	-- long jump
	
	self._isLongJumping = false;
	self._canLongJump = true;
	
	self.isLongJumpActive = true;
	self.longJumpPower = 175;
	self.longJumpSpeed = 100;
	self.longJumpDelay = 0;
	
	-- wall jump
	
	self._isWallJumping = false;
	self._canWallJump = true;
	self._lastWall = nil;
	self._totalWallJumpCount = 0;
	
	self.isWallJumpActive = true;
	
	-- dive
	
	self._isDiving = false;
	self._canDive = true;
	self._diveCount = 0;
	
	self.isDiveActive = true;
	self.maxDives = 1;
	self.diveJumpPower = 30;
	self.diveSpeed = 60;
	
	-- slow fall
	
	self._isSlowFalling = false;
	
	-- stance
	
	self.isLookingAt = true;
	
	self._crouch = false;
	self._isCrouching = false;
	
	self._animate = self.character:WaitForChild("Animate");
	self._animStance = self._animate:WaitForChild("Stance");
	
	-- tilting
	
	self._rootC0 = self.root.C0;
	self._waistC0 = self.waist.C0;
	self._tiltSpring = spring.new(5, 5, 5, 0.5, 1, 1E-4);
	self._isTilting = false;
	self._canTilt = true;
	
	self.isTiltingActive = true;
	self.maxTiltAngle = math.rad(5);
	
	-- speed
	
	self.standSpeed = 40;
	self.crouchSpeed = 5;
	self.airSpeed = 55;
	self.swimSpeed = 60;
	
	-- timers
	
	self._fallTimer = 0;
	self._outOfWaterTimer = 0;
	
	-- animations
	
	self.rollJumpAnim = self.humanoid:LoadAnimation(animations:WaitForChild("RollJump"));
	self.diveAnim = self.humanoid:LoadAnimation(animations:WaitForChild("Dive"));
	self.flipAnim = self.humanoid:LoadAnimation(animations:WaitForChild("Flip"));
	self.longJumpAnim = self.humanoid:LoadAnimation(animations:WaitForChild("LongJump"));
	self.spinAnim = self.humanoid:LoadAnimation(animations:WaitForChild("Spin"));
	
	self.currentAnim = self.rollJumpAnim;
	
	--
	
	self.humanoid.StateChanged:Connect(function(old, new) onStateChange(old, new, self); end);
	
	return setmetatable(self, moveSet_mt);
end

--

function moveSet:isAlive()
	return (self.humanoid:GetState() ~= Enum.HumanoidStateType.Dead);
end

function moveSet:isSwimming()
	return (self.humanoid:GetState() == Enum.HumanoidStateType.Swimming);
end

function moveSet:inAir()
	return (self.humanoid.FloorMaterial == Enum.Material.Air) and not self:isSwimming();
end

function moveSet:isFalling()
	return self.hrp.Velocity.y < 0 and not self._isLongJumping and self:inAir();
end

function moveSet:isMoving()
	if (self.physBall.isActive) then
		return self.physBall.chasis.Velocity.magnitude > MIN_VEL;
	else
		local moveSq = self.humanoid.MoveDirection:Dot(self.humanoid.MoveDirection);
		return moveSq > 0 and self.hrp.Velocity.magnitude > MIN_VEL;
	end
end

function moveSet:isCrouching()
	return self._isCrouching;
end

--

function moveSet:jump(flip)
	if not (self.isJumpActive and self:isAlive() and self._canJump and (self._jumpCount < self.maxJumps or self._isDiving)) then
		return false;
	end
	
	if (self._isDiving) then
		self:cancelDive();
		flip = true;
	end
	
	self._canJump = false;
	self._prevFlip = flip;
	self._jumpCount = self._jumpCount + 1;
	
	self.humanoid.JumpPower = self.jumpPower;
	self.humanoid:ChangeState(Enum.HumanoidStateType.Jumping);
	
	self.currentAnim:Stop();
	if (flip) then
		self.currentAnim = self.rollJumpAnim;
		self.currentAnim:Play(nil, nil, 2.5);
	end
	
	return true;
end



--Sprint
function moveSet:sprintHold ()
	self.standspeed = 100
end

function moveSet:highJump()
	if not (self.isHighJumpActive and self._canHighJump and self:isAlive() and not self:inAir()) then
		return false;
	end

	self._isHighJumping = true;	
	self._canHighJump = false;
	
	self.humanoid.JumpPower = self.highJumpPower;
	self.humanoid:ChangeState(Enum.HumanoidStateType.Jumping);
	
	self.currentAnim:Stop();
	self.currentAnim = self.flipAnim;
	self.currentAnim:Play(0.4, nil, 1);
	
	return true;
end

function moveSet:longJump()
	if not (self.isLongJumpActive and self._canLongJump and self:isAlive() and not self:inAir()) then
		return false;
	end
	
	self._isLongJumping = true;
	self._canLongJump = false;
	
	self.humanoid.JumpPower = 0;
	self.humanoid:ChangeState(Enum.HumanoidStateType.Jumping); -- unless the character is jumping we can't set its velocity
	
	local hrpCF = self.hrp.CFrame;
	local ray = Ray.new(hrpCF.p, -5*hrpCF.upVector);
	local hit, pos, normal = game.Workspace:FindPartOnRay(ray, self.character);
	normal = normal:Dot(normal) > 0 and normal or UP;
	
	self.hrp.Velocity = self.longJumpSpeed*(normal:Cross(hrpCF.lookVector):Cross(normal)).unit + self.longJumpPower*normal;
	
	self.currentAnim:Stop();
	self.currentAnim = self.longJumpAnim;
	self.currentAnim:Play(0.2, nil, 1);
	
	return true;
end

function moveSet:wallJump()
	local hrpCF = self.hrp.CFrame;
	local ray = Ray.new(hrpCF * CFrame.new(0, self.hrp.Size.y/2, 0).Position, 4*hrpCF.lookVector);
	local hit, pos, normal, material = game.Workspace:FindPartOnRay(ray, self.character);
	
	if not (self.isWallJumpActive and self._canWallJump and self:inAir() and hit and (not self._lastWall or self._lastWall:Dot(normal) < 0)) then
		return false;
	end
	
	self._isWallJumping = true;
	self._canWallJump = false;
	self._lastWall = normal;
	self._totalWallJumpCount = self._totalWallJumpCount + 1;
	
	self._jumpCount = 0;
	self:jump(false);
	
	local move = self.humanoid.MoveDirection;
	move = (move:Dot(move) > 0 and move:Dot(normal) < 0) and move or hrpCF.lookVector;
	self.humanControl:setMode(Enum.HumanoidControlType.Locked, reflect(move, normal));
	
	local count = self._totalWallJumpCount;
	delay(0.2, function()
		if (self._totalWallJumpCount == count) then
			self._isWallJumping = false;
			self._canWallJump = true;
			self.humanControl:setMode(Enum.HumanoidControlType.Default);
		end
	end)
	
	return true;
end

function moveSet:dive()
	if not (self.isDiveActive and self._canDive and not self._isDiving and self._diveCount < self.maxDives and self:isAlive() and self:inAir() and not NO_STANCE_CHANGE[self.humanoid:GetState()]) then
		return false;
	end
	
	self._isDiving = true;
	self._canDive = false;
	self._diveCount = self._diveCount + 1;
	
	self.physBall:setActive(true, Enum.PhysBallType.Dive);
	self.physBall.chasis.Velocity = self.hrp.CFrame:vectorToWorldSpace(Vector3.new(0, self.diveJumpPower, -100));
	
	self.currentAnim:Stop();
	self.currentAnim = self.diveAnim;
	self.currentAnim:Play(0.4, nil, 3);
	
	self.particles:airPuff();
	
	return true;
end

--

function moveSet:cancelHighJump()
	if (self._isHighJumping) then
		self._isHighJumping = false;
		self._canHighJump = true;
		if (self.currentAnim == self.flipAnim) then
			self.currentAnim:Stop();
		end
	end
end

function moveSet:cancelLongJump()
	if (self._isLongJumping) then
		self._isLongJumping = false;
		self._canLongJump = true;
		if (self.currentAnim == self.longJumpAnim) then
			self.currentAnim:Stop();
		end
	end
end

function moveSet:cancelDive()
	if (self._isDiving) then
		local vel = self.physBall.chasis.Velocity;
		self._isDiving = false;
		self.physBall:setActive(false);
		self.currentAnim:Stop();
		self.hrp.Velocity = vel;
	end
end

--

function moveSet:onJumpRequest()
	local isCrouching = self._isCrouching;
	local isMoving = self:isMoving();
	
	local canWallJump = not self._isHighJumping and not self._isDiving and self._outOfWaterTimer > 0.2;
	local canCrouchJump = isCrouching and not self._isDiving and not self:inAir();
	
	local wallJump = canWallJump and self:wallJump();
	local jump = not wallJump and not isCrouching and self:jump(not self._prevFlip);
	local didJump = wallJump or jump;
	
	local longJump = not didJump and canCrouchJump and isMoving and self:longJump();
	local highJump = not didJump and canCrouchJump and not isMoving and self:highJump();
	
	if not (didJump or longJump or highJump) then
		self.humanoid.JumpPower = 0;
	end
end

function moveSet:setCrouch(bool)
	if (not self:inAir() and self._isCrouching ~= bool) then
		self._animStance.Value = bool and "crouch" or "";
		self._isCrouching = bool;
	end
	self._crouch = bool;
end

function moveSet:setSlowFall(bool)
	self._isSlowFalling = bool;
end

--

function moveSet:slowFall(dt)
	local vel = self.hrp.Velocity;
	if (self._isSlowFalling and self._fallTimer > 0.3 and vel.y < 0) then
		self.hrp.Velocity = (vel * Vector3.new(1, 0, 1)) + Vector3.new(0, -20, 0);	
		if (self.currentAnim ~= self.spinAnim) then
			self.currentAnim:Stop();
			self.currentAnim = self.spinAnim;
			self.currentAnim:Play(0.1, nil, 3);
		end
	elseif (self.currentAnim == self.spinAnim) then
		self.currentAnim:Stop();
		self.currentAnim = self.rollJumpAnim;
	end
end

function moveSet:tiltToMovement(dt)
	local worldMove = self.humanControl:getWorldMoveDirection();
	local worldMoveSq = worldMove:Dot(worldMove);
	
	local look = self.hrp.CFrame.lookVector;
	local realTheta = math.atan2(-look.z, look.x);
	local worldMoveTheta = worldMoveSq > 0 and math.atan2(-worldMove.z, worldMove.x) or realTheta;
	
	self._tiltSpring.target = 0;
	self._isTilting = false;
	
	if (self.isTiltingActive and self._canTilt and self.hrp.Velocity.magnitude >= MIN_VEL) then
		local delta = deltaAngle(worldMoveTheta, realTheta);
		self._tiltSpring.target = math.clamp(delta, -self.maxTiltAngle, self.maxTiltAngle);
		self._isTilting = true;
	end
	
	self._tiltSpring:update(1);
	
	local theta = self._tiltSpring.position/4;
	self.root.C0 = self._rootC0 * CFrame.fromEulerAnglesXYZ(0, 0, theta*3);
	self.waist.C0 = self._waistC0 * CFrame.fromEulerAnglesXYZ(0, 0, theta);
end

function moveSet:update(dt)
	self._fallTimer = (self:isFalling() and not self._isDiving) and self._fallTimer + dt or 0;
	self._outOfWaterTimer = not self:isSwimming() and self._outOfWaterTimer + dt or 0;
	
	if (self._isDiving) then
		self.humanoid.WalkSpeed = self.diveSpeed;
	elseif (self._isLongJumping) then
		self.humanoid.WalkSpeed = self.longJumpSpeed;
	elseif (self:inAir()) then
		self.humanoid.WalkSpeed = self.airSpeed;
	elseif (self:isSwimming()) then
		self:setCrouch(false);
		self.humanoid.WalkSpeed = self.swimSpeed;
	else
		self.humanoid.WalkSpeed = self._isCrouching and self.crouchSpeed or self.standSpeed;
	end
	
	self.physBall:update(dt);
	if (self.physBall._floorMaterial == Enum.Material.Water) then
		self:cancelDive();
	end
	
	self.humanoid:Move(self.humanControl:getWorldMoveDirection(), false);
	
	self._canTilt = not NO_STANCE_CHANGE[self.humanoid:GetState()] and self:isMoving();
	
	self:tiltToMovement(dt);
	self:slowFall(dt);
	
	self.lookAt:setActive(self.isLookingAt and not self:isMoving() and not self._isDiving and not NO_STANCE_CHANGE[self.humanoid:GetState()] and not self._isCrouching);
	self.lookAt:calcGoal(self.lookAt:getEyeCF().p + CAMERA.CFrame.lookVector);
	self.lookAt:update(1);
	
	self.particles:setParticleEnabled("airTrail", self:inAir() and ((self._isDiving and not self.physBall.isGrounded) or self._isLongJumping));
	self.particles:setParticleEnabled("floorParticle", (not self:inAir() or self._isDiving and self.physBall.isGrounded) and self:isMoving() and not NO_STANCE_CHANGE[self.humanoid:GetState()]);
end

--

return moveSet