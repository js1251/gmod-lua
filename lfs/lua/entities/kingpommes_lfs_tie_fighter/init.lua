
util.PrecacheModel( "models/kingpommes/starwars/tie/fighter.mdl" )
if (!util.IsValidModel( "models/kingpommes/starwars/tie/fighter.mdl" )) then return end

AddCSLuaFile( "shared.lua" )
AddCSLuaFile( "cl_init.lua" )
include("shared.lua")

function ENT:SpawnFunction( ply, tr, ClassName )

	if not tr.Hit then return end

	local ent = ents.Create( ClassName )
	ent:SetPos( tr.HitPos + tr.HitNormal * 178 )
	ent:Spawn()
	ent:Activate()

	return ent

end

function ENT:OnTick()
end

function ENT:RunOnSpawn()
	self:GetChildren()[1]:SetVehicleClass("phx_seat2")
	self:SetAutomaticFrameAdvance(true)
	self:ResetSequence(self:LookupSequence("TopOpen"))
end

function ENT:PrimaryAttack()
	if not self:CanPrimaryAttack() then return end

	self:EmitSound( "TIE_FIRE" )
	
	self:SetNextPrimary( 0.4 )
	
	local fP = { Vector(49.91,14.53,-42.09),Vector(49.91,-14.53,-42.09) }
	
	for k,v in pairs(fP) do
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
		bullet.Src 	= self:LocalToWorld( v )
		bullet.Dir 	= (TracePlane.HitPos - bullet.Src):GetNormalized()
		bullet.Spread 	= Vector( 0.01,  0.01, 0.01 )
		bullet.Tracer	= 1
		bullet.TracerName	= "lfs_laser_green"
		bullet.Force	= 100
		bullet.HullSize 	= 40
		bullet.Damage	= 60
		bullet.Attacker 	= self:GetDriver()
		bullet.AmmoType = "Pistol"
		bullet.Callback = function(att, tr, dmginfo)
			dmginfo:SetDamageType(DMG_AIRBOAT)
		end
		self:FireBullets( bullet )
		
		self:TakePrimaryAmmo()
	end
end

function ENT:SecondaryAttack()	
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
	self:EmitSound("TIE_STARTUP")
end

function ENT:OnEngineStopped()
	self:SetSkin(0)
	self:EmitSound("TIE_SHUTDOWN")
end
