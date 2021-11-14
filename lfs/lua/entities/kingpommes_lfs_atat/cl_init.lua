------------------------------------
------ Created by Jakob Sailer -----
------ LFS Base by blu / Luna ------
----------- DO NOT edit or ---------
------------ reupload!! ------------
------------------------------------

include("shared.lua")

function ENT:Initialize()
	self:GetOtherEnts()
	self.stompEffect = {}
	self.EngineSound = CreateSound(self, "ATAT_ENGINE")
	self.EngineSound:Play()
end

-- Overriding the base Think but nothing in it is required
function ENT:Think()
	self:DamageFX()

	local RPM = self:GetRPM()

	self.EngineSound:ChangePitch(math.Clamp(RPM / 18, 60, 150))
	self.EngineSound:ChangeVolume(math.Clamp(RPM / 1600, 0.5, 2))
	--self:CreateStompEffect()

	--self:LFSOverhaulFix()
end

/*
function ENT:LFSOverhaulFix()
	local driverSeat = self:GetDriverSeat()
	local driverPosRelative = self:WorldToLocal(driverSeat:GetPos())
	self.SeatPos = driverPosRelative
end
*/

function ENT:GetOtherEnts()
	if not (isfunction(self.GetTorsoEnt) and isfunction(self.GetHeadEnt)) then return end
	self.Torso = self:GetTorsoEnt()
	self.Head = self:GetHeadEnt()
end

-- Override
function ENT:LFSCalcViewThirdPerson(view, ply, FirstPerson)
	if FirstPerson then return view end

	if ply == self:GetDriver() or ply == self:GetGunner() or ply == self:GetTurretDriver() then
		local Pod = ply:GetVehicle()
		local radius = 400
		radius = radius + radius * Pod:GetCameraDistance()
		local StartPos = Pod:GetPos() + view.angles:Up() * 300
		local EndPos = StartPos - view.angles:Forward() * radius

		local WallOffset = 4

		local tr = util.TraceHull( {
			start = StartPos,
			endpos = EndPos,
			filter = function( e )
				local c = e:GetClass()
				local collide = not c:StartWith( "prop_physics" ) and not c:StartWith( "prop_dynamic" ) and not c:StartWith( "prop_ragdoll" ) and not e:IsVehicle() and not c:StartWith( "kingpommes_lfs_atat_" ) and not c:StartWith( "player" ) and not e.LFS
				return collide
			end,
			mins = Vector( -WallOffset, -WallOffset, -WallOffset ),
			maxs = Vector( WallOffset, WallOffset, WallOffset ),
		} )

		view.drawviewer = true
		view.origin = tr.HitPos

		if tr.Hit and not tr.StartSolid then
			view.origin = view.origin + tr.HitNormal * WallOffset
		end

		view.angles = view.angles + Angle(25, 0, 0)
	end
	return view
end

function ENT:ColorRamp(color1, color2, factor)
	local r = color1.r * factor + color2.r * (1 - factor)
	local g = color1.g * factor + color2.g * (1 - factor)
	local b = color1.b * factor + color2.b * (1 - factor)

	return Color(r, g, b)
end

function ENT:LFSHudPaintInfoText( X, Y, speed, alt, AmmoPrimary, AmmoSecondary, Throttle )
	local baseClass = scripted_ents.GetStored("lunasflightschool_atte")
	if not istable(baseClass) then return end
	baseClass = baseClass.t
	baseClass.LFSHudPaintInfoText( self, X, Y, speed, alt, AmmoPrimary, AmmoSecondary, Throttle )

	draw.SimpleText( "SEC", "LFS_FONT", 10, 60, Color(255,255,255,255), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP )
	draw.SimpleText( AmmoSecondary, "LFS_FONT", 120, 60, Color(255,255,255,255), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP )

	local pitch = math.Round(self:GetAngles().p)
	local pitchblend = 1 / math.pow(self.TipOverThreashold["pitch"], 2) * math.pow(math.abs(pitch), 2)
	local pitchColor = self:ColorRamp(Color(255,0,0), Color(255,255,255), pitchblend)
	draw.SimpleText( "PITCH", "LFS_FONT", 10, 85, Color(255,255,255,255), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP )
	draw.SimpleText( -pitch, "LFS_FONT", 120, 85, pitchColor, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP )

	local roll = math.Round(self:GetAngles().r)
	local rollblend = 1 / math.pow(self.TipOverThreashold["roll"], 2) * math.pow(math.abs(roll), 2)
	local rollColor = self:ColorRamp(Color(255,0,0), Color(255,255,255), rollblend)
	draw.SimpleText( "ROLL", "LFS_FONT", 10, 110, Color(255,255,255,255), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP )
	draw.SimpleText( roll, "LFS_FONT", 120, 110, rollColor, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP )
end

function ENT:LFSHudPaintPassenger( _, _, ply )
	if ply == self:GetGunner() then
		draw.SimpleText( "SEC", "LFS_FONT", 10, 10, Color(255,255,255,255), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP )
		draw.SimpleText( self:GetAmmoSecondary(), "LFS_FONT", 120, 10, Color(255,255,255,255), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP )

		local Muzzle = self.Head:GetAttachment(self.Head:LookupAttachment("muzzle_cannon"))
		if not istable(Muzzle) then return end
		local startpos = Muzzle.Pos

		local Trace = util.TraceHull({
			start = startpos,
			endpos = startpos + LocalPlayer():EyeAngles():Forward() * 50000,
			mins = Vector(-10, -10, -10),
			maxs = Vector(10, 10, 10),
			filter = function(ent) return ent ~= self and ent ~= self.Head and ent ~= self.Torso and ent:GetClass() ~= "lfs_aat_maingun_projectile" end
		})

		local HitPilot = Trace.HitPos:ToScreen()
		local X = HitPilot.x
		local Y = HitPilot.y

		if self:GetRearInRange() then
			surface.SetDrawColor( 255, 255, 255, 255 )
		else
			surface.SetDrawColor( 255, 0, 0, 255 )
		end

		simfphys.LFS.DrawCircle( X, Y, 10 )
		surface.DrawLine( X + 10, Y, X + 20, Y )
		surface.DrawLine( X - 10, Y, X - 20, Y )
		surface.DrawLine( X, Y + 10, X, Y + 20 )
		surface.DrawLine( X, Y - 10, X, Y - 20 )

		-- shadow
		surface.SetDrawColor( 0, 0, 0, 80 )
		simfphys.LFS.DrawCircle( X + 1, Y + 1, 10 )
		surface.DrawLine( X + 11, Y + 1, X + 21, Y + 1 )
		surface.DrawLine( X - 9, Y + 1, X - 16, Y + 1 )
		surface.DrawLine( X + 1, Y + 11, X + 1, Y + 21 )
		surface.DrawLine( X + 1, Y - 19, X + 1, Y - 16 )
	end
end

function ENT:LFSHudPaintCrosshair(_, _)
	if not IsValid(self.Head) then return end
	local Muzzle = self.Head:GetAttachment(self.Head:LookupAttachment("muzzle_cannon"))
	if not istable(Muzzle) then return end
	local startpos = Muzzle.Pos

	local Trace = util.TraceHull({
		start = startpos,
		endpos = startpos + LocalPlayer():EyeAngles():Forward() * 50000,
		mins = Vector(-10, -10, -10),
		maxs = Vector(10, 10, 10),
		filter = function(ent) return ent ~= self and ent ~= self.Head and ent ~= self.Torso and ent:GetClass() ~= "lfs_aat_maingun_projectile" end
	})

	local HitPilot = Trace.HitPos:ToScreen()
	local X = HitPilot.x
	local Y = HitPilot.y

	if self:GetFrontInRange() then
		surface.SetDrawColor(255, 255, 255)
	elseif self:GetRearInRange() and not IsValid(self:GetGunner()) then
		surface.SetDrawColor(235, 215, 38)
	else
		surface.SetDrawColor(255, 0, 0)
	end

	simfphys.LFS.DrawCircle(X, Y, 10)
	surface.DrawLine(X + 10, Y, X + 20, Y)
	surface.DrawLine(X - 10, Y, X - 20, Y)
	surface.DrawLine(X, Y + 10, X, Y + 20)
	surface.DrawLine(X, Y - 10, X, Y - 20)
	-- shadow
	surface.SetDrawColor(0, 0, 0, 80)
	simfphys.LFS.DrawCircle(X + 1, Y + 1, 10)
	surface.DrawLine(X + 11, Y + 1, X + 21, Y + 1)
	surface.DrawLine(X - 9, Y + 1, X - 16, Y + 1)
	surface.DrawLine(X + 1, Y + 11, X + 1, Y + 21)
	surface.DrawLine(X + 1, Y - 19, X + 1, Y - 16)

	-- overheat indicator
	local heat = (self:GetTurretHeat() / 100)
	if heat > 0.01 then
		local sX = 70
		local sY = 6
		X = X - sX * 0.5
		Y = Y + 25
		surface.SetDrawColor(0, 0, 0, 255)
		surface.DrawRect(X - 1, Y - 1, sX + 2, sY + 2)
		surface.SetDrawColor(150, 150, 150, 100)
		surface.DrawRect(X, Y, sX, sY)
		surface.SetDrawColor(255, 255, 255, 255)
		surface.DrawRect(X, Y, sX * math.min(heat, 1), sY)

		if heat > 1 then
			surface.SetDrawColor(255, 0, 0, 255)
			surface.DrawRect(X + sX, Y, sX * math.min(heat - 1, 1), sY)
		end
	end
end

function ENT:DamageFX()
	local HP = self:GetHP()
	if HP >= 0 then return end

	if self.alreadyDead then return end
	self.alreadyDead = true
	self.EngineSound:Stop()

	timer.Simple(0, function()
		if IsValid(self:GetHeadEnt()) then
			-- front fallover effect
		else
			--ParticleEffectAttach("explosion_huge_smoking_chunks", PATTACH_POINT_FOLLOW, self, self:LookupAttachment("attach.neck"))
			--ParticleEffectAttach("explosion_huge", PATTACH_POINT_FOLLOW, self, self:LookupAttachment("attach.neck"))
		end
	end)
end

function ENT:OnRemove()
	self.EngineSound:Stop()
end