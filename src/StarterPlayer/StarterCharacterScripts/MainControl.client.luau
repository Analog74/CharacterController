local core = game.ReplicatedStorage:WaitForChild("CustomMovement");
local utility = core:WaitForChild("Utility");

local uisBinds = require(utility:WaitForChild("UserInputBind"));
local moveSet = require(core:WaitForChild("MoveSet")).new(game.Players.LocalPlayer);

--

local function slowFall(actionName, userInputState, input)
	moveSet:setSlowFall(userInputState == Enum.UserInputState.Begin)
	return Enum.ContextActionResult.Pass;
end

local function dive(actionName, userInputState, input)
	if (userInputState == Enum.UserInputState.Begin) then
		moveSet:dive();
	end
	return Enum.ContextActionResult.Pass;
end


local function crouchHold(actionName, userInputState, input)
	moveSet:setCrouch(userInputState == Enum.UserInputState.Begin);
	return Enum.ContextActionResult.Pass;
end

local function crouchToggle(actionName, userInputState, input)
	if (userInputState == Enum.UserInputState.Begin) then
		moveSet:setCrouch(not moveSet:isCrouching());
	end
	return Enum.ContextActionResult.Pass;
end

--

--moveSet.isLookingAt = false;

-- Why not use contextAction service? Doesn't play nicely with controllers

uisBinds:BindToInput("dive", dive, Enum.KeyCode.LeftShift, Enum.KeyCode.ButtonX);
uisBinds:BindToInput("slowFall", slowFall, Enum.KeyCode.Space, Enum.KeyCode.ButtonA);
uisBinds:BindToInput("crouchHold", crouchHold, Enum.KeyCode.ButtonL2, Enum.KeyCode.LeftControl);


uisBinds:BindToInput("crouchToggle", crouchToggle, Enum.KeyCode.LeftControl);

game:GetService("UserInputService").JumpRequest:Connect(function()
	moveSet:onJumpRequest();
end)

game:GetService("RunService"):BindToRenderStep("MoveSet", Enum.RenderPriority.Input.Value, function(dt)
	moveSet:update(dt);
end)