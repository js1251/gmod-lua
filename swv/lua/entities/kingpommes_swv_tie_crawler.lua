
util.PrecacheModel( "models/kingpommes/starwars/tie/crawler.mdl" )
if (!util.IsValidModel( "models/kingpommes/starwars/tie/crawler.mdl" )) then return end

ENT.RenderGroup = RENDERGROUP_BOTH
ENT.Base = "speeder_base"
ENT.Type = "vehicle"

ENT.PrintName = "TIE Crawler"
ENT.Author = "KingPommes"
--- BASE AUTHOR: Liam0102 ---
ENT.Category = "Star Wars Vehicles: Empire"
ENT.Spawnable = false
ENT.AdminSpawnable = false
ENT.AutomaticFrameAdvance = true

ENT.Vehicle = "CRAWLER" 
ENT.EntModel = "models/kingpommes/starwars/tie/crawler.mdl"

ENT.StartHealth = 1500
ENT.NoWobble = true
ENT.HoverMod = 150
ENT.CanShoot = true

ENT.backAmount = 20
ENT.frontAmount = 20
ENT.upAmount = 2
ENT.leftAmount = 60
ENT.rightAmount = 60

list.Set("SWVehicles", ENT.PrintName, ENT)

if SERVER then

	AddCSLuaFile()
	function ENT:SpawnFunction(pl, tr)
		local e = ents.Create("kingpommes_swv_tie_crawler")
		e:SetPos(tr.HitPos + Vector(0,0,4))
		e:SetAngles(Angle(0,pl:GetAimVector():Angle().Yaw+0,0))
		e:Spawn()
		e:Activate()
		e:PrecacheGibs()
		e:SetSkin(1)
		
		return e
	end

	function ENT:SpawnTracks()
		local pos = self:GetPos()
		local ang = self:GetAngles()

		local e1 = ents.Create("prop_dynamic")
		e1:SetModel("models/KingPommes/starwars/tie/crawler_tracks.mdl")
		e1:SetPos(pos)
		e1:SetAngles(ang)
		e1:SetParent(self)
		e1:Spawn()
		e1:Activate()
		self.TrackR = e1

		local e2 = ents.Create("prop_dynamic")
		e2:SetModel("models/KingPommes/starwars/tie/crawler_tracks.mdl")
		e2:SetPos(pos)
		e2:SetAngles(ang)
		e2:SetParent(self)
		e2:Spawn()
		e2:Activate()
		self.TrackL = e2
	end

	function ENT:SpeederClassing()
	end

	function ENT:Initialize()
		self.BaseClass.Initialize(self)
		self.NextUse = {Use = CurTime(),Fire = CurTime(), Boost = CurTime(), FireBlast = CurTime()}
		--self.Shots = 0
		self.FireSound = Sound("weapons/tie_shoot.wav")
		
		self.Roll = 0
		self.YawAccel = 0
		--self.num = 0
		--self.rocketnum = 1
		--self.b2 = true

		self.SeatClass = "phx_seat2"
		self.SpeederClass = 2
		self.ForwardSpeed = 270
		self.BoostSpeed = 	270
		self.AccelSpeed = 10
		self.HoverMod = 4
		self.CanBack = true
		self.StartHover = 4
		self.StandbyHoverAmount = 4
		self.ExitModifier = {x=64,y=-96,z=0}

		local driverPos = self:GetPos()+self:GetUp()*50+self:GetForward()*55
		local driverAng = self:GetAngles()+Angle(0,-90,0)

		self:SpawnChairs(driverPos,driverAng,false)
		--function self.DriverChair:SetThirdPersonMode() self:SetDTBool(3, true) end

		self:SpawnTracks()
		--self:SpawnLaunchers()
		--self:SpawnRockets()
		self.TrackL:ResetSequence(self.TrackL:LookupSequence("move"))
		self.TrackR:ResetSequence(self.TrackR:LookupSequence("move"))
		self.TrackL:SetPlaybackRate(0)
		self.TrackR:SetPlaybackRate(0)
		self.TrackR:Fire("SetParentAttachment", "track_r")
		self.TrackL:Fire("SetParentAttachment", "track_l")

		self.WeaponLocations = {
			self:GetPos()+self:GetUp()*39.29+self:GetForward()*117+self:GetRight()*14.5,
			self:GetPos()+self:GetUp()*39.29+self:GetForward()*117+self:GetRight()*-14.5
		}
		self.WeaponDir = self:GetAngles():Forward()*-1
		self:SpawnWeapons()
		self.Bullet = CreateBulletStructure(80,"green")
		self.CanShoot = true
		
		self:ResetSequence(self:LookupSequence("TopOpen"))
	end

	local ZAxis = Vector(0,0,1)

	function ENT:Think()
		self:NextThink(CurTime())
		self.BaseClass.Think(self)

		if self.LastColor ~= self:GetColor() then
			self.LastColor = self:GetColor()
			self.TrackL:SetColor(self.LastColor)
			self.TrackR:SetColor(self.LastColor)
		end

		if(self.Inflight) then		
			if(IsValid(self.Pilot)) then
				EndSpeedL = -(self.YawAccel/self.ForwardSpeed) + (self:GetNWInt("Speed") / self.ForwardSpeed)
				self.TrackL:SetPlaybackRate(EndSpeedL)
				
				
				EndSpeedR = (self.YawAccel/self.ForwardSpeed) + (self:GetNWInt("Speed") / self.ForwardSpeed)
				self.TrackR:SetPlaybackRate(EndSpeedR)
				
				if(self.Pilot:KeyDown(IN_ATTACK2)) then
					local angpos = {
						self:GetPos()+self:GetForward()*117+self:GetUp()*39.29+self:GetRight()*14.5,
						self:GetPos()+self:GetForward()*117+self:GetUp()*39.29+self:GetRight()*-14.5,
					}
					self:FireBlast(angpos,false,1000)
				elseif(self.Pilot:KeyDown(IN_ATTACK)) then
					self:FireWeapons()
				end
			end
		end
		self:NextThink(CurTime())
	end
	
	function ENT:FireBlast(angpos,gravity,vel)
		if(self.NextUse.FireBlast < CurTime()) then
			for k,v in pairs(angpos) do
				local e = ents.Create("cannon_blast")
				e:SetPos(v)
				e:Spawn()
				e:Activate()
				e:SetColor(Color(255,255,255,1))
				e:EmitSound(Sound("weapons/n1_cannon.wav"))
				local phys = e:GetPhysicsObject()
				phys:SetMass(100)
				phys:EnableGravity(gravity)
				phys:SetVelocity(self:GetAngles():Forward()*(2000*vel))
			end
			self:ResetSequence(self:LookupSequence("shoot_big"))
			self.NextUse.FireBlast = CurTime() + 5
		end
	end

	function ENT:Enter(p,driver)
		self.BaseClass.Enter(self, p, driver)
		self:SetSkin(2)
		if self:GetSequence() == self:LookupSequence("TopOpen") then
			self:ResetSequence(self:LookupSequence("TopClose"))
		end
	end

	function ENT:Exit(driver,kill)
		self:SetSkin(1)
		self.BaseClass.Exit(self, driver,kill)
		self.TrackL:SetPlaybackRate(0)
		self.TrackR:SetPlaybackRate(0)
		self:ResetSequence(self:LookupSequence("TopOpen"))
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
	
	function ENT:RunTraces()
		self.FrontTrace = util.TraceLine({
			start = self.FrontPos,
			endpos = self.FrontPos + self:GetUp()*-10000,
			filter = function(ent) return !ent:IsPlayer() end,
			mask = MASK_SOLID,
		})
		
		self.BackTrace = util.TraceLine({
			start = self.BackPos,
			endpos = self.BackPos + self:GetUp()*-10000,
			filter = function(ent) return !ent:IsPlayer() end,
			mask = MASK_SOLID,		
		})
		
		self.MiddleTrace = util.TraceLine({
			start = self.MiddlePos,
			endpos = self.MiddlePos + self:GetUp()*-10000,
			filter = function(ent) return !ent:IsPlayer() end,
			mask = MASK_SOLID,
		})
		-- self.BaseClass.RunTraces(self)
		-- remove WaterTrace so crawler can drive underwater
		-- instead of ontop like jebus
		self.WaterTrace = util.TraceLine({
		})
		
		-- we also introduce two more traces
		self.LeftTrace = util.TraceLine({
			start = self.LeftPos,
			endpos = self.LeftPos + self:GetUp() * -1000,
			filter = { self, self.Feet },
			mask = MASK_SOLID,
		})
		self.RightTrace = util.TraceLine({
			start = self.RightPos,
			endpos = self.RightPos + self:GetUp() * -1000,
			filter = { self, self.Feet },
			mask = MASK_SOLID,
		})
	end

	function ENT:PhysicsSimulate( phys, deltatime )
		self.BackPos = self:GetPos()+self:GetForward()*-self.backAmount+self:GetUp()*self.upAmount
		self.FrontPos = self:GetPos()+self:GetForward()*self.frontAmount+self:GetUp()*self.upAmount
		self.MiddlePos = self:GetPos()+self:GetUp()*self.upAmount
		self.LeftPos = self:GetPos()+self:GetRight()*-self.leftAmount+self:GetUp()*self.upAmount
		self.RightPos = self:GetPos()+self:GetRight()*self.rightAmount+self:GetUp()*self.upAmount
		if(self.Inflight) then
			local UP = ZAxis
			self.RightDir = self.Entity:GetRight()
			self.FWDDir = self.Entity:GetForward()
			
			self:RunTraces()
	
			-- vehicle shouldnt bank in when turning
			self.ExtraRoll = Angle(0,0,0)
			-- adjust vehicle angle to ground
			if(!self.WaterTrace.Hit) then
				-- Forward depending on main model!!!
				-- angling forwards/ backwards
				if(self.FrontTrace.HitPos.z >= self.BackTrace.HitPos.z) then
					self.PitchMod = Angle(math.Clamp((self.BackTrace.HitPos.z - self.FrontTrace.HitPos.z),-45,45)/2, 0, 0)
				else
					self.PitchMod = Angle(math.Clamp(-(self.FrontTrace.HitPos.z - self.BackTrace.HitPos.z),-45,45)/2, 0, 0)
				end
				-- angling sideways left/ right
				if(self.RightTrace.HitPos.z >= self.LeftTrace.HitPos.z) then
					self.PitchMod = Angle(self.PitchMod.x,self.PitchMod.y,math.Clamp((self.LeftTrace.HitPos.z - self.RightTrace.HitPos.z),-45,45)/2)
				else
					self.PitchMod = Angle(self.PitchMod.x,self.PitchMod.y,math.Clamp(-(self.RightTrace.HitPos.z - self.LeftTrace.HitPos.z),-45,45)/2)
				end
			end
		end
		self.BaseClass.PhysicsSimulate(self,phys,deltatime)
	end

	function ENT:Rotorwash(b)
		-- Disabled Dust around vehicle
	end
end

if CLIENT then
	ENT.Sounds={
		Engine=Sound("kingpommes/starwars/tie/crawler_idle.wav"),
	}
	
	local Health = 0
	function ENT:Think()
		self.BaseClass.Think(self)
		local p = LocalPlayer()
		local Flying = p:GetNWBool("Flying"..self.Vehicle)
		if(Flying) then
			Health = self:GetNWInt("Health")
		end
		
	end
    ENT.HasCustomCalcView = true
	local View = {}
	function CalcView()
		
		local p = LocalPlayer()
		local self = p:GetNWEntity("CRAWLER", NULL)
		local DriverSeat = p:GetNWEntity("DriverSeat",NULL)

		if(IsValid(self)) then

			if(IsValid(DriverSeat)) then
				if(DriverSeat:GetThirdPersonMode()) then
					local pos = self:GetPos()+self:GetForward()*-300+self:GetUp()*240
					local face = ((self:GetPos() + Vector(0,0,100))- pos):Angle()
					--local face = self:GetAngles()
						View.origin = pos
						View.angles = face
					return View
				end
			end

		end
	end
	hook.Add("CalcView", "CRAWLERView", CalcView)

	
	hook.Add( "ShouldDrawLocalPlayer", "CRAWLERDrawPlayerModel", function( p )
		local self = p:GetNWEntity("CRAWLER", NULL)
		local DriverSeat = p:GetNWEntity("DriverSeat",NULL)
		local PassengerSeat = p:GetNWEntity("PassengerSeat",NULL)
		if(IsValid(self)) then
			if(IsValid(DriverSeat)) then
				if(DriverSeat:GetThirdPersonMode()) then
					return true
				end
			elseif(IsValid(PassengerSeat)) then
				if(PassengerSeat:GetThirdPersonMode()) then
					return true
				end
			end
		end
	end)
	
	function CRAWLERReticle()
	
		local p = LocalPlayer()
		local Flying = p:GetNWBool("FlyingCRAWLER")
		local self = p:GetNWEntity("CRAWLER")
		if(Flying and IsValid(self)) then
			local WeaponsPos = {self:GetPos()}
			
			SW_Speeder_Reticles(self,WeaponsPos)
			SW_Speeder_DrawHull(self.StartHealth)
			SW_Speeder_DrawSpeedometer()
		end
	end
	hook.Add("HUDPaint", "CRAWLERReticle", CRAWLERReticle)
end