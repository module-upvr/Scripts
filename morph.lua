local Players = game:GetService("Players")
local Player = Players.LocalPlayer
Player.AutoJumpEnabled = false
local MorphSystem = {}

local function clearCharacterAssets(character)
	for _, v in ipairs(character:GetDescendants()) do
		if v:IsA("Accessory") or v:IsA("Decal") or v:IsA("Clothing") or v:IsA("CharacterMesh") or v:IsA("WrapTarget") then
			v:Destroy()
		end
	end
end

local function syncMotor6D(targetCharacter, morphModel)
	for _, morphMotor in ipairs(morphModel:GetDescendants()) do
		if morphMotor:IsA("Motor6D") then
			local parentPart = morphMotor.Parent
			local targetPart = targetCharacter:FindFirstChild(parentPart.Name)
			if targetPart then
				local targetMotor = targetPart:FindFirstChild(morphMotor.Name)
				if targetMotor and targetMotor:IsA("Motor6D") then
					targetMotor.C0 = morphMotor.C0
					targetMotor.C1 = morphMotor.C1
				end
			end
		end
	end
end

local function setupMorphPhysics(morphModel)
	local morphHumanoid = morphModel.Humanoid
morphHumanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	for _, v in ipairs(morphModel:GetDescendants()) do
		if v:IsA("BasePart") then
			v.Massless = true
			v.CanCollide = false
			v.CanTouch = false
			v.CanQuery = false
			v.CustomPhysicalProperties = PhysicalProperties.new(0.0001, 0.0001, 0.0001, 0.0001, 0.0001)
		elseif v:IsA("Motor6D") then
			v.Enabled = false
		end
	end

	if morphModel:FindFirstChild("HumanoidRootPart") then morphModel.HumanoidRootPart:Destroy() end
	if morphModel:FindFirstChild("Animate") then morphModel.Animate:Destroy() end
	
	morphHumanoid.EvaluateStateMachine = false

	local statesToDisable = {
		Enum.HumanoidStateType.FallingDown, Enum.HumanoidStateType.Running,
		Enum.HumanoidStateType.Climbing, Enum.HumanoidStateType.Jumping,
		Enum.HumanoidStateType.Swimming, Enum.HumanoidStateType.Landed,
		Enum.HumanoidStateType.Ragdoll, Enum.HumanoidStateType.GettingUp
	}

	for _, state in ipairs(statesToDisable) do
		morphHumanoid:SetStateEnabled(state, false)
	end

	morphHumanoid:ChangeState(Enum.HumanoidStateType.Physics)
end

function MorphSystem:Morph(username)
	local character = Player.Character or Player.CharacterAdded:Wait()
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end

	username = username or "leewan237"
	local rigType = humanoid.RigType

	local success, userId = pcall(function() return Players:GetUserIdFromNameAsync(username) end)

	local desc = Players:GetHumanoidDescriptionFromUserId(userId)
	local morphModel = Players:CreateHumanoidModelFromDescription(desc, rigType)
	local morphHumanoid = morphModel:FindFirstChildOfClass("Humanoid")

	morphModel.Parent = workspace
	morphModel:PivotTo(character:GetPivot())

	setupMorphPhysics(morphModel)
	
	if rigType == Enum.HumanoidRigType.R15 then
		syncMotor6D(character, morphModel)
	end
	
	clearCharacterAssets(character)

	local limbs = (rigType == Enum.HumanoidRigType.R15) 
		and {"Head", "UpperTorso", "LowerTorso", "LeftUpperArm", "LeftLowerArm", "LeftHand", "RightUpperArm", "RightLowerArm", "RightHand", "LeftUpperLeg", "LeftLowerLeg", "LeftFoot", "RightUpperLeg", "RightLowerLeg", "RightFoot"}
		or {"Head", "Torso", "Left Arm", "Right Arm", "Left Leg", "Right Leg"}

	for _, limbName in ipairs(limbs) do
		local targetLimb = character:FindFirstChild(limbName)
		local morphLimb = morphModel:FindFirstChild(limbName)

		if targetLimb and morphLimb then
			targetLimb.Size = morphLimb.Size
			targetLimb.CanCollide = false 

			local weld = Instance.new("Weld")
			weld.Part0 = targetLimb
			weld.Part1 = morphLimb
			weld.C0, weld.C1 = CFrame.new(), CFrame.new()
			weld.Parent = targetLimb

			targetLimb.Transparency = 1
			targetLimb:GetPropertyChangedSignal("Transparency"):Connect(function() 
				targetLimb.Transparency = 1 
			end)
		end
	end

	local function cleanup() if morphModel then morphModel:Destroy() end end
	humanoid.Died:Connect(function() task.delay(5, cleanup) end)
	Player.CharacterAdded:Connect(cleanup)
end

return MorphSystem