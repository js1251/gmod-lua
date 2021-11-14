------------------------------------
------ Created by Jakob Sailer -----
------ LFS Base by blu / Luna ------
----------- DO NOT edit or ---------
------------ reupload!! ------------
------------------------------------

AddCSLuaFile()
ENT.Type = "anim"
--ENT.Base = "gmod_atte_rear"
ENT.PrintName = "AT-AT Head"
ENT.Author = "Jakob Sailer aka KingPommes"
ENT.AutomaticFrameAdvance = true
ENT.DoNotDuplicate = true
ENT.IdentifiesAsLFS = true

ENT.HeadTurnRange = {
	x = 30, -- symmetrical in both directions
	y = 45, -- symmetrical in both directions
}

function ENT:SetupDataTables()
	self:NetworkVar("Entity", 1, "BaseEnt")
	self:NetworkVar("Bool", 2, "IsLightOn")
end

if SERVER then

	function ENT:Think()
		self:NextThink(CurTime())
		return true
	end

	-- Override
	function ENT:Initialize()
		self:SetModel("models/kingpommes/starwars/atat/atat_head.mdl")
		self:PhysicsInit(SOLID_VPHYSICS)
		self:SetMoveType(MOVETYPE_VPHYSICS)
		self:SetSolid(SOLID_VPHYSICS)
		self:SetRenderMode(RENDERMODE_TRANSALPHA)
		self:SetUseType(SIMPLE_USE)
		self:AddFlags(FL_OBJECT)
		self:DrawShadow(true)

		self.PreviousHeadAngle = self:GetAngles()
	end

	function ENT:Use(ply)
		self.ATTEBaseEnt:Use(ply)
	end

	function ENT:ResetHead(strength)
		local forwardAngles = self.ATTEBaseEnt:GetAngles()
		local headAngles = self:GetAngles()
		strength = strength or 10
		forwardAngles.x = math.ApproachAngle(headAngles.x, forwardAngles.x, FrameTime() * strength)
		forwardAngles.y = math.ApproachAngle(headAngles.y, forwardAngles.y, FrameTime() * strength)
		forwardAngles.z = math.ApproachAngle(headAngles.z, forwardAngles.z, FrameTime() * strength)
		self:SetAngles(forwardAngles)

		self:SetPoseParameter("turrets_pitch", Lerp(FrameTime(), self:GetPoseParameter("turrets_pitch"), 0))
		self:SetPoseParameter("turrets_yaw", Lerp(FrameTime(), self:GetPoseParameter("turrets_yaw"), 0))
	end

	function ENT:AdjustHead(FTtoTick, Pod, EyeAngles)
		if not IsValid(self.ATTEBaseEnt) then return end

		self.DesiredHeadAngles = Pod:WorldToLocalAngles(EyeAngles)

		-- main guns in range depending on head angle
		local aimAng = self.DesiredHeadAngles - self:GetAngles()
		local aimDifference = math.abs(aimAng.p + aimAng.y)
		self.ATTEBaseEnt:SetFrontInRange( aimDifference < 3 )

		local CurrentAngles = self.PreviousHeadAngle or self.DesiredHeadAngles
		--local CurrentAngles = self.DesiredHeadAngles

		-- smooth motion
		CurrentAngles.x = math.ApproachAngle(CurrentAngles.x, self.DesiredHeadAngles.x, self.ATTEBaseEnt.HeadTurnrate * FTtoTick)
		CurrentAngles.y = math.ApproachAngle(CurrentAngles.y, self.DesiredHeadAngles.y, self.ATTEBaseEnt.HeadTurnrate * FTtoTick)

		-- turn head to match the horizon (but only up to a limit)
		local min = self.ATTEBaseEnt:GetAngles().z - self.ATTEBaseEnt.TipOverThreashold["roll"]
		local max = self.ATTEBaseEnt:GetAngles().z + self.ATTEBaseEnt.TipOverThreashold["roll"]
		local clampedZ = math.Clamp(0, min, max)
		CurrentAngles.z = math.ApproachAngle(CurrentAngles.z, clampedZ, self.ATTEBaseEnt.HeadTurnrate * FTtoTick * 2)

		self:SetAngles(CurrentAngles)
	end

	function ENT:ClampHead()
		-- clamping (looks retarded but the angle is only set if needed which avoids floaty physics when fell over)
		local CurrentAngles = Angle(0,0,0)
		local clamp = false
		local atatLocalAngles = self:WorldToLocalAngles(self.ATTEBaseEnt:GetAngles())
		local xMin = atatLocalAngles.x - self.HeadTurnRange["x"]
		local xMax = atatLocalAngles.x + self.HeadTurnRange["x"]
		if (xMin > 0 or xMax < 0) then
			CurrentAngles.x = math.Clamp(0, xMin, xMax)
			clamp = true
		end
		local yMin = atatLocalAngles.y - self.HeadTurnRange["y"]
		local yMax = atatLocalAngles.y + self.HeadTurnRange["y"]
		if (yMin > 0 or yMax < 0) then
			CurrentAngles.y = math.Clamp(0, yMin, yMax)
			clamp = true
		end
		local zMin = atatLocalAngles.z - self.ATTEBaseEnt.TipOverThreashold["roll"]
		local zMax = atatLocalAngles.z + self.ATTEBaseEnt.TipOverThreashold["roll"]
		if (zMin > 0 or zMax < 0) then
			CurrentAngles.z = math.Clamp(0, zMin, zMax)
			clamp = true
		end

		CurrentAngles = self:LocalToWorldAngles(CurrentAngles)
		self.PreviousHeadAngle = CurrentAngles

	 	if clamp then self:SetAngles(CurrentAngles) end
	end

	function ENT:ApplyBobbing()
		local HeadAttach = self.ATTEBaseEnt:GetAttachment(self.ATTEBaseEnt:LookupAttachment("attach.head"))
		if (not istable(HeadAttach)) then return end

		-- add the head bobbing back in
		local BobbingAngles = self.ATTEBaseEnt:WorldToLocalAngles(HeadAttach.Ang)
		-- finally set the angles of the head
		self:SetAngles(self:GetAngles() + BobbingAngles)
	end

	function ENT:PoseTurrets(Pod, EyeAngles)
		local CannonAttachment = self:GetAttachment(self:LookupAttachment("muzzle_cannon"))
		if not istable(CannonAttachment) then return end

		local eyeAnglesL = Pod:WorldToLocalAngles(EyeAngles)
		self.ATTEBaseEnt.MainGunDir = eyeAnglesL:Forward()

		local startpos = CannonAttachment.Pos
		local endpos = startpos + self.ATTEBaseEnt.MainGunDir * 50000

		local TracePlane = util.TraceHull({
			start = startpos,
			endpos = endpos,
			mins = Vector( -10, -10, -10 ),
			maxs = Vector( 10, 10, 10 ),
			filter = function(ent) return ent ~= self.ATTEBaseEnt and ent ~= self and ent ~= self.ATTEBaseEnt.Torso and ent:GetClass() ~= "lfs_aat_maingun_projectile" end
		})

		self.TurretGunPos = TracePlane.HitPos

		local AimAngles = -self:WorldToLocalAngles((TracePlane.HitPos - startpos):GetNormalized():Angle())
		self:SetPoseParameter("turrets_pitch", AimAngles.p)
		self:SetPoseParameter("turrets_yaw", AimAngles.y)

		local inRange = math.abs(AimAngles.y) < 22.5 and math.abs(AimAngles.p) < 45
		self.ATTEBaseEnt:SetRearInRange(inRange)
	end

	function ENT:ShootPrimary()
		if not self.ATTEBaseEnt:CanPrimaryAttack() then return end

		local cannonMuzzles = {
			[1] = self:GetAttachment(self:LookupAttachment("muzzle.cannon.L")),
			[2] = self:GetAttachment(self:LookupAttachment("muzzle.cannon.R"))
		}
		self.ATTEBaseEnt.IsShootingCannon = true
		self:ShootCannon(cannonMuzzles[1])
		timer.Simple(0.2, function()
			if not IsValid(self) then return end
			self:ShootCannon(cannonMuzzles[2])
			self.ATTEBaseEnt.IsShootingCannon = false
		end)

		self:ResetSequence("shoot")
		self.ATTEBaseEnt:SetNextPrimary(1)

		self.ATTEBaseEnt:SetTurretHeat(self.ATTEBaseEnt:GetTurretHeat() + 60)
		if self.ATTEBaseEnt:GetTurretHeat() >= 100 then
			self.ATTEBaseEnt:SetNextPrimary(6)
			self:EmitSound("lfs/aat/overheat.mp3")
		end
	end

	function ENT:ShootCannon(Muzzle)
		if istable(Muzzle) then
			local ent = ents.Create("lfs_aat_maingun_projectile")
			ent:SetPos(Muzzle.Pos)
			ent:SetAngles(Muzzle.Ang:Forward():Angle())
			ent:Spawn()
			ent:Activate()
			ent:SetAttacker(self.ATTEBaseEnt:GetDriver())
			ent:SetInflictor(self.ATTEBaseEnt)
			local PhysObj = self.ATTEBaseEnt:GetPhysicsObject()

			if IsValid(PhysObj) then
				PhysObj:EnableMotion(true)
				PhysObj:ApplyForceOffset(-Muzzle.Ang:Forward() * self.ATTEBaseEnt.Mass * 300 * FrameTime(), Muzzle.Pos)
			end
		end
		self.ATTEBaseEnt:TakePrimaryAmmo()
	end

	function ENT:ShootSecondary()
		if not self.ATTEBaseEnt:CanSecondaryAttack() then return end

		local turretMuzzles = {
			[true] = "muzzle.turret.L",
			[false] = "muzzle.turret.R",
		}

		self.alternatingTurret = self.alternatingTurret or false
		local bulletSource = self:GetAttachment(self:LookupAttachment(turretMuzzles[self.alternatingTurret]))
		if not istable(bulletSource) then return end

		dir = bulletSource.Ang:Forward()
		if (self.ATTEBaseEnt:GetRearInRange()) then
			dir = (self.TurretGunPos - bulletSource.Pos):GetNormalized()
		end

		local bullet = {}
		bullet.Num 	= 1
		bullet.Src 	= bulletSource.Pos
		bullet.Dir 	= dir
		bullet.Spread 	= Vector( 0.01,  0.01, 0 )
		bullet.Tracer	= 1
		bullet.TracerName	= "lfs_laser_red"
		bullet.Force	= 100
		bullet.HullSize 	= 22
		bullet.Damage	= 100
		bullet.Attacker 	= self.ATTEBaseEnt:GetDriver()
		bullet.AmmoType = "Pistol"
		bullet.Callback = function(_, tr, dmginfo)
			if tr.Entity.IsSimfphyscar then
				dmginfo:SetDamageType(DMG_DIRECT)
			else
				dmginfo:SetDamageType(DMG_AIRBOAT)
			end
		end
		self:FireBullets( bullet )

		self:EmitSound( "ATAT_TURRET" )
		self.ATTEBaseEnt:SetNextSecondary(0.2)
		self.alternatingTurret = not self.alternatingTurret
		self.ATTEBaseEnt:TakeSecondaryAmmo()
	end
end

if CLIENT then
	-- Override
	function ENT:Think()

		self.BaseEnt = self.BaseEnt or self:GetBaseEnt()
		self:AdjustNeck()
		--self:PoseTurrets()

		--local min, max = self:GetRenderBounds()
		--debugoverlay.Box( self:GetPos(), min, max, FrameTime() * 2, Color( 7, 209, 0, 5) ) --the green box

		self:UpdateLight()

		if self:GetIsLightOn() and not IsValid(self.light) then
			self:CreateLight()
		elseif not self:GetIsLightOn() and IsValid(self.light) then
			self:RemoveLight()
		end

		return true
	end

	function ENT:AdjustNeck()
		if not IsValid(self.BaseEnt) then return end

		--local NeckBone = self:LookupBone("neck")
		local NeckAttachmentTorso = self.BaseEnt:GetAttachment(self.BaseEnt:LookupAttachment("attach.neck"))
		local NeckAttachmentHead = self:GetAttachment(self:LookupAttachment("neck"))
		--if (NeckBone == nil or not istable(NeckAttachmentTorso) or not istable(NeckAttachmentHead)) then return end

		local NeckOffset = self:WorldToLocal(NeckAttachmentTorso.Pos) - self:WorldToLocal(NeckAttachmentHead.Pos)
		--self:ManipulateBonePosition(NeckBone, NeckOffset) --brakes RenderBounds see https://github.com/Facepunch/garrysmod-issues/issues/5007
		self:SetPoseParameter("neck_x", -NeckOffset.x)
		self:SetPoseParameter("neck_y", NeckOffset.y)
		self:SetPoseParameter("neck_z", NeckOffset.z)

		local NeckAttachmentFollow = self:GetAttachment(self:LookupAttachment("neck_follow"))
		if not istable(NeckAttachmentFollow) then return end

		local NeckAngle = self:WorldToLocalAngles(NeckAttachmentTorso.Ang)
		--self:ManipulateBoneAngles(NeckBone, NeckAngle) --brakes RenderBounds see https://github.com/Facepunch/garrysmod-issues/issues/5007

		self:SetPoseParameter("neck_pitch", -NeckAngle.pitch)
		self:SetPoseParameter("neck_yaw", NeckAngle.yaw)
		self:SetPoseParameter("neck_roll", NeckAngle.roll)
	end

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
		lamp:SetBrightness(20)

		local attachment = self:GetAttachment(self:LookupAttachment("muzzle_cannon"))
		if not istable(attachment) then return end

		lamp:SetPos(attachment.Pos)
		lamp:SetAngles(self:GetAngles())
		lamp:Update()
		self.light = lamp
	end

	function ENT:UpdateLight()
		if not IsValid(self.light) then return end

		local attachment = self:GetAttachment(self:LookupAttachment("muzzle_cannon"))
		if not istable(attachment) then return end

		self.light:SetPos(attachment.Pos)
		self.light:SetAngles(self:GetAngles())
		self.light:Update()
	end

	function ENT:OnRemove()
		self:RemoveLight()
	end

	function ENT:Draw()
		self:DrawModel()
		if not IsValid(self.light) then return end

		local attachments = {
			l = self:GetAttachment(self:LookupAttachment("light.l")),
			r = self:GetAttachment(self:LookupAttachment("light.r"))
		}
		for _, v in pairs(attachments) do
			if not istable(v) then continue end

			render.SetMaterial(Material("sprites/light_glow02_add"))
			render.DrawSprite(v.Pos, 150, 150, Color(255, 251, 228))

			render.SetMaterial(Material("effects/lfs_base/spotlight_projectorbeam"))
			render.DrawBeam(v.Pos,  v.Pos + v.Ang:Forward() * 800, 300, 0, 0.99, Color(255, 253, 245, 10))
		end
	end
end
