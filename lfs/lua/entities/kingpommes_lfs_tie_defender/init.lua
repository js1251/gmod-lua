
util.PrecacheModel( "models/kingpommes/starwars/tie/defender.mdl" )
if (!util.IsValidModel( "models/kingpommes/starwars/tie/defender.mdl" )) then return end

AddCSLuaFile( "shared.lua" )
AddCSLuaFile( "cl_init.lua" )
include("shared.lua")

function ENT:SpawnFunction( ply, tr, ClassName ) -- called by garry

	if not tr.Hit then return end

	local ent = ents.Create( ClassName )
	ent:SetPos( tr.HitPos + tr.HitNormal * 176 ) -- spawn x units above ground
	ent:Spawn()
	ent:Activate()

	return ent

end

function ENT:OnTick() -- use this instead of "think"
end

function ENT:RunOnSpawn() -- called when the vehicle is spawned
	self:GetChildren()[1]:SetVehicleClass("phx_seat2")
	self:SetAutomaticFrameAdvance(true)
	self:ResetSequence(self:LookupSequence("TopOpen"))
end

function ENT:PrimaryAttack()
	if not self:CanPrimaryAttack() then return end

	self:EmitSound( "TIE_FIRE" )
	
	self:SetNextPrimary( 0.2 )
	
	local fP = {
		Vector(162.59,37.06,111.55),
		Vector(162.59,-37.06,111.55),
		Vector(162.59,-115.15,-23.67),
		Vector(162.59,-78.07,-87.87),
		Vector(162.59,78.07,-87.87),
		Vector(162.59,115.15,-23.67)
	} --  -y,x,z

	self.NumPrim = self.NumPrim and self.NumPrim + 1 or 1
	if self.NumPrim > 6 then self.NumPrim = 1 end
	
	local startpos =  self:GetRotorPos()
	local TracePlane = util.TraceHull( {
		start = startpos,
		endpos = (startpos + self:GetForward() * 50000),
		mins = Vector( -10, -10, -10 ),
		maxs = Vector( 10, 10, 10 ),
		filter = function( e )
			local collide = e ~= self
			return collide
		end
	} )
	
	local bullet = {}
	bullet.Num 	= 1
	bullet.Src 	= self:LocalToWorld( fP[self.NumPrim] )
	bullet.Dir 	= (TracePlane.HitPos - bullet.Src):GetNormalized()
	bullet.Spread 	= Vector( 0.01,  0.01, 0.01 )
	bullet.Tracer	= 1
	bullet.TracerName	= "lfs_laser_green"
	bullet.Force	= 100
	bullet.HullSize 	= 40
	bullet.Damage	= 30
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

	self:TakeSecondaryAmmo()
	
	local startpos =  self:GetRotorPos()
	local tr = util.TraceHull( {
		start = startpos,
		endpos = (startpos + self:GetForward() * 50000),
		mins = Vector( -40, -40, -40 ),
		maxs = Vector( 40, 40, 40 ),
		filter = function( e )
			local collide = e ~= self
			return collide
		end
	} )

	local rocketpos = {
		self:GetPos()+self:GetForward()*32.3+self:GetUp()*107.42+self:GetRight()*1,
		self:GetPos()+self:GetForward()*32.3+self:GetUp()*-53.7+self:GetRight()*-93.03,
		self:GetPos()+self:GetForward()*32.3+self:GetUp()*-53.7+self:GetRight()*93.03,
	}	
		
	local ent = ents.Create( "lunasflightschool_missile" )
	local mPos
	if (self:GetAmmoSecondary()+1)%3 == 0 then
		mPos = rocketpos[1]
		self:SetNextSecondary( 0.25 )
	elseif (self:GetAmmoSecondary()+1)%3 == 2 then
		mPos = rocketpos[2]
		self:SetNextSecondary( 0.25 )
	else
		mPos = rocketpos[3]
		self:SetNextSecondary( 4 )
	end

	local Ang = self:WorldToLocal( mPos ).y > 0 and -1 or 1
	ent:SetPos( mPos )
	ent:SetAngles( self:LocalToWorldAngles( Angle(0,Ang,0) ) )
	ent:Spawn()
	ent:Activate()
	ent:SetAttacker( self:GetDriver() )
	ent:SetInflictor( self )
	ent:SetStartVelocity( self:GetVelocity():Length() )
	
	if tr.Hit then
		local Target = tr.Entity
		if IsValid( Target ) then
			if Target:GetClass():lower() ~= "lunasflightschool_missile" then
				ent:SetLockOn( Target )
				ent:SetStartVelocity( 0 )
			end
		end
	end
	
	constraint.NoCollide( ent, self, 0, 0 ) 
end

function ENT:OnKeyThrottle( bPressed )
	if bPressed then
		if self:CanSound() then
			self:EmitSound( "TIE_ROAR" )
			self:DelayNextSound( 1 )
		end
	else
		if (self:GetRPM() + 1) > self:GetMaxRPM() then
			if self:CanSound() then
				self:EmitSound( "TIE_ROAR" )
				self:DelayNextSound( 0.5 )
			end
		end
	end
end

function ENT:CreateAI()
end

function ENT:RemoveAI()
end

function ENT:InitWheels()
	local PObj = self:GetPhysicsObject()
	
	if IsValid( PObj ) then 
		PObj:EnableMotion( true )
	end
end

function ENT:ToggleLandingGear()
end

function ENT:RaiseLandingGear()
end

function ENT:HandleWeapons(Fire1, Fire2)
	local Driver = self:GetDriver()
	
	if IsValid( Driver ) then
		if self:GetAmmoPrimary() > 0 then
			Fire1 = Driver:KeyDown( IN_ATTACK )
		end
		if self:GetAmmoSecondary() > 0 then
			Fire2 = Driver:KeyDown( IN_ATTACK2 )
		end
	end
	
	if Fire1 then
		self:PrimaryAttack()
	end
	
	if Fire2 then
		self:SecondaryAttack()
	end
end

function ENT:OnEngineStarted()
	self:SetSkin(1)
end

function ENT:OnEngineStopped()
	self:SetSkin(0)
end
