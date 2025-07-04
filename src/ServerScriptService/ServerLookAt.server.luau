local core = game.ReplicatedStorage:WaitForChild("CustomMovement");
local remotes = core:WaitForChild("Remotes");

local lookAt = require(core:WaitForChild("LookAt"));
local updateLookAtEvent = remotes:WaitForChild("UpdateLookAt");

local lookAtDict = {};

--

updateLookAtEvent.OnServerEvent:Connect(function(player, goal)
	if (lookAtDict[player]) then
		lookAtDict[player]._spring.target = goal;
	end
end)

--

game:GetService("RunService").Heartbeat:Connect(function(dt)
	for player, look in next, lookAtDict do
		look:update(dt);
	end
end)

game.Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function(character)
		lookAtDict[player] = lookAt.new(character);
	end)
end)
