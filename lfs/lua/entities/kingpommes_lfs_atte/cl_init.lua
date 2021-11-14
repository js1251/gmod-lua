-- BASECLASS CREATED BY LUNA!
-- ADDITIONAL CODE BY JAKOB SAILER AKA KINGPOMMES AND ONINONI
-- DO NOT EDIT OR REUPLOAD THIS FILE
util.PrecacheModel("models/kingpommes/starwars/atte/lfs_front.mdl")
if not util.IsValidModel("models/kingpommes/starwars/atte/lfs_front.mdl") then return end
include("shared.lua")
include("entities/lunasflightschool_atte/cl_ikfunctions.lua")

hook.Add("OnEntityCreated", "KingPommes.ATTE.SeatSync", function(ent)
	if ent:GetClass() ~= "kingpommes_lfs_atte" then return end
	-- Timer is needed because of SetupDataTables being called after OnEntityCreated, so no Network Vars exist yet clientside.
	local entIndex = ent:EntIndex()

	timer.Create("KingPommes.SpawnATTE." .. entIndex, 0.2, 0, function()
		if IsValid(ent) then
			if not isfunction(ent.GetRearEnt) then return end
			local RearEnt = ent:GetRearEnt()
			if not IsValid(RearEnt) then return end

			for _, v in pairs(RearEnt:GetChildren()) do
				if v ~= DriverSeat and v:GetClass():lower() == "prop_vehicle_prisoner_pod" then
					v.LFSchecked = true
					v.LFSBaseEnt = ent
				end
			end
		end

		timer.Remove("KingPommes.SpawnATTE." .. entIndex)
	end)
end)

function ENT:LFSCalcViewThirdPerson(view, ply, FirstPerson)
	local baseClass = scripted_ents.GetStored("lunasflightschool_atte")
	if not istable(baseClass) then return end
	baseClass = baseClass.t
	local Pod = ply:GetVehicle()

	-- Top Gunner
	if ply == self:GetTurretDriver() then
		-- init ply. Values
		if ply.TurretView == nil then
			ply.TurretView = 0
			ply.FOV = ply:GetFOV()
		end

		-- create three-way switch
		if ply.OldView ~= FirstPerson then
			ply.TurretView = (ply.TurretView + 1) % 3
		end

		ply.OldView = FirstPerson

		-- First Person Mode
		if ply.TurretView == 1 then
			view.origin = Pod:GetPos() + Pod:GetUp() * 48 + Pod:GetRight() * -16
			ply:SetFOV(ply.FOV)

			return view
		end

		-- Zoomed View
		if ply.TurretView == 2 then
			view.origin = Pod:GetPos() + Pod:GetUp() * 16 + Pod:GetRight() * -185
			ply:SetFOV(30)

			return view
		end

		-- else regular thirdperson in baseclass
		ply:SetFOV(ply.FOV)
	else
		-- Rest of Passengers including Driver
		if FirstPerson then
			if ply == self:GetDriver() then
				view.origin = view.origin + self:GetForward() * 6 + self:GetUp() * 12
			else
				view.origin = view.origin
			end

			return view
		elseif ply ~= self:GetGunner() then
			local radius = 800
			radius = radius + radius * Pod:GetCameraDistance()
			local StartPos = self:LocalToWorld(Vector(200, 0, 400)) + view.angles:Up() * 0
			local EndPos = StartPos - view.angles:Forward() * radius
			local WallOffset = 4

			local tr = util.TraceHull({
				start = StartPos,
				endpos = EndPos,
				filter = function(e)
					local c = e:GetClass()
					local collide = not c:StartWith("prop_physics") and not c:StartWith("prop_dynamic") and not c:StartWith("prop_ragdoll") and not e:IsVehicle() and not c:StartWith("gmod_") and not c:StartWith("player") and not e.LFS

					return collide
				end,
				mins = Vector(-WallOffset, -WallOffset, -WallOffset),
				maxs = Vector(WallOffset, WallOffset, WallOffset),
			})

			view.drawviewer = true
			view.origin = tr.HitPos

			if tr.Hit and not tr.StartSolid then
				view.origin = view.origin + tr.HitNormal * WallOffset
			end
		end
	end
	-- third person for RearGunner and TurretGunner

	return baseClass.LFSCalcViewThirdPerson(self, view, ply, FirstPerson)
end

local GroupCollide = {
	[COLLISION_GROUP_DEBRIS] = true,
	[COLLISION_GROUP_DEBRIS_TRIGGER] = true,
	[COLLISION_GROUP_PLAYER] = true,
	[COLLISION_GROUP_WEAPON] = true,
	[COLLISION_GROUP_VEHICLE_CLIP] = true,
	[COLLISION_GROUP_WORLD] = true,
}

function ENT:RemoveLight()
	if not IsValid(self.light) then return end

	self.light:Remove()
	self.light = nil
end

function ENT:CreateLight()
	local lamp = ProjectedTexture()
	lamp:SetTexture("effects/flashlight001")
	lamp:SetFarZ(4096)
	lamp:SetNearZ(64)
	lamp:SetFOV(60)
	lamp:SetColor(Color(255, 248, 208))
	lamp:SetBrightness(10)

	local lightPos = self:GetPos() + self:GetForward() * 300 + self:GetUp() * 200

	lamp:SetPos(lightPos)
	lamp:SetAngles(self:GetAngles())
	lamp:Update()
	self.light = lamp
end

function ENT:UpdateLight()
	if not IsValid(self.light) then return end

	local lightPos = self:GetPos() + self:GetForward() * 300 + self:GetUp() * 200
	local lightAng = Angle(0, 0, 0)
	lightAng.p = math.Remap(self:GetPoseParameter("frontgun_pitch"), 0, 1, -45, 45)
	lightAng.r = 0
	lightAng.y = math.Remap(self:GetPoseParameter("frontgun_yaw"), 0, 1, -12, 12)
	self.lightAng = self:LocalToWorldAngles(lightAng)

	self.light:SetPos(lightPos)
	self.light:SetAngles(self.lightAng)
	self.light:Update()
end

function ENT:Think()
	self:UpdateLight()

	if self:GetIsLightOn() and not IsValid(self.light) then
		self:CreateLight()
	elseif not self:GetIsLightOn() and IsValid(self.light) then
		self:RemoveLight()
	end

	self:DamageFX()
	local RearEnt = self:GetRearEnt()
	if not IsValid(RearEnt) then return end

	-- delete legs if atte is in ragdoll mode
	if self:GetDieRagdoll() then
		self:LegClearAll()
		RearEnt:LegClearAll()

		return
	end

	local Vel = self:GetVelocity()
	local FT = math.min(FrameTime(), 0.08) -- if fps lower than 12, clamp the frametime to avoid spazzing.
	local Rate = FT * 20

	-- sync with server animation when not moving
	if Vel:Length() < 10 then
		self.Move = self:GetMove()
	else
		self.Move = self.Move and self.Move + self:WorldToLocal(self:GetPos() + Vel).x * FT * 1.8 or 0
	end

	-- Walking Parameters	
	local Cycles = {self.Move, self.Move + 180, self.Move, self.Move + 180, self.Move + 270, self.Move + 90,}

	-- FrontLeft
	-- FrontRight
	-- RearRight
	-- RearLeft
	-- MidLeft
	-- MidRight
	local IsMoving = self:GetIsMoving()

	-- Reset Legs to idle if carried or moving
	if self:GetIsCarried() then
		self.TRACEPOS1 = self:LocalToWorld(Vector(200, 70, 180))
		self.TRACEPOS2 = self:LocalToWorld(Vector(200, -70, 180))
		self.TRACEPOS3 = RearEnt:LocalToWorld(Vector(-160, -70, 180))
		self.TRACEPOS4 = RearEnt:LocalToWorld(Vector(-160, 70, 180))
		self.TRACEPOS5 = RearEnt:LocalToWorld(Vector(0, -80, 180))
		self.TRACEPOS6 = RearEnt:LocalToWorld(Vector(0, 80, 180))

		for k, _ in pairs(Cycles) do
			Cycles[k] = 0
		end

		IsMoving = true
	elseif not IsMoving then
		Cycles[1] = 0
		Cycles[2] = 0
		Cycles[3] = 180
		Cycles[4] = 180
		Cycles[5] = 90
		Cycles[6] = 90
	end

	local Legs = {
		-- Front Left
		{
			GlobalOffset = Vector(216.88, 46, 163.42),
			LegShift = self:GetRight() * -32,
			LegLift = 55,
			Mdl1 = "models/kingpommes/starwars/atte/lfs_leg3_front_l.mdl",
			Mdl2 = "models/kingpommes/starwars/atte/lfs_leg2.mdl",
			Mdl3 = "models/kingpommes/starwars/atte/lfs_leg1_l.mdl",
			Angle1 = Angle(-69, 245, 25),
			Angle2 = Angle(-80, -108, 0),
			Angle3 = Angle(180, 180, 180),
			Offset1 = Vector(0, 0, 0),
			Offset2 = Vector(0, 9.5, 0),
			Offset3 = Vector(0, 24, 0),
			Lenght1 = 77,
			Lenght2 = 73,
			GlobalAngle = Angle(90, 10, 0),
		},
		-- Front Right
		{
			GlobalOffset = Vector(216.88, -46, 163.42),
			LegShift = self:GetRight() * 32,
			LegLift = 55,
			Mdl1 = "models/kingpommes/starwars/atte/lfs_leg3_front_r.mdl",
			Mdl2 = "models/kingpommes/starwars/atte/lfs_leg2.mdl",
			Mdl3 = "models/kingpommes/starwars/atte/lfs_leg1_r.mdl",
			Angle1 = Angle(-69, 110, -20),
			Angle2 = Angle(-80, 108, 0),
			Angle3 = Angle(0, 0, 0),
			Offset1 = Vector(0, 0, 0),
			Offset2 = Vector(0, -9.5, 0),
			Offset3 = Vector(0, -24, 0),
			Lenght1 = 77,
			Lenght2 = 73,
			GlobalAngle = Angle(90, -10, 0),
		},
		-- Rear Left
		{
			GlobalOffset = Vector(-150.42, -84.54, 154.13),
			LegShift = self:GetRight() * 1,
			LegLift = 58,
			Mdl1 = "models/kingpommes/starwars/atte/lfs_leg3_rear.mdl",
			Mdl2 = "models/kingpommes/starwars/atte/lfs_leg2.mdl",
			Mdl3 = "models/kingpommes/starwars/atte/lfs_leg1_r.mdl",
			Angle1 = Angle(-90, -180, -270),
			Angle2 = Angle(-90, -180, -270),
			Angle3 = Angle(-180, 180, -180),
			Offset1 = Vector(0, -16, 0),
			Offset2 = Vector(0, -7, 0),
			Offset3 = Vector(0, -27, 0),
			Lenght1 = 55,
			Lenght2 = 75,
			GlobalAngle = Angle(90, 180, 0),
		},
		-- Rear Right
		{
			GlobalOffset = Vector(-150.42, 84.54, 154.13),
			LegShift = self:GetRight() * -1,
			LegLift = 58,
			Mdl1 = "models/kingpommes/starwars/atte/lfs_leg3_rear.mdl",
			Mdl2 = "models/kingpommes/starwars/atte/lfs_leg2.mdl",
			Mdl3 = "models/kingpommes/starwars/atte/lfs_leg1_l.mdl",
			Angle1 = Angle(-90, 180, -90),
			Angle2 = Angle(-90, 180, -90),
			Angle3 = Angle(0, 0, 0),
			Offset1 = Vector(0, 16, 0),
			Offset2 = Vector(0, 7, 0),
			Offset3 = Vector(0, 27, 0),
			Lenght1 = 55,
			Lenght2 = 75,
			GlobalAngle = Angle(90, -180, 0),
		},
		-- Middle Right
		{
			GlobalOffset = Vector(-8.86, -53.29, 171.73),
			LegShift = self:GetRight() * 88,
			LegLift = 67,
			Mdl2 = "models/kingpommes/starwars/atte/lfs_bigleg2.mdl",
			Mdl3 = "models/kingpommes/starwars/atte/lfs_bigleg1_r.mdl",
			Angle2 = Angle(-90, -86, -90),
			Angle3 = Angle(-180, 175, -180),
			Offset2 = Vector(0, 0, 0),
			Offset3 = Vector(0, -8, 0),
			Lenght1 = 65,
			Lenght2 = 112,
			GlobalAngle = Angle(135, 100, 0),
		},
		-- Middle Left
		{
			GlobalOffset = Vector(-8.86, 53.29, 171.73),
			LegShift = self:GetRight() * -88,
			LegLift = 67,
			Mdl2 = "models/kingpommes/starwars/atte/lfs_bigleg2.mdl",
			Mdl3 = "models/kingpommes/starwars/atte/lfs_bigleg1_l.mdl",
			Angle2 = Angle(-90, 86, 90),
			Angle3 = Angle(0, 5, 0),
			Offset2 = Vector(0, 0, 0),
			Offset3 = Vector(0, 8, 0),
			Lenght1 = 65,
			Lenght2 = 112,
			GlobalAngle = Angle(135, -100, 0),
		},
	}

	local TRACEPOS = {self.TRACEPOS1, self.TRACEPOS2, self.TRACEPOS3, self.TRACEPOS4, self.TRACEPOS5, self.TRACEPOS6,}

	local FSOG = {self.FSOG1, self.FSOG2, self.FSOG3, self.FSOG4, self.FSOG5, self.FSOG6,}

	local oldFSOG = {self.oldFSOG1, self.oldFSOG2, self.oldFSOG3, self.oldFSOG4, self.oldFSOG5, self.oldFSOG6,}

	local Stride = 40
	local Lift = 20
	local Up = self:GetUp()
	local Forward = self:GetForward()
	local Right = self:GetRight()
	local ParentEnt = self

	for k, v in pairs(Legs) do
		if k > 2 then
			Forward = RearEnt:GetForward()
			Right = RearEnt:GetRight()
			Up = RearEnt:GetUp()
			ParentEnt = RearEnt
		end

		local X = 20 + math.cos(math.rad(Cycles[k])) * Stride
		local Z = math.max(math.sin(math.rad(-Cycles[k])), 0) * Lift
		local STARTPOS = ParentEnt:LocalToWorld(v["GlobalOffset"])
		TRACEPOS[k] = TRACEPOS[k] and TRACEPOS[k] or STARTPOS

		if Z > 0 or not IsMoving then
			TRACEPOS[k] = TRACEPOS[k] + (STARTPOS + Forward * X - TRACEPOS[k]) * Rate
			FSOG[k] = false
		else
			FSOG[k] = true
		end

		local ENDPOS = util.TraceLine({
			start = TRACEPOS[k] - Up * 50,
			endpos = TRACEPOS[k] - Up * 160,
			filter = function(ent)
				if ent == self or ent == self:GetRearEnt() or GroupCollide[ent:GetCollisionGroup()] then return false end

				return true
			end,
		}).HitPos + v["LegShift"] + Vector(0, 0, v["LegLift"] + Z)

		if FSOG[k] ~= oldFSOG[k] then
			oldFSOG[k] = FSOG[k]

			if FSOG[k] then
				if k == 5 then
					ParentEnt:EmitSound("ATTE_STEP_HARD1")
				elseif k == 6 then
					ParentEnt:EmitSound("ATTE_STEP_HARD2")
				else
					ParentEnt:EmitSound("ATTE_STEP_SOFT")
				end

				local effectdata = EffectData()
				effectdata:SetOrigin(ENDPOS - Vector(0, 0, v["LegLift"]) - self:GetRight() * v["Offset3"].y)
				util.Effect("laatc_atte_walker_stomp", effectdata)
			end
		end

		local ATTACHMENTS = {}

		if k == 5 or k == 6 then
			ATTACHMENTS = {
				Leg2 = {
					MDL = v["Mdl2"],
					Ang = v["Angle2"],
					Pos = v["Offset2"]
				},
				Foot = {
					MDL = v["Mdl3"],
					Ang = v["Angle3"],
					Pos = v["Offset3"]
				},
			}
		else
			ATTACHMENTS = {
				Leg1 = {
					MDL = v["Mdl1"],
					Ang = v["Angle1"],
					Pos = v["Offset1"]
				},
				Leg2 = {
					MDL = v["Mdl2"],
					Ang = v["Angle2"],
					Pos = v["Offset2"]
				},
				Foot = {
					MDL = v["Mdl3"],
					Ang = v["Angle3"],
					Pos = v["Offset3"]
				},
			}
		end

		ParentEnt:GetLegEnts(k, v["Lenght1"], v["Lenght2"], ParentEnt:LocalToWorldAngles(v["GlobalAngle"]), STARTPOS, ENDPOS, ATTACHMENTS)
		-- adjust the toe angle
		ParentEnt.IK_Joints[k].Attachment3:SetPoseParameter("toes", math.Remap(Z, 0, 20, 0, 45))

		-- change feet skin
		if k ~= 5 and k ~= 6 then
			ParentEnt.IK_Joints[k].Attachment1:SetSkin(self:GetSkin())
		end
		ParentEnt.IK_Joints[k].Attachment2:SetSkin(self:GetSkin())
		ParentEnt.IK_Joints[k].Attachment3:SetSkin(self:GetSkin())

		-- adjust balljoint shift
		if k == 5 then
			RearEnt:SetPoseParameter("shift_right", math.Remap(Z, 0, 20, -8, 16))
		elseif k == 6 then
			RearEnt:SetPoseParameter("shift_left", math.Remap(Z, 0, 20, -8, 16))
		end
	end

	for _, _ in pairs(TRACEPOS) do
		self.TRACEPOS1 = TRACEPOS[1]
		self.TRACEPOS2 = TRACEPOS[2]
		self.TRACEPOS3 = TRACEPOS[3]
		self.TRACEPOS4 = TRACEPOS[4]
		self.TRACEPOS5 = TRACEPOS[5]
		self.TRACEPOS6 = TRACEPOS[6]
		self.FSOG1 = FSOG[1]
		self.FSOG2 = FSOG[2]
		self.FSOG3 = FSOG[3]
		self.FSOG4 = FSOG[4]
		self.FSOG5 = FSOG[5]
		self.FSOG6 = FSOG[6]
		self.oldFSOG1 = oldFSOG[1]
		self.oldFSOG2 = oldFSOG[2]
		self.oldFSOG3 = oldFSOG[3]
		self.oldFSOG4 = oldFSOG[4]
		self.oldFSOG5 = oldFSOG[5]
		self.oldFSOG6 = oldFSOG[6]
	end
end

function ENT:Draw()
	self:DrawModel()
	if not (IsValid(self.light) and IsValid(self.lightAng)) then return end

	local midpos = self:GetPos() + self:GetForward() * 280 + self:GetUp() * 155
	local attachments = {
		l = midpos + self:GetRight() * 32,
		r = midpos - self:GetRight() * 48
	}
	for _, v in pairs(attachments) do
		render.SetMaterial(Material("sprites/light_glow02_add"))
		render.DrawSprite(v, 150, 150, Color(255, 251, 228))

		render.SetMaterial(Material("effects/lfs_base/spotlight_projectorbeam"))
		render.DrawBeam(v,  v + self.lightAng:Forward() * 800, 300, 0, 0.99, Color(255, 253, 245, 20))
	end
end

function ENT:OnRemove()
	self:LegClearAll()
	self:RemoveLight()
end

hook.Add("HUDPaint", "!!!!!LFS_PommesATTE_hud", function() end)