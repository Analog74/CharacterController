local core = game.ReplicatedStorage:WaitForChild("CustomMovement");
local remotes = core:WaitForChild("Remotes");

local particlesClass = require(core:WaitForChild("Particles"));
local initParticles = remotes:WaitForChild("initParticles");
local airPuffEvent = remotes:WaitForChild("airPuff");
local setParticleEnabledEvent = remotes:WaitForChild("setParticleEnabled");

local lookup = {};

function initParticles.OnServerInvoke(player)
	lookup[player] = particlesClass.new(player);
end

setParticleEnabledEvent.OnServerEvent:Connect(function(player, key, bool)
	if (lookup[player]) then
		lookup[player]:setParticleEnabled(key, bool);
	end
end)

airPuffEvent.OnServerEvent:Connect(function(player)
	if (lookup[player]) then
		lookup[player]:airPuff();
	end
end)