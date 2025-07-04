local core = script.Parent;
local utility = core:WaitForChild("Utility")

local Enum = require(utility:WaitForChild("Enums"));

--

local CAMERA = game.Workspace.CurrentCamera;

--

local humanoidControl = {};
local humanoidControl_mt = {__index = humanoidControl};

function humanoidControl.new(player)
	local self = {};
	
	self.character = player.Character;
	self.humanoid = self.character:WaitForChild("Humanoid");
	self.hrp = self.character:WaitForChild("HumanoidRootPart");
	
	self._lockedMoveVector = self.humanoid.MoveDirection;
	self._forcedMoveVector = self.humanoid.MoveDirection;
	self._mode = Enum.HumanoidControlType.Default;
	
	return setmetatable(self, humanoidControl_mt);
end

--

function humanoidControl:setMode(newMode, moveVec)
	self._mode = newMode;
	if (newMode == Enum.HumanoidControlType.Locked) then
		self._lockedMoveVector = moveVec;
	end
end

function humanoidControl:getWorldMoveDirection(enum)
	local mode = enum or self._mode;
	
	if (mode == Enum.HumanoidControlType.Default) then
		return self.humanoid.MoveDirection;
	elseif (mode == Enum.HumanoidControlType.Locked) then
		return self._lockedMoveVector;
	elseif (mode == Enum.HumanoidControlType.Forced or mode == Enum.HumanoidControlType.ForcedRespectCamera) then
		local worldMove = self.humanoid.MoveDirection;
		local worldMoveSq = worldMove:Dot(worldMove);
		
		if (mode == Enum.HumanoidControlType.ForcedRespectCamera and worldMoveSq == 0) then
			worldMove = (CAMERA.CFrame.lookVector * Vector3.new(1, 0, 1)).unit;
			worldMoveSq = 1;
		end
		
		local look = self.hrp.CFrame.lookVector;
		local realTheta = math.atan2(-look.z, look.x);
		local worldTheta = worldMoveSq > 0 and math.atan2(-worldMove.z, worldMove.x) or realTheta;
		
		self._forcedMoveVector = CFrame.fromEulerAnglesYXZ(0, worldTheta, 0) * Vector3.new(1, 0, 0);
		
		return self._forcedMoveVector;
	end
end

--

return humanoidControl;