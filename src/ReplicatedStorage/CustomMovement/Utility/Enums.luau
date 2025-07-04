local enums = {}

enums.HumanoidControlType = {
	Default = 1;
	Locked = 2;
	Forced = 3;
	ForcedRespectCamera = 4;
}

enums.PhysBallType = {
	Default = 1;
	Dive = 2;
}

return setmetatable(enums, {__index = Enum});