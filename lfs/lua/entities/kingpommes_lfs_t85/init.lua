-- YOU CAN EDIT AND REUPLOAD THIS FILE. 
-- HOWEVER MAKE SURE TO RENAME THE FOLDER TO AVOID CONFLICTS

AddCSLuaFile( "shared.lua" )
AddCSLuaFile( "cl_init.lua" )
include("shared.lua")

function ENT:SpawnFunction( ply, tr, ClassName ) -- called by garry
	if not tr.Hit then return end

	local ent = ents.Create( ClassName )
	ent.dOwnerEntLFS = ply  -- this is important
	
	ent:SetPos( tr.HitPos + tr.HitNormal * 52 )
	ent:SetAngles(Angle(0,ply:GetAimVector():Angle().Yaw,0))
	ent:Spawn()
	ent:Activate()

	return ent
end

function ENT:OnTick() -- use this instead of "think"
	local FullThrottle = self:GetThrottlePercent() >= 35

	if self.OldFullThrottle ~= FullThrottle then
		self.OldFullThrottle = FullThrottle
		if FullThrottle then 
			self:EmitSound( "T85_BOOST" )
		end
	end
	
	if IsValid(self:GetGunner()) then
		self:SetBodygroup(6, 1)
		self:GetGunner():SetNoDraw(true)
	else
		self:SetBodygroup(6, 0)
	end
	
	local wingspeed = 3.5
	self.WingFactor = self.WingFactor and (self.WingFactor + (self.WingsOpen - 1 - self.WingFactor) * FrameTime() * wingspeed) or 0
	self:SetPoseParameter("wings", self.WingFactor)
	
	self:DisableWep( self.WingsOpen > 1 )
	
	-- AI should open the wings if theres a target
	if self:GetAI() then
		if self:AIGetTarget() ~= NULL then
			self.WingsOpen = 2
		else
			self.WingsOpen = 1
		end
	end
end

function ENT:RunOnSpawn() -- called when the vehicle is spawned
	local SpawnedPod = self:AddPassengerSeat( Vector(-8,0,32), Angle(0,-90,0) ) -- add a passenger seat, store it inside "SpawnedPod" local variable
	SpawnedPod.ExitPos = Vector(0,80,20)  -- assigns an exit pos for SpawnedPod
	self:SetGunnerSeat( SpawnedPod )
	
	self:GetDriverSeat():SetVehicleClass("phx_seat2")
	self:SetColor(Color(0, 161, 255, 255))
	
	self.FireIndex = 4
	self.ProtonIndex = 2
	self.WingsOpen = 1
end

function ENT:PrimaryAttack()
	if not self:CanPrimaryAttack() then return end
	
	if self.WingsOpen < 2 then return end

	self:SetNextPrimary( 0.15 )
	
	self:EmitSound("T85_FIRE")
	
	local startpos =  self:GetRotorPos()
	local TracePlane = util.TraceHull( {
		start = startpos,
		endpos = (startpos + self:GetForward() * 50000),
		mins = Vector( -10, -10, -10 ),
		maxs = Vector( 10, 10, 10 ),
		filter = self
	} )
	
	local FireSource = {
		self:GetAttachment(self:LookupAttachment("muzzle1")).Pos,
		self:GetAttachment(self:LookupAttachment("muzzle2")).Pos,
		self:GetAttachment(self:LookupAttachment("muzzle3")).Pos,
		self:GetAttachment(self:LookupAttachment("muzzle4")).Pos,
	}
	
	self.FireIndex = self.FireIndex % 4 + 1
	
	local bullet = {}
	bullet.Num 	= 1
	bullet.Src 	= FireSource[self.FireIndex]
	bullet.Dir 	= (TracePlane.HitPos - bullet.Src):GetNormalized()
	bullet.Spread 	= Vector( 0.015,  0.015, 0 )
	bullet.Tracer	= 1
	bullet.TracerName	= "lfs_laser_red"
	bullet.Force	= 100
	bullet.HullSize 	= 40
	bullet.Damage	= 25
	bullet.Attacker 	= self:GetDriver()
	bullet.AmmoType = "Pistol"
	bullet.Callback = function(att, tr, dmginfo)
		dmginfo:SetDamageType(DMG_AIRBOAT)
	end	
	self:FireBullets( bullet )
	
	self:TakePrimaryAmmo()
end

function ENT:SecondaryAttack()
	if self:GetAI() then return end
	if not self:CanSecondaryAttack() then return end
	
	self:SetNextSecondary( 1 )

	self:TakeSecondaryAmmo()

	self:EmitSound( "T85_PROTON" )
	
	local startpos =  self:GetRotorPos()
	local tr = util.TraceHull( {
		start = startpos,
		endpos = (startpos + self:GetForward() * 50000),
		mins = Vector( -40, -40, -40 ),
		maxs = Vector( 40, 40, 40 ),
		filter = { 
			self,
			self:GetDriver(),
			self:GetGunner(),
			self.wheel_L,
			self.wheel_R,
			self.wheel_C,
		}
	} )
	
	local ProtonSource = {
		self:GetAttachment(self:LookupAttachment("proton1")).Pos,
		self:GetAttachment(self:LookupAttachment("proton2")).Pos,
	}
	
	self.ProtonIndex = self.ProtonIndex % 2 + 1
	
	local Pos = ProtonSource[self.ProtonIndex]
	
	local ent = ents.Create( "lunasflightschool_missile" )
	ent:SetPos( Pos )
	ent:SetAngles( (tr.HitPos - Pos):Angle() )
	ent:Spawn()
	ent:Activate()
	ent:SetAttacker( self:GetDriver() )
	ent:SetInflictor( self )
	ent:SetStartVelocity( self:GetVelocity():Length())
	ent:SetCleanMissile( true )

	constraint.NoCollide( ent, self, 0, 0 )
	
	if tr.Hit then
		local Target = tr.Entity
		if IsValid( Target ) then
			if Target:GetClass():lower() ~= "lunasflightschool_missile" then
				if Target ~= self then
					ent:SetLockOn( Target )
					ent:SetStartVelocity( 0 )
				end
			end
		end
	end
	
end

function ENT:HandleWeapons(Fire1, Fire2)
	local baseClass = scripted_ents.GetStored("lunasflightschool_basescript")
	if not istable(baseClass) then return end
	baseClass = baseClass.t

	baseClass.HandleWeapons(self, Fire1, Fire2)
	
	if IsValid( self:GetGunner() ) then
		if self:GetGunner():KeyDown( IN_ATTACK ) then
			self:AstroRepair()
		end
	end
end


function ENT:AstroRepair()
	if self.NextRepair == nil then
		self.NextRepair = CurTime()
	end
	
	if self:GetHP() == self.MaxHealth then return end
	
	if self.NextRepair < CurTime() then
		self:SetHP(math.Clamp(self:GetHP() + self.RepairValue, 0, self.MaxHealth))
		
		self.NextRepair = CurTime() + 0.5
	end
end

function ENT:CreateAI() -- called when the ai gets enabled
end

function ENT:RemoveAI() -- called when the ai gets disabled
end

function ENT:OnKeyThrottle( bPressed )
	if bPressed then
		if self:CanSound() then -- makes sure the player cant spam sounds
			self:DelayNextSound( 2 )
		end
	else
		if (self:GetRPM() + 1) > self:GetMaxRPM() then
			if self:CanSound() then
				self:EmitSound( "T85_BRAKE" )
				self:DelayNextSound( 0.5 )
			end
		end
	end
end

--[[
function ENT:ApplyThrustVtol( PhysObj, vDirection, fForce )
	PhysObj:ApplyForceOffset( vDirection * fForce,  self:GetElevatorPos() )
	PhysObj:ApplyForceOffset( vDirection * fForce,  self:GetWingPos() )
end

function ENT:ApplyThrust( PhysObj, vDirection, fForce )
	PhysObj:ApplyForceOffset( vDirection * fForce, self:GetRotorPos() )
end
]]--

function ENT:OnEngineStarted()
	--[[ play engine start sound? ]]--
	self:EmitSound( "T85_START" )
end

function ENT:OnEngineStopped()
	--[[ play engine stop sound? ]]--
	self:EmitSound( "T85_STOP" )
end

function ENT:OnVtolMode( IsOn )
	--[[ called when vtol mode is activated / deactivated ]]--

	if IsOn then
		self:DeployLandingGear()
		self.WingsOpen = 1
	else
		self:RaiseLandingGear()
	end	
end

--[[
	Overwriting ToggleLandingGear Function
	Spacebar can be mapped to toggle the wings instead
	Without loosing the landing gear
]]--
function ENT:ToggleLandingGear()
	self.nextWing = self.nextWing or 0
	if self.nextWing > CurTime() then return end
	
	if self:GetLGear() > 0.1 then return end
	
	self:EmitSound( "T85_WINGS" )
	
	self.WingsOpen = self.WingsOpen % 2 + 1
	
	self.nextWing = CurTime() + 1
end

function ENT:OnLandingGearToggled( bOn )
	self:EmitSound( "T85_LGEAR" )
	
	if bOn then
		--[[ set bodygroup of landing gear down? ]]--
	else
		--[[ set bodygroup of landing gear up? ]]--
	end
end
