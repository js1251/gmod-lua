
util.PrecacheModel( "models/KingPommes/starwars/tie/defender.mdl" )
if (!util.IsValidModel( "models/KingPommes/starwars/tie/defender.mdl" )) then return end

ENT.RenderGroup = RENDERGROUP_OPAQUE
ENT.Base = "fighter_base"
ENT.Type = "vehicle"

ENT.PrintName = "TIE/D Defender"
ENT.Author = "KingPommes"
ENT.Category = "Star Wars Vehicles: Empire"
ENT.AutomaticFrameAdvance = true
ENT.Spawnable = false
ENT.AdminSpawnable = false

ENT.EntModel = "models/KingPommes/starwars/tie/defender.mdl"
ENT.Vehicle = "IMP_TIE_Defender"
ENT.StartHealth = 3700
ENT.Allegiance = "Empire"
list.Set("SWVehicles", ENT.PrintName, ENT)
if SERVER then
	
	ENT.FireSound = Sound("weapons/tie_shoot.wav")
	ENT.NextUse = {Wings = CurTime(),Use = CurTime(),FireRockets = CurTime(),}
	
	
	AddCSLuaFile()
	function ENT:SpawnFunction(pl, tr)
		local e = ents.Create("kingpommes_swv_tie_defender")
		e:SetPos(tr.HitPos + Vector(0,0,178))
		e:SetAngles(Angle(0,pl:GetAimVector():Angle().Yaw,0))
		e:Spawn()
		e:Activate()
		e:PrecacheGibs()
		return e
	end
	
	function ENT:SpawnLauncher()
		local pos1 = self:GetPos()
		local pos2 = self:GetPos()
		local ang1 = self:GetAngles()
		local ang2 = self:GetAngles() + Angle(90, 0, 0)

		local e = ents.Create("info_target")
		e:SetPos(pos1)
		e:SetAngles(ang1)
		e:SetParent(self)
		e:Spawn()
		e:Fire("AddOutput", "targetname target", 0)
		self.Target = e

		local e1 = ents.Create("npc_launcher")
		e1:SetPos(pos2)
		e1:SetAngles(ang2)
		e1:SetParent(self)
		e1:Spawn()
		e1:Activate()
		e1:Fire("SetEnemyEntity", "target")
		e1:Fire("AddOutput", "damage 1000")
		e1:Fire("AddOutput", "DamageRadius 300")
		e1:Fire("AddOutput", "FlySound weapons/rpg/rocket1.wav")
		e1:Fire("AddOutput", "Gravity 0")
		e1:Fire("AddOutput", "HomingDelay 0")
		e1:Fire("AddOutput", "HomingDuration 0")
		e1:Fire("AddOutput", "HomingStrength 0")
		e1:Fire("AddOutput", "LaunchSmoke 1")
		e1:Fire("AddOutput", "SmokeTrail 1")
		e1:Fire("AddOutput", "LaunchSound weapons/stinger_fire1.wav")
		e1:Fire("AddOutput", "LaunchSpeed 5000")
		e1:Fire("AddOutput", "MaxRange 99999")
		e1:Fire("AddOutput", "MinRange 100")
		e1:Fire("AddOutput", "MissileModel models/kingpommes/starwars/tie/missile.mdl")
		e1:Fire("AddOutput", "SpinMagnitude 0")
		e1:Fire("AddOutput", "SpinSpeed 0")
		self.Launcher = e1
	end
	
	function ENT:Initialize()

		self:SetNWInt("Health",self.StartHealth)
		
		self.WeaponLocations = {
			Wing1A = self:GetPos() + self:GetUp() * 111.6 + self:GetRight() *  -37 + self:GetForward() * 162.6,
			Wing1B = self:GetPos() + self:GetUp() * 111.6 + self:GetRight() *  37 + self:GetForward() * 162.6,
			Wing2A = self:GetPos() + self:GetUp() * -23.7 + self:GetRight() * 115.1 + self:GetForward() * 162.6,
			Wing2B = self:GetPos() + self:GetUp() *  -87.9 + self:GetRight() * 78.1 + self:GetForward() * 162.6,
			Wing3A = self:GetPos() + self:GetUp() *  -87.9 + self:GetRight() * -78.1 + self:GetForward() * 162.6,
			Wing3B = self:GetPos() + self:GetUp() * -23.7 + self:GetRight() * -115.1 + self:GetForward() * 162.6,
		}

		self.WeaponsTable = {}
		self.BoostSpeed = 3200
		self.ForwardSpeed = 3200
		self.UpSpeed = 500
		self.AccelSpeed = 12
		self.CanBack = true
		self.CanRoll = false
		self.CanStrafe = true
		self.HasWings = true
		self:SetSkin(0)
		self.al = 1
		
		self.Cooldown = 2
		self.Overheat = 0
		self.Overheated = false
		
		self.CanShoot = true
		self.Bullet = CreateBulletStructure(60,"green")
		self.FireDelay = 0.05
		self.AlternateFire = true
		self.FireGroup = {"Wing1A","Wing1B","Wing2A","Wing2B","Wing3A","Wing3B"}
		
		self.ExitModifier = {x=0,y=-120,z=-30}
		
		self.HasLookaround = true
		self.LandOffset = Vector(0,0, 178)
		self.PilotVisible = true
		self.PilotPosition = Vector(0, -11, -25)
		self.PilotAnim = "drive_jeep"
		
		self.rocketnum = 1
		self:SpawnLauncher()
		
		self.Bullet = CreateBulletStructure(85,"green")

		
		self.BaseClass.Initialize(self)
		-- Das hier löschen
		self.Filter = {self:GetChildEntities()}
		
		self:ResetSequence(self:LookupSequence("TopOpen"))
	end
	
	function ENT:Think()
		if(self.Inflight) then
			if(self.Wings) then
				self.CanRoll = true
				self.CanStrafe = false
			else
				self.CanRoll = false
				self.CanStrafe = true
			end
			if(self.Pilot:KeyDown(IN_ATTACK2)) then
				self:FireLauncher()
			end
		end
		self.BaseClass.Think(self)
	end
	
	-- Und diese Funktion hier.
	function ENT:GetChildEntities()
		return self
	end
	
	function ENT:Use(p)
	    if(!self.Inflight) then
			self:SetSkin(1)
			self.BaseClass.Enter(self,p)
			if self:GetSequence() == self:LookupSequence("TopOpen") then
				self:ResetSequence(self:LookupSequence("TopClose"))
			end
		end
	end
	
	function ENT:Exit(kill)
		self.BaseClass.Exit(self,kill)
		self:ResetSequence(self:LookupSequence("TopOpen"))
		self:SetSkin(0)
	end
	
	function ENT:Bang()
		self.BaseClass.Bang(self)
		self:GibBreakClient(self:GetVelocity())
		self:Remove()
	end
	
	function ENT:FireLauncher()
		if(self.NextUse.FireRockets < CurTime()) then
			if (self.rocketnum < 7) then
				self.Launcher:SetPos(self:GetAttachment(self:LookupAttachment("rocket" .. self.rocketnum)).Pos)
				self.Launcher:Fire("FireOnce")
				self.rocketnum = self.rocketnum + 1
			end
			if (self.rocketnum == 7) then 
				self.rocketnum = 1
				self.NextUse.FireRockets = CurTime()+15
				self:SetNWInt("FireBlast",self.NextUse.FireRockets)
			end
		end
	end
	function ENT:FireWeapons()
		if(self.NextUse.Fire < CurTime()) then
			for k,v in pairs(self.Weapons) do
				if(!IsValid(v)) then return end;
				local tr = util.TraceLine({
					start = self:GetPos(),
					endpos = self:GetPos()+self:GetForward()*10000,
					filter = {self},
				})
				
				local angPos = (tr.HitPos - v:GetPos())
				
				if(self.ShouldLock) then
					local e = self:FindTarget();
					if(IsValid(e)) then
						local tr = util.TraceLine( {
							start = v:GetPos(),
							endpos = e:GetPos(),
							filter = {self},
						} )
						if(!tr.HitWorld) then
							angPos = (e:GetPos() + e:GetUp()*(e:GetModelRadius()/3) + (self.LockOnOverride or Vector(0,0,0))) - v:GetPos();
						end
	
					end
				end
				
				self.Bullet.Attacker = self.Pilot or self;
				self.Bullet.Src		= v:GetPos();
				local spread = self.Accel.FWD/1000;
				self.Bullet.Spread = Vector(spread,spread,spread);
				
				self.Bullet.Dir = angPos
	
				if(!self.Disabled) then
					if(self.AlternateFire) then
						if (self.al == 1 and (k == self.FireGroup[1])) then
							v:FireBullets(self.Bullet)
						elseif (self.al == 2 and (k == self.FireGroup[2])) then
							v:FireBullets(self.Bullet)
						elseif (self.al == 3 and (k == self.FireGroup[3])) then
							v:FireBullets(self.Bullet)
						elseif (self.al == 4 and (k == self.FireGroup[4])) then
							v:FireBullets(self.Bullet)
						elseif (self.al == 5 and (k == self.FireGroup[5])) then
							v:FireBullets(self.Bullet)
						elseif (self.al == 6 and (k == self.FireGroup[6])) then
							v:FireBullets(self.Bullet)
						end
					else
						v:FireBullets(self.Bullet)
					end
				end
			end
			self.al = self.al + 1
			if(self.al == 7) then
				self.al = 1
			end
			self:EmitSound(self.FireSound,100,math.random(90,110))
			self.NextUse.Fire = CurTime() + (self.FireDelay)
		end
	end
end



if CLIENT then

	function ENT:Think()
		self.BaseClass.Think(self)
		local p = LocalPlayer()
		local Flying = p:GetNWBool("Flying"..self.Vehicle)
		if(Flying) then
			Health = self:GetNWInt("Health")
			Speed = self:GetNWInt("Speed")
		end
		
	end

	function ENT:Draw() self:DrawModel() end
	
	ENT.EnginePos = {}
	ENT.Sounds={
		Engine=Sound("vehicles/tie/tie_interceptor4.wav"),
	}
	ENT.CanFPV = true
	
	function ENT:FlightEffects()
		local normal = (self:GetForward() * -1):GetNormalized()
		local roll = math.Rand(-90,90)
		local p = LocalPlayer()		
		local FWD = self:GetForward()
		local id = self:EntIndex()

		for k,v in pairs(self.EnginePos) do
			
			local dynlight = DynamicLight(id + 4096 * k)
			dynlight.Pos = v+FWD*-5
			dynlight.Brightness = 2
			dynlight.Size = 150
			dynlight.Decay = 1024
			dynlight.R = 255
			dynlight.G = 100
			dynlight.B = 100
			dynlight.DieTime = CurTime()+1
			
		end
	end
	
	local Health = 0
	function ENT:Think()
		self.BaseClass.Think(self)
		local p = LocalPlayer()
		local IsFlying = p:GetNWBool("Flying"..self.Vehicle)
		
		local IsDriver = p:GetNWEntity(self.Vehicle) == self.Entity
		if(IsFlying and IsDriver) then
			Health = self:GetNWInt("Health")
		end
		
		if(IsFlying) then
			self.EnginePos = {
				self:GetPos()+self:GetForward()*-92+self:GetUp()*0+self:GetRight()*23.7,
				self:GetPos()+self:GetForward()*-92+self:GetUp()*0+self:GetRight()*-23.7,
			}
			if(!TakeOff and !Land) then
				self:FlightEffects()
			end
		end
	end

    ENT.ViewDistance = 700
    ENT.ViewHeight = 300
    ENT.FPVPos = Vector(6,0,6)
    ENT.FPVPos = Vector(6,0,6)


	function IMP_TIEDefenderOfDoomReticle()
		local p = LocalPlayer()
		local Flying = p:GetNWBool("FlyingIMP_TIE_Defender")
		local self = p:GetNWEntity("IMP_TIE_Defender")
		
		

		if(Flying and IsValid(self)) then
            local x = ScrW()/4*0.1
			local y = ScrH()/4*2.5
			if(self:GetFPV()) then			
			end
			SW_HUD_DrawHull(self.StartHealth)
			SW_WeaponReticles(self)
			SW_HUD_DrawOverheating(self)
            local pos = self:GetPos()+self:GetForward()*100+self:GetUp()*-45+self:GetRight()*0
            local x,y = SW_XYIn3D(pos)
			SW_HUD_Compass(self,x,y)
			SW_HUD_DrawSpeedometer()
			SW_HUD_WingsIndicator("defender",x,y)
			SW_BlastIcon(self,15)
		end
	end
	hook.Add("HUDPaint", "IMP_TIE_DefenderReticle", IMP_TIEDefenderOfDoomReticle)
end