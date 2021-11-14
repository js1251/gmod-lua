
util.PrecacheModel( "models/kingpommes/starwars/hailfire/hailfire_droid.mdl" )
if (!util.IsValidModel( "models/kingpommes/starwars/hailfire/hailfire_droid.mdl" )) then return end

ENT.RenderGroup = RENDERGROUP_BOTH
ENT.Base = "speeder_base"
ENT.Type = "vehicle"

ENT.PrintName = "Hailfire"
ENT.Author = "KingPommes"
--- BASE AUTHOR: Liam0102 ---
ENT.Category = "Star Wars Vehicles: CIS"
ENT.Spawnable = false
ENT.AdminSpawnable = false
ENT.AutomaticFrameAdvance =  true

ENT.Vehicle = "HAILFIRE" 
ENT.EntModel = "models/kingpommes/starwars/hailfire/hailfire_droid.mdl"

ENT.StartHealth = 800
ENT.NoWobble = true
ENT.HoverMod = 8
ENT.CanShoot = true
ENT.FireSound = Sound("KingPommes/starwars/hailfire/laser.wav")

list.Set("SWVehicles", ENT.PrintName, ENT)

if SERVER then

	AddCSLuaFile()
	function ENT:SpawnFunction(pl, tr)
		local e = ents.Create("kingpommes_swv_hailfire")
		e:SetPos(tr.HitPos)
		e:SetAngles(Angle(0,pl:GetAimVector():Angle().Yaw+0,0))
		e:Spawn()
		e:Activate()
		return e
	end

	function ENT:SpawnWheels()
		local pos = self:GetPos()
		local ang = self:GetAngles()

		local e1 = ents.Create("prop_dynamic")
		e1:SetModel("models/KingPommes/starwars/hailfire/hailfire_wheel_r.mdl")
		e1:SetPos(pos)
		e1:SetAngles(ang)
		e1:SetParent(self)
		e1:Spawn()
		e1:Activate()
		self.WheelR = e1

		local e2 = ents.Create("prop_dynamic")
		e2:SetModel("models/KingPommes/starwars/hailfire/hailfire_wheel_l.mdl")
		e2:SetPos(pos)
		e2:SetAngles(ang)
		e2:SetParent(self)
		e2:Spawn()
		e2:Activate()
		self.WheelL = e2
	end

	function ENT:SpawnLaunchers()
		local pos1 = self:GetPos()+self:GetUp()*142+self:GetForward()*64
		local pos2 = self:GetPos()
		local ang1 = self:GetAngles()
		local ang2 = self:GetAngles() + Angle(0,90,85)

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
		e1:Fire("AddOutput", "FlySound KingPommes/starwars/hailfire/flying.wav")
		e1:Fire("AddOutput", "Gravity 2.5")
		e1:Fire("AddOutput", "HomingDelay 0")
		e1:Fire("AddOutput", "HomingDuration 0")
		e1:Fire("AddOutput", "HomingStrength 0")
		e1:Fire("AddOutput", "LaunchSmoke 1")
		e1:Fire("AddOutput", "SmokeTrail 1")
		e1:Fire("AddOutput", "LaunchSound KingPommes/starwars/hailfire/rocket.wav")
		e1:Fire("AddOutput", "LaunchSpeed 2048")
		e1:Fire("AddOutput", "MaxRange 99999")
		e1:Fire("AddOutput", "MinRange 100")
		e1:Fire("AddOutput", "MissileModel models/kingpommes/starwars/hailfire/hailfire_rocket_flying.mdl")
		e1:Fire("AddOutput", "SpinMagnitude 50")
		e1:Fire("AddOutput", "SpinSpeed 3")
		self.Launcher = e1
	end
	
	function ENT:SpawnRockets()
		self.Rocket = {}

		for k=1, 30, 1 do
			local attachmentName = "rocket" .. k
			local pos = self:GetAttachment(self:LookupAttachment(attachmentName)).Pos
			local ang = self:GetAttachment(self:LookupAttachment(attachmentName)).Ang

			local e = ents.Create("base_anim")
			e:SetModel("models/KingPommes/starwars/hailfire/hailfire_rocket.mdl")
			e:SetPos(pos)
			e:SetAngles(ang)
			e:SetParent(self)
			e:Spawn()
			e:Activate()
			self.Rocket[k] = e
		end
	end

	function ENT:SpeederClassing()
	end

	function ENT:Initialize()
		self.BaseClass.Initialize(self)
		self.NextUse = {Use = CurTime(),Fire = CurTime(), Boost=CurTime()}
		self.Shots = 0
		self.StartHealth = 800
		
		self.Roll = 0
		self.YawAccel = 0
		self.num = 0
		self.rocketnum = 1
		self.b2 = true

		self.SeatClass = "Seat_Airboat"
		self.SpeederClass = 2
		self.ForwardSpeed = 426
		self.BoostSpeed = 426
		self.AccelSpeed = 10
		self.HoverMod = 0
		self.CanBack = true
		self.StartHover = 0
		self.StandbyHoverAmount = 0
		self.ExitModifier = {x=128,y=0,z=0}

		local driverPos = self:GetPos()+self:GetUp()*80+self:GetForward()*-16
		local driverAng = self:GetAngles()+Angle(0,-90,0)
		
		self.Bullet = CreateBulletStructure(150,"red")
		self.WeaponDir = self:GetAngles():Forward()
		self.WeaponLocations = {
			self:GetPos() + self:GetUp()*64 + self:GetForward()*48
		}
		self:SpawnWeapons()

		self:SpawnChairs(driverPos,driverAng,false)

		self:SpawnWheels()
		self:SpawnLaunchers()
		self:SpawnRockets()
		self.WheelL:ResetSequence(self.WheelL:LookupSequence("idle"))
		self.WheelR:ResetSequence(self.WheelR:LookupSequence("idle"))
		self.WheelL:SetPlaybackRate(0)
		self.WheelR:SetPlaybackRate(0)
	end

	hook.Add("PlayerEnteredVehicle","HAILFIRESeatEnter", function(p,v)
		if(IsValid(v) and IsValid(p)) then
			local e = v:GetParent()
			if e.IsSWVehicle and e:GetClass() == "kingpommes_swv_hailfire" then
				p:SetNetworkedEntity("HAILFIRE",v:GetParent())
				e:SetNetworkedEntity("HAILFIRE_PILOT", p)
			end
		end
	end)
    
	
	hook.Add("PlayerLeaveVehicle", "HAILFIRESeatExit", function(p,v)
		if(IsValid(v) and IsValid(p)) then
			local e = v:GetParent()
			if e.IsSWVehicle and e:GetClass() == "kingpommes_swv_hailfire" then
				if(IsValid(e)) then
					p:SetPos(e:GetPos() + e:GetRight()*e.ExitModifier.x + e:GetForward() * e.ExitModifier.y + e:GetUp() * e.ExitModifier.z)
				end
				p:SetNetworkedEntity("HAILFIRE",NULL)
				e:SetNetworkedEntity("HAILFIRE_PILOT",NULL)
			end
		end
	end)

	local ZAxis = Vector(0,0,1)

	function ENT:Think()
		self:NextThink(CurTime())
		self.BaseClass.Think(self)
		if self.LastSkin ~= self:GetSkin() then
			self.LastSkin = self:GetSkin()
			self.WheelL:SetSkin(self.LastSkin)
			self.WheelR:SetSkin(self.LastSkin)
		end

		if self.LastColor ~= self:GetColor() then
			self.LastColor = self:GetColor()
			self.WheelL:SetColor(self.LastColor)
			self.WheelR:SetColor(self.LastColor)
		end

		if(self.Inflight) then		
			if(IsValid(self.Pilot)) then

				EndSpeedL = -(self.YawAccel/self.ForwardSpeed) + (self:GetNWInt("Speed") / self.ForwardSpeed)
				self.WheelL:SetPlaybackRate(EndSpeedL)
				EndSpeedR = (self.YawAccel/self.ForwardSpeed) + (self:GetNWInt("Speed") / self.ForwardSpeed)
				self.WheelR:SetPlaybackRate(EndSpeedR)

				if(self.Pilot:KeyDown(IN_ATTACK2)) then
					self:FireLaunchers()
				end
				return true
			end
		end
		self:NextThink(CurTime())
	end

	function ENT:Enter(p,driver)
		self.BaseClass.Enter(self, p, driver)
	end

	function ENT:Exit(driver,kill)
		self.BaseClass.Exit(self, driver,kill)
		self.WheelL:SetPlaybackRate(0)
		self.WheelR:SetPlaybackRate(0)
	end
	
	function ENT:Bang()
		self:EmitSound(Sound("Explosion.mp3"),100,100)
		local fx = EffectData()
		fx:SetOrigin(self:GetPos())
		fx:SetMagnitude(0.25)
		util.Effect("SWExplosion",fx,true,true)
        
		if(self.Inflight) then
			if(IsValid(self.Pilot)) then
				if(!self.Pilot:HasGodMode()) then
					self:Exit(true,true)
				else
					self:Exit(true,false)
				end
			end
		end
		self:GibBreakClient(self:GetVelocity())
		self:Remove()
	end

	--function ENT:FireWeapons()
	--	if(self.NextUse.Fire < CurTime()) then
	--		local WeaponPos = self:GetPos()
	--	
	--		local aim
	--		if IsValid(self.Pilot) then
	--			aim = self.Pilot:EyeAngles()
	--			
	--			tr = util.TraceLine({
	--				start = WeaponPos,
	--				endpos = self.Pilot:GetPos() + Angle(aim.x-2,aim.y):Forward() * 100000,
	--				filter = {
	--					self, 
	--					self.Pilot,
	--					self.Turret
	--				}
	--			})
	--
	--			if self.b2 then
	--				self:ResetSequence(self:LookupSequence("shoot1"))
	--			else
	--				self:ResetSequence(self:LookupSequence("shoot2"))
	--			end
	--			self.b2 = !self.b2
	--
	--			if tr.Entity == self or tr.Entity == self.WheelR or tr.Entity == self.WheelL or tr.Entity == self.Pilot then
	--				return
	--			end
	--
	--			local angPos = (tr.HitPos - WeaponPos)
	--
	--			self.MyBullet.Attacker = self.Pilot or self
	--			self.MyBullet.Inflictor = self
	--			self.MyBullet.Src	= WeaponPos + angPos
	--			self.MyBullet.Dir = angPos
	--
	--			self:FireBullets(self.MyBullet)
	--
	--			self:EmitSound(Sound("KingPommes/starwars/hailfire/laser.wav"), 120, math.random(90,110))
	--		end
	--		self.NextUse.Fire = CurTime() + 0.2
	--	end
	--end

	function ENT:FireLaunchers()
		if(self.NextUse.Fire < CurTime()) then
			if self.rocketnum < 31 then
				self.Launcher:SetPos(self:GetAttachment(self:LookupAttachment("rocket" .. self.rocketnum)).Pos + self:GetForward() * 48)
				self.Launcher:Fire("FireOnce")
				self.Rocket[self.rocketnum]:Remove()
				self.rocketnum = self.rocketnum + 1
			end
			if self.rocketnum == 31 then 
				if not timer.Exists("ReloadRockets") then
					timer.Create("ReloadRockets", 5, 1, function()
						if not IsValid(self) then return end
						self.rocketnum = 1
						self:EmitSound(Sound("ambient/levels/caves/ol04_gearengage.wav"), 120, math.random(90,110))
						self:SpawnRockets()
					end)
				end
			end
		self.NextUse.Fire = CurTime() + 0.2
		end
	end

	local FlightPhys = {
		secondstoarrive	= 0.5,
		maxangular = 50000,
		maxangulardamp = 100000,
		maxspeed = 1000000,
		maxspeeddamp = 500000,
		dampfactor = 1,
		teleportdistance = 5000
	}

	local ZAxis = Vector(0,0,1)

	function ENT:PhysicsSimulate( phys, deltatime )
		self.BackPos = self:GetPos()+self:GetForward()*-50+self:GetUp()*50
		self.FrontPos = self:GetPos()+self:GetForward()*50+self:GetUp()*50
		self.MiddlePos = self:GetPos()+self:GetUp()*50 // Middle one
		if(self.Inflight) then
			local UP = ZAxis
			self.RightDir = self.Entity:GetRight()
			self.FWDDir = self.Entity:GetForward()
			
			self:RunTraces() // Ignore

			self.ExtraRoll = Angle(0,0,self.YawAccel / 1*-.1)
		end

		local UP = ZAxis
		local RIGHT = self.RightDir
		local FWD = self.FWDDir
		local worldZ
		self:RunTraces()

		if(!self.Tractored) then
			if(self.Inflight and IsValid(self.Pilot)) then
				if(self.EngineOn) then
					if(self.Pilot:KeyDown(IN_RELOAD) and self.Pilot:KeyDown(IN_JUMP)) then
						self.num = 0
					elseif(self.Pilot:KeyDown(IN_FORWARD)) then
						self.num = self.num + self.ForwardSpeed/100
					elseif(self.Pilot:KeyDown(IN_BACK)) then
						self.num = self.num - self.ForwardSpeed/100
					elseif(self.Pilot:KeyDown(IN_FORWARD) and self.Pilot:KeyDown(IN_SPEED) and self.SpeederClass == 2) then
						self.num = self.num + self.BoostSpeed/100
					end
					if(!self.Boosting) then
						local min,max
						if(self.CanBack) then
							min = self.ForwardSpeed/2 * -1
						else
							min = 0
						end
						max = self.ForwardSpeed
						if(self.Pilot:KeyDown(IN_SPEED) and self.SpeederClass == 2) then
							max = self.BoostSpeed
						end

						if(self.ForwardSpeed > 0) then
							self.num = math.Clamp(self.num,min,max)
						elseif(self.ForwardSpeed < 0) then
							self.num = math.Clamp(self.num,max,min)
						end
					end		

					self.Accel.FWD = math.Approach(self.Accel.FWD,self.num,self.AccelSpeed)

					self:SetNWInt("Speed",self.Accel.FWD)
					if(IsValid(self.Pilot)) then
						self.Pilot:SetNWInt("SW_Speeder_Speed",self.Accel.FWD)
					end

					Speed = self.Pilot:GetNWInt("SW_Speeder_Speed") or self:GetNWInt("Speed")
					MaxSpeed = self.Pilot:GetNWInt("SW_Speeder_MaxSpeed") or self:GetNWInt("MaxSpeed")

					if(self.Pilot:KeyDown(IN_MOVERIGHT)) then
						self.YawAccel = -50 - (self.Accel.FWD/100)
					elseif(self.Pilot:KeyDown(IN_MOVELEFT)) then
						self.YawAccel = 50 + (self.Accel.FWD/100)
					else
						self.YawAccel = 0
						ExtraRoll = 0
					end

					phys:Wake()

					local ang = Angle(0,self:GetAngles().y+self.YawAccel,0)
					ang = ang
					if(!self.WaterTrace.Hit and self.UseGroundTraces) then
						ang = ang + (self.PitchMod or Angle(0,0,0))
					end	

					worldZ = self:GetPos().z

					if self.MiddleTrace.HitPos.z < worldZ - 10 or self.Accel.UP > 0 then
						self.Accel.UP = self.Accel.UP - 10
					else
						self.Accel.UP = 0
						worldZ = self:GetHover()
					end

					if(!self.CriticalDamage) then
						FlightPhys.angle = ang
						FlightPhys.pos = Vector(self:GetPos().x,self:GetPos().y,worldZ)+(FWD*self.Accel.FWD)+(RIGHT*self.Accel.RIGHT)+(UP*self.Accel.UP)
					else
						FlightPhys.angle = ang
						FlightPhys.pos = Vector(self:GetPos().x,self:GetPos().y,worldZ)+(FWD*-2000)			
					end
					FlightPhys.deltatime = deltatime
					phys:ComputeShadowControl(FlightPhys)
				end
			else
				if(self.ShouldStandby) then
					phys:Wake()

					worldZ = self:GetHover(true)
					FlightPhys.angle = Angle(0,self:GetAngles().y,0)
					FlightPhys.pos = Vector(self:GetPos().x,self:GetPos().y,worldZ)
					FlightPhys.deltatime = deltatime
					phys:ComputeShadowControl(FlightPhys)
				end
			end
		end
	end

	function ENT:Rotorwash(b)
	end

end

if CLIENT then

	ENT.Sounds={
			Engine=Sound("ambient/machines/train_idle.wav"),
		}
		
	function ENT:Think()
		self.BaseClass.Think(self)
	
		self.Pilot = self:GetNWEntity("HAILFIRE_PILOT")
	
		if(IsValid(self.Pilot)) then
	
			local aim = self.Pilot:EyeAngles()
	
			self:ManipulateBoneAngles(self:LookupBone("bone_turret_2"), Angle(0,0,-aim.x))
			self:ManipulateBoneAngles(self:LookupBone("bone_turret_1"), Angle(aim.y - 90,0,0))
	
			return true
		else
			self:ManipulateBoneAngles(self:LookupBone("bone_turret_2"), Angle(0,0,0))
			self:ManipulateBoneAngles(self:LookupBone("bone_turret_1"), Angle(0,0,0))
		end
	end

	ENT.HasCustomCalcView = true
	local View = {}
	function CalcView()
    
		local p = LocalPlayer()
		local self = p:GetNWEntity("HAILFIRE", NULL)
		local DriverSeat = p:GetNWEntity("DriverSeat",NULL)
    
		if(IsValid(self)) then
    
			if(IsValid(DriverSeat)) then
				if(DriverSeat:GetThirdPersonMode()) then
					local pos = self:GetPos() + self:GetUp()*40 + self:GetForward()*-10
					local face = self:GetAngles()
						View.origin = pos
						View.angles = face
				else
					local pos = self:GetPos()+LocalPlayer():GetAimVector():GetNormal()*-300+self:GetUp()*220
					local face = ((self:GetPos() + Vector(0,0,150))- pos):Angle()
						View.origin = pos
						View.angles = face
				end
				return View
			end
		end
	end
	hook.Add("CalcView", "HAILFIREView", CalcView)

	function HAILFIREReticle()

		local p = LocalPlayer()
		local Flying = p:GetNWBool("FlyingHAILFIRE")
		local self = p:GetNWEntity("HAILFIRE")
		if(Flying and IsValid(self)) then
			local cannonpos = self:GetAttachment(self:LookupAttachment("barrel")).Pos
			local cannonang = self:GetAttachment(self:LookupAttachment("barrel")).Ang

			surface.SetDrawColor(Color(200, 55, 55, 255))		

			tr = util.TraceLine({
				start = cannonpos,
				endpos = cannonpos + cannonang:Forward()*100000,
				filter = {
					self, 
					self.Pilot,
					self.WheelR,
					self.WheelL
				}
			})

			local vpos = tr.HitPos
			local screen = vpos:ToScreen()
			local x,y

			 x = 0
			 y = 0
			for k,v in pairs(screen) do
				if(k == "x") then
					x = v
				elseif(k == "y") then
					y = v
				end
			end

			local w = ScrW()/100*2
			local h = w
			x = x - w/2
			y = y - h/2

			surface.SetMaterial( Material( "hud/reticle.png", "noclamp" ) )
			surface.DrawTexturedRectUV( x , y, w, h, 0, 0, 1, 1 )
			SW_Speeder_DrawHull(self.StartHealth)
			SW_Speeder_DrawSpeedometer()
		end
	end
	hook.Add("HUDPaint", "HAILFIREReticle", HAILFIREReticle)
end