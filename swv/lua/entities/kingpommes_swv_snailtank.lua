
util.PrecacheModel( "models/KingPommes/starwars/nr_n99/main.mdl" )
if (!util.IsValidModel( "models/KingPommes/starwars/nr_n99/main.mdl" )) then return end


-- Geschwindigkeit "zuckt"
-- Lasers src nicht richtig?!
-- Kann nicht auf den Boden ziehlen


ENT.RenderGroup = RENDERGROUP_BOTH
ENT.Base = "speeder_base"
ENT.Type = "vehicle"

ENT.PrintName = "NR-N99"
ENT.Author = "KingPommes"
--- BASE AUTHOR: Liam0102 ---
ENT.Category = "Star Wars Vehicles: CIS"
ENT.Spawnable = false
ENT.AdminSpawnable = false
ENT.AutomaticFrameAdvance =  true

ENT.Vehicle = "NRN99" 
ENT.EntModel = "models/KingPommes/starwars/nr_n99/main.mdl"

ENT.StartHealth = 1500
ENT.NoWobble = true
ENT.HoverMod = 8
ENT.CanShoot = true

list.Set("SWVehicles", ENT.PrintName, ENT)

if SERVER then

	ENT.FireSound = Sound("weapons/aat_shoot.wav")
	AddCSLuaFile()
	function ENT:SpawnFunction(pl, tr)
		local e = ents.Create("kingpommes_swv_snailtank")
		e:SetPos(tr.HitPos + Vector(130,0,0))
		e:SetAngles(Angle(0,pl:GetAimVector():Angle().Yaw+0,0))
		e:Spawn()
		e:Activate()
		return e
	end

	function ENT:SpawnTracks()
		local pos = self:GetPos()
		local pos2 = self:GetAttachment(self:LookupAttachment("track_left")).Pos
		local pos3 = self:GetAttachment(self:LookupAttachment("track_right")).Pos
		local ang = self:GetAngles()

		local e1 = ents.Create("prop_dynamic")
		e1:SetModel("models/KingPommes/starwars/nr_n99/tracks_middle.mdl")
		e1:SetPos(pos)
		e1:SetAngles(ang)
		e1:SetParent(self)
		e1:Spawn()
		e1:Activate()
		self.TracksMain = e1

		local e2 = ents.Create("prop_dynamic")
		e2:SetModel("models/KingPommes/starwars/nr_n99/tracks_side.mdl")
		e2:SetPos(pos2)
		e2:SetAngles(ang)
		e2:SetParent(self)
		e2:Spawn()
		e2:Activate()
		e2:Fire("setparentattachment", "track_left")
		self.TracksL = e2
		
		local e3 = ents.Create("prop_dynamic")
		e3:SetModel("models/KingPommes/starwars/nr_n99/tracks_side.mdl")
		e3:SetPos(pos3)
		e3:SetAngles(ang)
		e3:SetParent(self)
		e3:Spawn()
		e3:Activate()
		e3:Fire("setparentattachment", "track_right")
		self.TracksR = e3
	end
	
	function ENT:SpeederClassing()
	end

	function ENT:Initialize()
		self.BaseClass.Initialize(self)
		self.NextUse = {Use = CurTime(),Fire = CurTime(), Boost=CurTime(), FireBlast = CurTime(), Animate = CurTime()}
		self.Shots = 0
		self:SetSkin(0)
		
		self.Roll = 0
		self.YawAccel = 0
		self.num = 0

		self.SeatClass = "Seat_Airboat"
		self.SpeederClass = 2
		self.ForwardSpeed = 215.5
		self.BoostSpeed = 215.5
		self.AccelSpeed = 10
		self.HoverMod = 0
		self.CanBack = true
		self.StartHover = 0
		self.StandbyHoverAmount = 0
		self.ExitModifier = {x=80,y=-128,z=0}
		
		self.Bullet = CreateBulletStructure(150,"red")
		self.WeaponDir = self:GetAngles():Forward()
		self.WeaponLocations = {
			self:GetAttachment(self:LookupAttachment("barrel_small_right")).Pos + self:GetForward()*-100 + self:GetUp()*4,
			self:GetAttachment(self:LookupAttachment("barrel_small_left")).Pos + self:GetForward()*-100 + self:GetUp()*4,
		}
		self:SpawnWeapons()

		local driverPos = self:GetPos()+self:GetUp()*80+self:GetForward()*-16
		local driverAng = self:GetAngles()+Angle(0,-90,0)

		self:SpawnChairs(driverPos,driverAng,false)

		self:SpawnTracks()
		self.TracksL:ResetSequence(self.TracksL:LookupSequence("move"))
		self.TracksR:ResetSequence(self.TracksR:LookupSequence("move"))
		self.TracksMain:ResetSequence(self.TracksR:LookupSequence("move"))
		self.TracksL:SetPlaybackRate(0)
		self.TracksR:SetPlaybackRate(0)
		self.TracksMain:SetPlaybackRate(0)

	end

	hook.Add("PlayerEnteredVehicle","NRN99SeatEnter", function(p,v)
		if(IsValid(v) and IsValid(p)) then
			local e = v:GetParent()
			if e.IsSWVehicle and e:GetClass() == "kingpommes_swv_snailtank" then
				p:SetNetworkedEntity("NRN99",v:GetParent())
				e:SetNetworkedEntity("NRN99_PILOT", p)
			end
		end
	end)
    
	
	hook.Add("PlayerLeaveVehicle", "NRN99SeatExit", function(p,v)
		if(IsValid(v) and IsValid(p)) then
			local e = v:GetParent()
			if e.IsSWVehicle and e:GetClass() == "kingpommes_swv_snailtank" then
				if(IsValid(e)) then
					p:SetPos(e:GetPos() + e:GetRight()*e.ExitModifier.x + e:GetForward() * e.ExitModifier.y + e:GetUp() * e.ExitModifier.z)
				end
				p:SetNetworkedEntity("NRN99",NULL)
				e:SetNetworkedEntity("NRN99_PILOT",NULL)
			end
		end
	end)
	
	local ZAxis = Vector(0,0,1)

	function ENT:Think()
		self:NextThink(CurTime())
		self.BaseClass.Think(self)
		
		if(self.Inflight) then		
			if(IsValid(self.Pilot)) then

				local EndSpeedMain = self:GetNWInt("Speed") / self.ForwardSpeed
				self.TracksMain:SetPlaybackRate(EndSpeedMain*4)
				
				local EndSpeedR = ((self:GetNWInt("Speed") / self.ForwardSpeed) + (self.YawAccel/self.ForwardSpeed))*2.92
				self.TracksR:SetPlaybackRate(EndSpeedR)
				
				local EndSpeedL = ((self:GetNWInt("Speed") / self.ForwardSpeed) + (-(self.YawAccel/self.ForwardSpeed)))*2.92
				self.TracksL:SetPlaybackRate(EndSpeedL)
				
				self:SetNetworkedEntity("NRN99_YAW",self.YawAccel)
				
				if(self.Pilot:KeyDown(IN_ATTACK2)) then
					local blastpos = {
						self:GetAttachment(self:LookupAttachment("barrel_big_right")),
						self:GetAttachment(self:LookupAttachment("barrel_big_left")),
					}
					self:FireBlast(blastpos,true,1000);
					
				end	
				if(self.Pilot:KeyDown(IN_ATTACK)) then
					self:FireWeapons()
				end
				return true
			end
		end
		self:NextThink(CurTime())
	end
	
	function ENT:FireWeapons()
		self.BaseClass.FireWeapons(self)
		self:ResetSequence(self:LookupSequence("shoot_small"))
	end
	
	function ENT:FireBlast(angpos,gravity,vel)
		if(self.NextUse.FireBlast < CurTime()) then
			for k,v in pairs(angpos) do
				local e = ents.Create("cannon_blast")
				e:SetPos(v.Pos)
				e:Spawn()
				e:Activate()
				e:SetColor(Color(255,255,255,1))
				e:EmitSound(Sound("weapons/n1_cannon.wav"))
				local phys = e:GetPhysicsObject()
				phys:SetMass(100)
				phys:EnableGravity(gravity)
				phys:SetVelocity(v.Ang:Forward()*(2000*vel))
			end
			self.NextUse.FireBlast = CurTime() + 3
			self:ResetSequence(self:LookupSequence("shoot_big"))
		end
	end

	function ENT:Enter(p,driver)
		self:SetSkin(1)
		self.BaseClass.Enter(self, p, driver)
	end

	function ENT:Exit(driver,kill)
		self:SetSkin(0)
		self.BaseClass.Exit(self, driver,kill)
		self.TracksL:SetPlaybackRate(0)
		self.TracksR:SetPlaybackRate(0)
		self.TracksMain:SetPlaybackRate(0)
	end
	
	function ENT:Bang()
		self:SetSkin(0)
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
		self.MiddlePos = self:GetPos()+self:GetUp()*50
		if(self.Inflight) then
			local UP = ZAxis
			self.RightDir = self.Entity:GetRight()
			self.FWDDir = self.Entity:GetForward()
			
			self:RunTraces()

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
	local lastYaw = 0
	function ENT:Think()
		self.BaseClass.Think(self)
		self.Pilot = self:GetNWEntity("NRN99_PILOT")
		if(!IsValid(self.Pilot)) then return end
		self.YawAccel = self:GetNWEntity("NRN99_YAW")
		if(self.YawAccel == NULL) then return end
		
		lastYaw = math.Approach(lastYaw, self.YawAccel * 0.3, 0.3)
		self:ManipulateBoneAngles(self:LookupBone("steer_left"), Angle(lastYaw,0,0))
		self:ManipulateBoneAngles(self:LookupBone("steer_right"), Angle(lastYaw,0,0))

		local aim = self.Pilot:EyeAngles()
		local x = math.Clamp(aim.x, -45, 15)
		local y1 = math.Clamp(aim.y-90, -12, 15)
		local y2 = math.Clamp(aim.y-90, -15, 12)
		
		self:ManipulateBoneAngles(self:LookupBone("turret_left"), Angle(y1,0,x))
		self:ManipulateBoneAngles(self:LookupBone("turret_right"), Angle(y2,0,x))
	end
	
	ENT.HasCustomCalcView = true
	local View = {}
	function CalcView()
		local p = LocalPlayer()
		local self = p:GetNWEntity("NRN99", NULL)
		local DriverSeat = p:GetNWEntity("DriverSeat",NULL)
		
		if(IsValid(self)) then
			local pos, face
			if(DriverSeat:GetThirdPersonMode()) then
				pos = self:GetPos()+LocalPlayer():GetAimVector():GetNormal()*-300+self:GetUp()*300
				face = ((self:GetPos() + Vector(0,0,100))- pos):Angle()
			else
				pos = self:GetPos() + self:GetUp()*80 + self:GetForward()*105
				face = self:GetAngles()
			end
			View.origin = pos
			View.angles = face
			return View
		end
	end
	hook.Add("CalcView", "NRN99View", CalcView)
	
	function NRN99Reticle()
	
		local p = LocalPlayer();
		local Flying = p:GetNWBool("FlyingNRN99");
		local self = p:GetNWEntity("NRN99");
		if(Flying and IsValid(self)) then
			local WeaponsPos = {self:GetPos()};
			
			SW_Speeder_Reticles(self,WeaponsPos)
			SW_Speeder_DrawHull(self.StartHealth)
			SW_Speeder_DrawSpeedometer()

		end
	end
	
	hook.Add("HUDPaint", "NRN99Reticle", NRN99Reticle)
end