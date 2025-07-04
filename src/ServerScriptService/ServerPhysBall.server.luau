local core = game.ReplicatedStorage:WaitForChild("CustomMovement");
local remotes = core:WaitForChild("Remotes");

local initChasis = remotes:WaitForChild("initChasis");

local CHASIS = game:GetService("ServerStorage"):WaitForChild("Chasis");
local COLLISIONKEY = "ChasisPlayer";

local physicsService = game:GetService("PhysicsService");
physicsService:CreateCollisionGroup(COLLISIONKEY);
physicsService:CollisionGroupSetCollidable(COLLISIONKEY, COLLISIONKEY, false);

--

local function setCollisionGroup(children, key)
	for i = 1, #children do
		local child = children[i];
		if (child:IsA("BasePart")) then
			physicsService:SetPartCollisionGroup(child, key);
		end
		setCollisionGroup(child:GetChildren(), key);
	end
end

--

function initChasis.OnServerInvoke(player, humanoid)
	local chasis = CHASIS:Clone();
	chasis.Name = player.Name .. "'s Vehicle";
	chasis.Position = humanoid.RootPart.Position;
	chasis.Parent = player.Character;
	
	chasis:SetNetworkOwner(player);
	
	if (not player:HasAppearanceLoaded()) then
		player.CharacterAppearanceLoaded:Wait();
	end
	
	physicsService:SetPartCollisionGroup(chasis, COLLISIONKEY);
	setCollisionGroup(player.Character:GetChildren(), COLLISIONKEY);
	
	return chasis;
end