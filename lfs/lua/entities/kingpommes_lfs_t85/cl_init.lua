include("shared.lua")

function ENT:LFSCalcViewFirstPerson( view, ply ) -- modify first person camera view here
	if ply == self:GetDriver() then
		view.origin = view.origin + self:GetUp() * 8 + self:GetForward() * 12
	elseif ply == self:GetGunner() then
		-- gunner view
	end
	
	return view
end

function ENT:LFSCalcViewThirdPerson( view, ply ) -- modify third person camera view here
	return view
end

function ENT:LFSHudPaint( X, Y, data, ply ) -- driver only
end

function ENT:LFSHudPaintPassenger( X, Y, ply ) -- all except driver
end

function ENT:CalcEngineSound( RPM, Pitch, Doppler )
	if self.ENG then
		self.ENG:ChangePitch(  math.Clamp( 60 + Pitch * 40 + Doppler,0,255) )
		self.ENG:ChangeVolume( math.Clamp( Pitch, 0.5,1) )
	end
end

function ENT:EngineActiveChanged( bActive )
	if bActive then
		self.ENG = CreateSound( self, "T85_IDLE" )
		self.ENG:PlayEx(0,0)
	else
		self:SoundStop()
	end
end

function ENT:OnRemove()
	self:SoundStop()
	
	if IsValid( self.TheRotor ) then -- if we have an rotor
		self.TheRotor:Remove() -- remove it
	end
end

function ENT:SoundStop()
	if self.ENG then
		self.ENG:Stop()
	end
end

function ENT:AnimFins()
	-- wings handled in init.lua as wings have attachmentpoints that need to be serverside
	
	-- yoke movement
	local FT = FrameTime() * 10
	local Pitch = self:GetRotPitch()
	local Yaw = self:GetRotYaw()
	local Roll = -self:GetRotRoll()
	self.smPitch = self.smPitch and self.smPitch + (Pitch - self.smPitch) * FT or 0
	self.smYaw = self.smYaw and self.smYaw + (Yaw - self.smYaw) * FT or 0
	self.smRoll = self.smRoll and self.smRoll + (Roll - self.smRoll) * FT or 0
	
	self:SetPoseParameter("yoke_roll",self.smRoll)
	self:SetPoseParameter("yoke_pitch",-self.smPitch)
	self:SetPoseParameter("yoke_yaw",-self.smYaw)
	
	-- engine exhause scale
	local EngBones = {
		self:LookupBone("engine_lu"),
		self:LookupBone("engine_ll"),
		self:LookupBone("engine_ru"),
		self:LookupBone("engine_rl"),
	}
	
	local ScaleFactor = 0.7 + self:GetThrottlePercent() * 0.004
	local EngScale = Vector(1, ScaleFactor, ScaleFactor)
	
	for _,v in pairs (EngBones) do
		self:ManipulateBoneScale(v, EngScale)
	end
end

function ENT:AnimRotor()
	if not IsValid(self:GetGunner()) then return end
	
	self.nextAstro = self.nextAstro or 0
		if self.nextAstro < CurTime() then
		self.nextAstro = CurTime() + math.Rand(0.5,2)
		
		local HasShield = self:GetShield() > 0

		
		if self.OldShield == true and not HasShield then
			self:EmitSound( "lfs/naboo_n1_starfighter/astromech/shieldsdown"..math.random(1,2)..".ogg" )
		else
			if math.random(0,4) == 3 then
				self:EmitSound( "lfs/naboo_n1_starfighter/astromech/"..math.random(1,11)..".ogg" )
			end
		end
		
		self.OldShield = HasShield
	end
	local astroAng = self:WorldToLocalAngles(self:GetGunner():EyeAngles())
	astroAng = Angle(astroAng.Yaw, 0, 0)
	
	self:ManipulateBoneAngles(self:LookupBone("astro_head"), astroAng)
	
	local astroPos = self:GetBonePosition(self:LookupBone("astro_head"))
	
	if self.PrevHP ~= nil and self:GetHP() > self.PrevHP then
		
		astroPos = astroPos + self:GetForward() * -16 + self:GetUp() * 2
		
		local effectdata = EffectData()
		effectdata:SetOrigin( astroPos )
		util.Effect( "StunstickImpact", effectdata )
		
		self:EmitSound( "T85_REPAIR" )
	end
	
	self.PrevHP = self:GetHP()
end

function ENT:AnimCabin()
	local TVal = (self:GetActive() or self:GetAI()) and 0 or 1
	
	self.CockpitOpen = self.CockpitOpen and self.CockpitOpen + math.Clamp(TVal - self.CockpitOpen,-FrameTime(),FrameTime()) or 0
	self:SetPoseParameter("cockpit", self.CockpitOpen)

	if self.CabinSoundPlayed ~= TVal then
		self:EmitSound( "T85_COCKPIT" )
	end
	
	self.CabinSoundPlayed = TVal
end

function ENT:AnimLandingGear()
	if not self:GetEngineActive() then
		if not self.LGPose then self.LGPose = 0 end
		self:SetPoseParameter("landing_gear", self.LGPose)
		return
	end
	
	local LGSpeed = 0.5
	local VtolMode = self.VtolAllowInputBelowThrottle > self:GetThrottlePercent() and 0 or 1
	self.LGearOpen = self.LGearOpen and self.LGearOpen + math.Clamp(VtolMode - self.LGearOpen, -FrameTime() * LGSpeed, FrameTime() * LGSpeed) or 0
	self:SetPoseParameter("landing_gear", self.LGearOpen)
	if (self.LGPose == 1 or self.LGPose == 0) and self.LGPose ~= self.LGearOpen then
		self:EmitSound("T85_LGEAR")
	end
	self.LGPose = self.LGearOpen	
end

function ENT:ExhaustFX()
	if not self:GetEngineActive() then return end
	
	self.nextEFX = self.nextEFX or 0
	
	if self.nextEFX < CurTime() then
		self.nextEFX = CurTime() + 0.01
		
		local emitter = ParticleEmitter( self:GetPos(), false )
		local Pos = {
			self:GetAttachment(self:LookupAttachment("engine5")).Pos,
			self:GetAttachment(self:LookupAttachment("engine6")).Pos,
			self:GetAttachment(self:LookupAttachment("engine7")).Pos,
			self:GetAttachment(self:LookupAttachment("engine8")).Pos,
		}
		
		local FullThrottle = self:GetThrottlePercent() >= 35

		if self.OldFullThrottle ~= FullThrottle then
			self.OldFullThrottle = FullThrottle
			if FullThrottle then 
				self.BoostAdd = 3
			end
		end

		self.BoostAdd = self.BoostAdd and (self.BoostAdd - self.BoostAdd * FrameTime()) or 0
		
		if emitter then
			for k, v in pairs( Pos ) do
				local Sub = Mirror and 1 or -1
				local vOffset = v
				local vNormal = -self:GetForward()

				vOffset = vOffset + vNormal * 1
				
				local particle = emitter:Add( "effects/muzzleflash2", vOffset )
				if not particle then return end
				
				particle:SetDieTime( 0.1  + self.BoostAdd * 0.1)
				particle:SetColor( 0, 80, 255 )
				particle:SetStartSize( math.Rand(15,25) + self.BoostAdd )
				particle:SetEndSize( math.Rand(0,10)  + self.BoostAdd)
				particle:SetVelocity( vNormal * math.Rand(500,800) + self:GetVelocity() )
				particle:SetLifeTime( 0 )
				particle:SetStartAlpha( 255 )
				particle:SetEndAlpha( 255 )
				particle:SetRoll( math.Rand(-1,1) * 100 )
			end
			
			emitter:Finish()
		end
	end
end

local mat = Material( "sprites/light_glow02_add" )

function ENT:Draw()
	self:DrawModel()
	
	if not self:GetEngineActive() then return end
	
	if self.OldFullThrottle ~= FullThrottle then
		self.OldFullThrottle = FullThrottle
		if FullThrottle then 
			self.BoostAdd = 3
		end
	end

	self.BoostAdd = self.BoostAdd and (self.BoostAdd - self.BoostAdd * FrameTime()) or 0
	
	local Size = 80 + self:GetThrottlePercent() * 0.3 + self.BoostAdd
	
	local Pos = {
		self:GetAttachment(self:LookupAttachment("engine1")).Pos,
		self:GetAttachment(self:LookupAttachment("engine2")).Pos,
		self:GetAttachment(self:LookupAttachment("engine3")).Pos,
		self:GetAttachment(self:LookupAttachment("engine4")).Pos,
		
		self:GetAttachment(self:LookupAttachment("engine5")).Pos,
		self:GetAttachment(self:LookupAttachment("engine6")).Pos,
		self:GetAttachment(self:LookupAttachment("engine7")).Pos,
		self:GetAttachment(self:LookupAttachment("engine8")).Pos,
	}	
	for k, v in pairs(Pos) do
		render.SetMaterial( mat )
		if k < 5 then
			render.DrawSprite( v + self:GetForward() * -0.5, Size * 0.5, Size * 0.5, Color( 255, 215, 130, 255) )
		else
			render.DrawSprite( v + self:GetForward() * -2, Size, Size, Color( 0, 100, 255, 255) )
		end
	end
end
