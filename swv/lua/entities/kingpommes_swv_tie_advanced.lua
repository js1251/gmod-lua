
util.PrecacheModel( "models/KingPommes/starwars/tie/advanced.mdl" )
if (!util.IsValidModel( "models/KingPommes/starwars/tie/advanced.mdl" )) then return end

ENT.RenderGroup = RENDERGROUP_OPAQUE
ENT.Base = "fighter_base"
ENT.Type = "vehicle"

ENT.PrintName = "TIE/AD Advanced"
ENT.Author = "KingPommes"
ENT.Category = "Star Wars Vehicles: Empire"
ENT.AutomaticFrameAdvance = true
ENT.Spawnable = false
ENT.AdminSpawnable = false

ENT.EntModel = "models/KingPommes/starwars/tie/advanced.mdl"
ENT.Vehicle = "IMP_TIE_ADVANCED"
ENT.StartHealth = 3000
ENT.Allegiance = "Empire"
list.Set("SWVehicles", ENT.PrintName, ENT)
if SERVER then
	
	ENT.FireSound = Sound("weapons/tie_shoot.wav")
	ENT.NextUse = {Wings = CurTime(),Use = CurTime(),Fire = CurTime(),}
	
	
	AddCSLuaFile()
	function ENT:SpawnFunction(pl, tr)
		local e = ents.Create("kingpommes_swv_tie_advanced")
		e:SetPos(tr.HitPos + Vector(0,0,90))
		e:SetAngles(Angle(0,pl:GetAimVector():Angle().Yaw,0))
		e:Spawn()
		e:Activate()
		e:PrecacheGibs()
		return e
	end
	
	function ENT:Initialize()
	
		self:PrecacheGibs()
		self:SetNWInt("Health",self.StartHealth)
		
		self.WeaponLocations = {
			Right = self:GetPos()+self:GetUp()*-42+self:GetRight()*14+self:GetForward()*50,
			Left = self:GetPos()+self:GetUp()*-42+self:GetRight()*-14+self:GetForward()*50,
		}

		self.WeaponsTable = {}
		self.BoostSpeed = 2400
		self.ForwardSpeed = 2400
		self.UpSpeed = 500
		self.AccelSpeed = 9
		self.CanBack = true
		self.CanRoll = false
		self.CanStrafe = true
		self.HasWings = true
		self:SetSkin(0)
		
		self.Cooldown = 2
		self.Overheat = 0
		self.Overheated = false
		
		self.CanShoot = true
		self.Bullet = CreateBulletStructure(60,"green")
		self.FireDelay = 0.05
		self.AlternateFire = false
		--self.FireGroup = {"Left","Right"}
		
		self.ExitModifier = {x=0,y=-220,z=-30}
		
		self.HasLookaround = true
		self.LandOffset = Vector(0,0, 90)
		self.PilotVisible = true
		self.PilotPosition = Vector(0, -11, -25)
		self.PilotAnim = "drive_jeep"
		
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
		Engine=Sound("vehicles/tie/tie_fly3.wav"),
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
				self:GetPos()+self:GetForward()*-40+self:GetUp()*19.12+self:GetRight()*33.12,
				self:GetPos()+self:GetForward()*-40+self:GetUp()*19.12+self:GetRight()*-33.12,
				self:GetPos()+self:GetForward()*-40+self:GetUp()*-19.12+self:GetRight()*33.12,
				self:GetPos()+self:GetForward()*-40+self:GetUp()*-19.12+self:GetRight()*-33.12,
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


	function IMP_TIEFighterOfDoomReticle()
		local p = LocalPlayer()
		local Flying = p:GetNWBool("FlyingIMP_TIE_ADVANCED")
		local self = p:GetNWEntity("IMP_TIE_ADVANCED")
		
		

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
			SW_HUD_WingsIndicator("advanced",x,y)
		end
	end
	hook.Add("HUDPaint", "IMP_TIE_ADVANCEDReticle", IMP_TIEFighterOfDoomReticle)

	-- hook.Add("HUDPaint", "TestingAoroundMF", function()
		-- for k, entity in pairs(ents.GetAll()) do
			-- cam.Start3D()
				-- if entity.StartHealth then
			
					-- render.DrawLine(
						-- entity.LandTracePos or entity:GetPos(),
						-- entity:GetPos()+entity:GetUp()*-(entity.LandDistance or 300),
						-- Color(255, 0, 0, 255)
					-- )
					
					-- local tr = util.TraceLine({
						-- start = entity.LandTracePos or entity:GetPos(),
						-- endpos = entity:GetPos()+entity:GetUp()*-(entity.LandDistance or 300),
						-- filter = entity:GetChildEntities(),
					-- })
					
					-- render.DrawWireframeBox(tr.HitPos + (entity.LandOffset or Vector(0,0,0)), Angle(), Vector(-10, -10, -10), Vector(10, 10, 10), Color(0, 0, 255, 255))

					-- print("---")
					-- PrintTable(entity:GetChildEntities())
					-- print("...")
					-- print(tr.Entity)
					
					-- if(tr.HitWorld or (IsValid(tr.Entity) and tr.Entity:GetClass() == "prop_physics")) then
						-- render.DrawWireframeBox(tr.HitPos + (entity.LandOffset or Vector(0,0,0)), Angle(), Vector(-10, -10, -10), Vector(10, 10, 10), Color(0, 255, 255, 255))
					-- end
				-- end
			-- cam.End3D()
		-- end
	-- end)
end