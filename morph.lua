local Players = game:GetService("Players")
local Player = Players.LocalPlayer

local MorphSystem = {}

local function clearCharacterAssets(character)
  for _, v in character:GetDescendants() do
    if v:IsA("Accessory") or v:IsA("Decal") or v:IsA("Clothing") or v:IsA("CharacterMesh") or v:IsA("WrapTarget") then
      v:Destroy()
    end
  end
end

local function syncMotor6D(targetCharacter, morphModel)
  for _, morphMotor in morphModel:GetDescendants() do
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
  morphHumanoid.EvaluateStateMachine = false
  
  for _, state in Enum.HumanoidStateType:GetEnumItems() do
    if state ~= Enum.HumanoidStateType.None then
      morphHumanoid:SetStateEnabled(state, false)
    end
  end
  morphHumanoid:ChangeState(Enum.HumanoidStateType.None)
  
  for _, v in morphModel:GetDescendants() do
    if v:IsA("BasePart") then
      v.Massless = true
      v.CanCollide = false
      v.CanTouch = false
      v.CanQuery = false
    elseif v:IsA("Motor6D") then
      v.Enabled = false
    end
  end

  if morphModel:FindFirstChild("HumanoidRootPart") then morphModel.HumanoidRootPart:Destroy() end
  if morphModel:FindFirstChild("Animate") then morphModel.Animate:Destroy() end
end

local C2, C3

function MorphSystem:Morph(username)
  username = username or "souldrivenlove_simp"
  
  local character = Player.Character or Player.CharacterAdded:Wait()
  local humanoid = character:FindFirstChildOfClass("Humanoid")
  
  if not humanoid then return end
  
  local rigType = humanoid.RigType

  local success, userId = pcall(function() return Players:GetUserIdFromNameAsync(username) end)

  local desc = Players:GetHumanoidDescriptionFromUserId(userId)
  local morphModel = Players:CreateHumanoidModelFromDescription(desc, rigType)
  local morphHumanoid = morphModel:FindFirstChildOfClass("Humanoid")

  morphModel.Parent = character.Parent
  morphModel:PivotTo(character:GetPivot())

  setupMorphPhysics(morphModel)
	
  if rigType == Enum.HumanoidRigType.R15 then
    syncMotor6D(character, morphModel)
  end
	
  clearCharacterAssets(character)

  local limbs = (rigType == Enum.HumanoidRigType.R15) 
  and {"Head", "UpperTorso", "LowerTorso", "LeftUpperArm", "LeftLowerArm", "LeftHand", "RightUpperArm", "RightLowerArm", "RightHand", "LeftUpperLeg", "LeftLowerLeg", "LeftFoot", "RightUpperLeg", "RightLowerLeg", "RightFoot"}
  or {"Head", "Torso", "Left Arm", "Right Arm", "Left Leg", "Right Leg"}

  for _, limbName in limbs do
    local targetLimb = character:FindFirstChild(limbName)
    local morphLimb = morphModel:FindFirstChild(limbName)

    if targetLimb and morphLimb then
      targetLimb.Size = morphLimb.Size

      local weld = Instance.new("Weld")
      weld.Part0 = targetLimb
      weld.Part1 = morphLimb
      weld.Parent = targetLimb

      targetLimb.Transparency = 1
      
      local C
      C = targetLimb:GetPropertyChangedSignal("Transparency"):Connect(function()
        if not targetLimb or targetLimb.Parent then
          C:Disconnect()
          return
        end
        
        targetLimb.Transparency = 1
      end)
    end
  end

  local function cleanup()
    if morphModel then
      morphModel:Destroy()
    end
    if C2 then C2:Disconnect() C2 = nil end
    if C3 then C3:Disconnect() C3 = nil end
  end
  
  C2 = character.Destroying:Once(cleanup)
  C3 = Player.CharacterAdded:Once(cleanup)
end

return MorphSystem
