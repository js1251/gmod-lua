
util.PrecacheModel( "models/KingPommes/starwars/patrol_transport/main.mdl" )
if (!util.IsValidModel( "models/KingPommes/starwars/patrol_transport/main.mdl" )) then return end

ENT.RenderGroup = RENDERGROUP_OPAQUE
ENT.Base = "fighter_base"
ENT.Type = "vehicle"
 
ENT.PrintName = "Imperial Patrol Transport"
ENT.Author = "KingPommes, Mattzi"
ENT.Category = "Star Wars Vehicles: Empire"
ENT.AutomaticFrameAdvance = true
ENT.Spawnable = false
ENT.AdminSpawnable = false
 
ENT.EntModel = "models/KingPommes/starwars/patrol_transport/main.mdl"
ENT.Vehicle = "IMP_PATROL"
ENT.StartHealth = 4500
ENT.Allegiance = "Empire"
list.Set("SWVehicles", ENT.PrintName, ENT)
if SERVER then
   
    ENT.FireSound = Sound("weapons/tie_shoot.wav")
   
    AddCSLuaFile()
    function ENT:SpawnFunction(pl, tr)
        local e = ents.Create("kingpommes_swv_patroltransport_imp")
        e:SetPos(tr.HitPos + Vector(0,0,2))
        e:SetAngles(Angle(0,pl:GetAimVector():Angle().Yaw,0))
        e:Spawn()
        e:Activate()
        e:PrecacheGibs()
        return e
    end
 
    function ENT:SpawnLauncher()
        local pos = self:GetPos()
        local ang1 = self:GetAngles()
        local ang2 = self:GetAngles() + Angle(90, 0, 0)
 
        local e = ents.Create("info_target")
        e:SetPos(pos)
        e:SetAngles(ang1)
        e:SetParent(self)
        e:Spawn()
        e:Fire("AddOutput", "targetname target", 0)
        self.Target = e
 
        local e1 = ents.Create("npc_launcher")
        e1:SetPos(pos)
        e1:SetAngles(ang2)
        e1:SetParent(self)
        e1:Spawn()
        e1:Activate()
        e1:Fire("SetEnemyEntity", "target")
        e1:Fire("AddOutput", "damage 1000")
        e1:Fire("AddOutput", "DamageRadius 300")
        --e1:Fire("AddOutput", "FlySound weapons/rpg/rocket1.wav")
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
   
    function ENT:SpawnTurrets()
        self.Turrets = {}
        for k,v in pairs(self.WeaponLocations) do
            local e = ents.Create("base_anim")
            e:SetModel("models/KingPommes/starwars/patrol_transport/turret.mdl")
            e:SetPos(v)
            e:SetParent(self)
            e:Spawn()
            e:Activate()
            self.Turrets[k] = e
        end
    end
 
    function ENT:SpawnDoors()
        local e = ents.Create("prop_dynamic")
        e:SetModel("models/KingPommes/starwars/patrol_transport/doors.mdl")
        e:SetPos(self:GetPos())
        e:SetAngles(self:GetAngles())
        e:SetParent(self)
        e:PhysicsInit(SOLID_VPHYSICS)
        e:Spawn()
        e:Activate()
        self.Doors = e
    end
   
    function ENT:SpawnSeats()
        self.Seats = {}
        for k,v in pairs(self.SeatPos) do
            local e = ents.Create(self.SeatClass or "prop_vehicle_prisoner_pod")
            e:SetPos(v[1] or self:GetPos())
            e:SetAngles(v[2] or self:GetAngles())
            e:SetParent(self)
            e:SetModel("models/nova/airboat_seat.mdl")
            e:SetRenderMode(RENDERMODE_TRANSALPHA)
            e:SetColor(Color(255,255,255,0))
            e:Spawn()
            e:Activate()
            e:SetUseType(USE_OFF)
            e:GetPhysicsObject():EnableMotion(false)
            e:GetPhysicsObject():EnableCollisions(false)
            e:SetCollisionGroup(COLLISION_GROUP_WEAPON)
            e._ExitPos = v[3] or Vector(0,0,0)
            e._ExitAngles = v[4] or Angle(0,180,0)
            if (k == "Gunner") then
                e:SetVehicleClass("phx_seat2")
                e:SetName("Gunner")
            else
                e:SetVehicleClass("pommes_patrol_seat")
                e:SetName("Passenger")
            end
            self.Seats[k] = e
        end
    end
   
    function ENT:Initialize()
        self.FireGroup = {"Laser1","Laser2"}
        self:SetModel(self.EntModel);
 
        self.WeaponLocations = {
            self:GetAttachment(self:LookupAttachment("turret_L")).Pos,
            self:GetAttachment(self:LookupAttachment("turret_R")).Pos,
        }
 
        self.Flashlights = {
        {Vector(174,0,15),Angle(90,0,0)},
        }
 
        self.HasFlashlight = false;
        self.FlashlightDistance = 4000;
       
        self:SetNWInt("Health",self.StartHealth)
       
        self.CanShoot = false
        self.Cooldown = 2
        self.Overheat = 0
        self.Overheated = false
        self.Bullet = CreateBulletStructure(60,"green")
        self.FireDelay = 0.05
        self.AlternateFire = true
 
        self.WeaponsTable = {}
       
        self.Gunner = nil
        self.BoostSpeed = 1500
        self.ForwardSpeed = 600
        self.UpSpeed = 500
        self.AccelSpeed = 12
        self.CanBack = true
        self.CanRoll = false
        self.CanStrafe = true
        self.HasWings = true
        self.CanEject = false       
       
        self:SetSkin(0)
        self.rocketnum = 1
        self.al = 1
       
        self.ExitModifier = {x=0,y=250,z=4}
        self.LandOffset = Vector(0,0, 1)
 
		self.PilotPosition =  Vector(0,102,87)
        self.PilotVisible = true
        self.PilotAnim = "drive_jeep"
        self.HasLookaround = true
       
        self.HasSeats = true
        self.SeatPos = {
            Gunner = {self:GetPos()+self:GetForward()*145+self:GetRight()*1+self:GetUp()*39,self:GetAngles()+Angle(0,-90,0),Vector(0,95,4)},

            {self:GetPos()+self:GetForward()*26+self:GetRight()*16+self:GetUp()*26,self:GetAngles()+Angle(0,180,0),Vector(0,95,4)},
            {self:GetPos()+self:GetForward()*26+self:GetRight()*-16+self:GetUp()*26,self:GetAngles()+Angle(0,0,0),Vector(0,95,4)},
            {self:GetPos()+self:GetForward()*-6+self:GetRight()*16+self:GetUp()*26,self:GetAngles()+Angle(0,180,0),Vector(0,95,4)},
            {self:GetPos()+self:GetForward()*-6+self:GetRight()*-16+self:GetUp()*26,self:GetAngles()+Angle(0,0,0),Vector(0,95,4)},
            {self:GetPos()+self:GetForward()*-38+self:GetRight()*16+self:GetUp()*26,self:GetAngles()+Angle(0,180,0),Vector(0,95,4)},
            {self:GetPos()+self:GetForward()*-38+self:GetRight()*-16+self:GetUp()*26,self:GetAngles()+Angle(0,0,0),Vector(0,95,4)},
            {self:GetPos()+self:GetForward()*58+self:GetRight()*16+self:GetUp()*26,self:GetAngles()+Angle(0,90,0),Vector(-95,0,4), Angle(0,90,0)},
            {self:GetPos()+self:GetForward()*58+self:GetRight()*-16+self:GetUp()*26,self:GetAngles()+Angle(0,90,0),Vector(95,0,4), Angle(0,90,0)},
        }
		
		self.NextUse.ToogleSirens = CurTime()
        self.NextUse.FireRockets = CurTime()
        self.NextUse.ToogleDoors = CurTime()
        self:SpawnLauncher()
        self.BaseClass.Initialize(self)

        self.Filter = {self:GetChildEntities()}

        self:SpawnDoors()
        self:SpawnTurrets()

        self.Turrets[1]:Fire( "SetParentAttachment", "turret_L")
        self.Turrets[2]:Fire( "SetParentAttachment", "turret_R")

        self.Seats["Gunner"]:Fire( "Addoutput", "limitview 0")

        self.Doors:ResetSequence(self.Doors:LookupSequence("DoorsOpen"))
        self.Doors:SetSolid(SOLID_NONE)
        self:SetNWEntity("IMP_PATROL_DOORS", self.Doors)
    end

    function ENT:Think()
        self:NextThink(CurTime())
        if(self.Inflight) then
            if IsValid(self.Pilot) then
				if(self.Pilot:KeyDown(IN_ATTACK2)) then
					self:FireLauncher()
				elseif(!IsValid(self.Gunner) and self.Pilot:KeyDown(IN_ATTACK)) then
					self:FireWeapons(self:GetPos() +  self:GetAngles():Forward()*100000)
				elseif(self.Pilot:KeyDown(IN_RELOAD)) then
					self:ToggleSiren()
				end
            end
            if (IsValid(self.Gunner)) then
                if IsValid(self.Gunner) and self.Gunner:KeyDown(IN_ATTACK) then
                    self:FireWeapons()
                end
                if IsValid(self.Gunner) and self.Gunner:KeyDown(IN_ATTACK2) then
                    if(self.FlashlightOn) then
						self.Doors:SetSkin(0)
                        self.BaseClass.RemoveFlashlight(self)
						self:EmitSound("buttons/lightswitch2.wav")
                        --self:SetNWEntity("IMPPATROL_Flashlight", NULL)
                    else
						self.Doors:SetSkin(1)
                        self.BaseClass.CreateFlashlight(self)
                        self.Flashlight[1]:SetParent(self.Doors)
						self:EmitSound("buttons/lightswitch2.wav")
                        --self:SetNWEntity("IMPPATROL_Flashlight", self.Flashlight[1])
                        self.Flashlight[1]:Fire("SetParentAttachment", "spotlight")
                    end
                end
            end
           
            if(self.Land) then
                self:ToggleDoors(true)
            end
           
            if(self.Wings) then
                self:ToggleDoors(false)
            elseif(!self.Wings) then
                self:ToggleDoors(true)
            end
 
            self:NextThink(CurTime())
        end
        self.BaseClass.Think(self)
    end
   
    function ENT:GetChildEntities()
        return self
    end
   
    function ENT:Passenger(p)
        if(self.NextUse.Use > CurTime()) then return end;
        for k,v in pairs(self.Seats) do
            if v:GetPassenger(1) == NULL and k ~= "Gunner" then
                p:EnterVehicle(v)
                return
            end
        end
    end
 
    function ENT:EnterGunner(p)
        if not self.Pilot then self:SetSkin(1) self.BaseClass.Enter(self, p) return end
        if self.Gunner == p then return end
        if(self.NextUse.Use > CurTime()) then return end
        for k,v in pairs(self.Seats) do
            if v:GetPassenger(1) == NULL and k == "Gunner" then
                p:EnterVehicle(v)
                p:CrosshairEnable()
                return       
            end
        end
    end
   
    function ENT:Use(p)
        if(not self.Inflight) then
            if !p:KeyDown(IN_WALK) then
                self:EnterGunner(p)
            elseif p ~= self.Pilot and p ~= self.Gunner then
                self:Passenger(p)
            end
        else
            if(!p:KeyDown(IN_WALK)) then
                self:EnterGunner(p)
            elseif p ~= self.Pilot and p ~= self.Gunner then
                self:Passenger(p)
            end
        end
    end
   
    function ENT:Exit(kill)
        if not IsValid(self) then return end
        self.BaseClass.Exit(self,kill)
       
        self:ToggleDoors(true)
        self:SetSkin(0)
		self:StopSound("siren")
        if self.Gunner then
            local p = self.Gunner
            self:GunnerLeftVehicle(self.Gunner, self.Gunner:GetVehicle())
            p:ExitVehicle()
            self:SetSkin(1)
            timer.Simple(0, function()
                self.BaseClass.Enter(self, p)
            end)
        end
        self.Pilot = nil
    end
   
    function ENT:Bang()
        self.BaseClass.Bang(self)
        self:GibBreakClient(self:GetVelocity())
		self:StopSound("siren")
        self:Remove()
    end
   
    function ENT:ToggleDoors(bol)
        if(self.NextUse.ToogleDoors < CurTime()) then
       
            if (bol and self.Doors:GetSequence() ~= self.Doors:LookupSequence("DoorsOpen")) then
                self:ResetSequence(self:LookupSequence("WingClose"))
                self.Doors:ResetSequence(self.Doors:LookupSequence("DoorsOpen"))
                self.Doors:SetSolid(SOLID_NONE)
                self.NextUse.ToogleDoors = CurTime()+2
               
            elseif (!bol and self.Doors:GetSequence() ~= self.Doors:LookupSequence("DoorsClose")) then
                self:ResetSequence(self:LookupSequence("WingOpen"))
                self.Doors:ResetSequence(self.Doors:LookupSequence("DoorsClose"))
                self.Doors:SetSolid(SOLID_VPHYSICS)
                self.NextUse.ToogleDoors = CurTime()+2
            end
        end
    end
   
	sound.Add( {
		name = "siren",
		channel = CHAN_STATIC,
		volume = 1.0,
		level = 80,
		pitch = 100,
		sound = "KingPommes/starwars/patrol/siren.wav"
	} )
   
    function ENT:ToggleSiren()
        if self.NextUse.ToogleSirens < CurTime()  then
            if self:GetSkin() == 1 then
                self:SetSkin(2)
				self:EmitSound("siren")
            elseif self:GetSkin() == 2 then
                self:SetSkin(1)
				self:StopSound("siren")
            end
        self.NextUse.ToogleSirens = CurTime()+1
        end
    end
   
    function ENT:FireLauncher()
        if(self.NextUse.FireRockets < CurTime()) then
            if (self.rocketnum % 2 == 1) then
                self.Launcher:SetPos(self:GetPos() + self:GetForward()*250 + self:GetUp()*50 + self:GetRight()*32)
                self.Launcher:Fire("FireOnce")
                self.rocketnum = self.rocketnum + 1
            elseif (self.rocketnum %2 == 0) then
                self.Launcher:SetPos(self:GetPos() + self:GetForward()*250 + self:GetUp()*50 + self:GetRight()*-32)
                self.Launcher:Fire("FireOnce")
                self.rocketnum = self.rocketnum + 1
            end
            if (self.rocketnum == 6) then
                self.rocketnum = 0
                self.NextUse.FireRockets = CurTime()+15
                self:SetNWInt("FireBlast",self.NextUse.FireRockets)
            end
        end
    end
 
    function ENT:FireWeapons()
        if(self.NextUse.Fire < CurTime()) then
        local aim
        if IsValid(self.Gunner) then
            --aim = self.Gunner:EyeAngles()
            --aim = self:WorldToLocalAngles(self.Gunner:GetAimVector():Angle())
            aim = self.Gunner:GetAimVector():Angle()
        end
            for k,v in pairs(self.Weapons) do
                if(!IsValid(v)) then return end;
                local tr
                if IsValid(self.Gunner) then
                    tr = util.TraceLine({
                        start = v:GetPos(),
                        --endpos = self.Gunner:GetPos() + Angle(math.Clamp(aim.x,-15,90),math.Clamp(aim.y,-68,68),0):Forward() * 100000,
                        endpos = self.Gunner:GetPos() + Angle(aim.x,aim.y):Forward() * 100000,
                        filter = {self,self.Gunner},
                    })
                elseif IsValid(self.Pilot) then
                    tr = util.TraceLine({
                        start = v:GetPos(),
                        endpos = self:GetPos()+self:GetForward()*10000,
                        filter = {self},
                    })                    
                end
                local angPos = (tr.HitPos - v:GetPos())
               
                if(self.ShouldLock) then
                    local e = self:FindTarget();
                    if(IsValid(e)) then
                        local tr = util.TraceLine( {
                            start = v:GetPos(),
                            endpos = e:GetPos(),
                            filter = {self, v},
                        } )
                        if(!tr.HitWorld) then
                            angPos = (e:GetPos() + e:GetUp()*(e:GetModelRadius()/3) + (self.LockOnOverride or Vector(0,0,0))) - v:GetPos();
                        end
                    end
                end
               
                self.Bullet.Attacker = self.Gunner or self.Pilot or self;
                self.Bullet.Src     = v:GetPos();
                local spread = self.Accel.FWD/1000;
                self.Bullet.Spread = Vector(spread,spread,spread);
                self.Bullet.IgnoreEntity = self, v
   
                self.Bullet.Dir = angPos
               
                if(self.AlternateFire) then
                    if (self.al == 1 and (v == self.Weapons[1])) then
                        v:FireBullets(self.Bullet)
                    elseif (self.al == 2 and (v == self.Weapons[2])) then
                        v:FireBullets(self.Bullet)
                    end
                else
                    v:FireBullets(self.Bullet)
                end
            end
            self.al = self.al + 1
            if(self.al == 3) then
                self.al = 1
            end
            self:EmitSound(self.FireSound,100,math.random(90,110))
            self.NextUse.Fire = CurTime() + (self.FireDelay)
        end
    end
 
    hook.Add("CanPlayerEnterVehicle", "PatrolTransport.PreventEnter", function(p,v)
        if(IsValid(p) and IsValid(v)) then
            local e = v:GetParent();
            if e.IsSWVehicle and e:GetClass() == "kingpommes_swv_patroltransport_imp" then
                if p == e.Gunner or p == e.Pilot then return false end
                return
            end
        end
    end)
 
    hook.Add("PlayerEnteredVehicle","PatrolTransport.GunnerEnterVehicle", function(p,v)
        if(IsValid(p) and IsValid(v)) then
            local e = v:GetParent();
            if e.IsSWVehicle and e:GetClass() == "kingpommes_swv_patroltransport_imp" and v:GetName() == "Gunner" then
                e.Gunner = p
                e:SetNWEntity("IMP_PATROL_GUNNER",p)
                p:SetNWEntity("IMP_PATROL", e)
                p:SetNWBool("GunnerIMP_Patrol", true)
                p:SetNWVector("Weapon1IMP_Patrol", e.WeaponLocations[1])
                p:SetNWVector("Weapon2IMP_Patrol", e.WeaponLocations[2])
            end
        end
    end)
	
	function ENT:GunnerLeftVehicle(p, v)
        if(IsValid(p) and IsValid(v)) then
            local e = v:GetParent();
            if e.IsSWVehicle and e:GetClass() == "kingpommes_swv_patroltransport_imp" then
                e.Gunner = nil
                e:SetNWEntity("IMP_PATROL_GUNNER", NULL)
                p:SetNWEntity("IMP_PATROL", nil)
                p:SetNWBool("GunnerIMP_Patrol", false)
                if v then
                    local pos = v:LocalToWorld(v._ExitPos)
                    p:SetPos(pos);
                end
            end
        end
    end

    hook.Add("PlayerLeaveVehicle", "PatrolTransport.GunnerLeaveVehicle", function(p, v)
        if(IsValid(p) and IsValid(v)) then
            local e = v:GetParent()
            if e.IsSWVehicle and e:GetClass() == "kingpommes_swv_patroltransport_imp" and v:GetName() == "Gunner" then
                e.Gunner = nil
                e:SetNWEntity("IMP_PATROL_GUNNER", NULL)
                p:SetNWEntity("IMP_PATROL", nil)
                p:SetNWBool("GunnerIMP_Patrol", false)
                local pos = v:LocalToWorld(v._ExitPos)
                p:SetPos(pos)
                if(e.FlashlightOn) then
				    e.Doors:SetSkin(0)
                    e.BaseClass.RemoveFlashlight(e)
					--e:EmitSound("items\flashlight1.wav")
                    --e:SetNWEntity("IMPPATROL_Flashlight", e)
                --else
				--	print("test")
				--	e.Doors:SetSkin(1)
                --    e.BaseClass.CreateFlashlight(e)
                --    e.Flashlight[1]:SetParent(e.Doors)
                --    e:SetNWEntity("IMPPATROL_Flashlight", e.Flashlight[1])
                --    e.Flashlight[1]:Fire("SetParentAttachment", "spotlight")
                end
            elseif e.IsSWVehicle and e:GetClass() == "kingpommes_swv_patroltransport_imp" and v:GetName() == "Passenger" then
                local pos = v:LocalToWorld(v._ExitPos)
                p:SetPos(pos)
                p:SetEyeAngles(v._ExitAngles)
            end
        end
    end)
       
end
 
 
 
if CLIENT then
 
    function ENT:Draw() self:DrawModel() end
 
    ENT.Sounds={
        Engine=Sound("vehicles/laat/laat_fly2.wav"),
    }
    ENT.CanFPV = true
	
	ENT.SpritePos = {}
 
    local Health = 0
    function ENT:Think()
        self.BaseClass.Think(self)

		--self:SetRenderBoundsWS(Vector(-9999999, -9999999, -9999999),Vector(9999999, 9999999, 9999999))
		
		local p = LocalPlayer()
        local IsDriver = p:GetNWEntity(self.Vehicle) == self.Entity
        local IsFlying = p:GetNWBool("Flying"..self.Vehicle)
		
		if(IsFlying and IsDriver) then
            Health = self:GetNWInt("Health")
        end     
 
        self.Gunner = self:GetNWEntity("IMP_PATROL_GUNNER")
        self.Doors = self:GetNWEntity("IMP_PATROL_DOORS")
		
        -- Dafuck, I need to do this because the Guns are always looking in one Direction when you are using global angles and are not the Localplayer
        -- If you use local angles its right for others but for the Localplayer its broken
		
        if IsValid(self.Gunner) and self.Gunner == LocalPlayer() then
            local aim = self.Gunner:EyeAngles()
            local x = math.Clamp(aim.x,-15,90)
            local y = math.Clamp(aim.y,22,158)
 
			self:ManipulateBoneAngles(self:LookupBone("turret_L"), Angle(0,-y + 90,x))
			self:ManipulateBoneAngles(self:LookupBone("turret_R"), Angle(0,-y + 90,x))
            if not IsValid(self.Doors) then return end
            self.Doors:ManipulateBoneAngles(self.Doors:LookupBone("spotlight"), Angle(0,-aim.x + 90,-aim.y + 90))
           
        elseif IsValid(self.Gunner) and self.Gunner ~= LocalPlayer() then
            local aim = self:WorldToLocalAngles(self.Gunner:EyeAngles())
			local x = math.Clamp(aim.x,-15,90)
            local y = math.Clamp(aim.y,-68,68)
 
            self:ManipulateBoneAngles(self:LookupBone("turret_L"), Angle(0,-y,x))
            self:ManipulateBoneAngles(self:LookupBone("turret_R"), Angle(0,-y,x))
 
            if not IsValid(self.Doors) then return end
            self.Doors:ManipulateBoneAngles(self.Doors:LookupBone("spotlight"), Angle(0,-aim.x + 90,-aim.y ))
           
        else
            self:ManipulateBoneAngles(self:LookupBone("turret_L"), Angle(0,0,0))
            self:ManipulateBoneAngles(self:LookupBone("turret_R"), Angle(0,0,0))
            if not IsValid(self.Doors) then return end
            self.Doors:ManipulateBoneAngles(self.Doors:LookupBone("spotlight"), Angle(0,0,0))
        end
    end
	
	ENT.ViewDistance = 700
	ENT.ViewHeight = 300
	ENT.FPVPos = Vector(115,0,121)
	ENT.HasCustomCalcView = true
	hook.Add("CalcVehicleView", "ImpPatrol.CalcVehicleView", function(veh, p, view)
		local e = LocalPlayer():GetVehicle()
		local Piloting = p:GetViewEntity() != p and p:GetViewEntity().IsSWVehicle;
		if IsValid(e) and e:GetParent().IsSWVehicle and e:GetParent():GetClass() == "kingpommes_swv_patroltransport_imp" then
			if p:GetNWBool("GunnerIMP_Patrol") and e:GetThirdPersonMode() then
                local view = {}
				view.origin = e:LocalToWorld(Vector(0,5,-30))
				view.angles = angles
				view.fov = fov
				view.drawviewer = true
				return view
			elseif not e:GetThirdPersonMode() and not p:GetNWBool("GunnerIMP_Patrol") then
                --Player View Height
				view.origin = view.origin + Vector(0,0, 40)
			elseif not p:GetNWBool("GunnerIMP_Patrol") then
                --Third Person View Height
                view.origin = view.origin + Vector(0,0, 40)
            end
		end
	end)

	hook.Add("CalcView", "ImpPatrol.CalcView", function(p, origin, ang)
		local view = {}
		local e = LocalPlayer():GetVehicle()
		local Piloting = p:GetViewEntity() != p and p:GetViewEntity().IsSWVehicle;
		if Piloting and p:GetViewEntity():GetClass() == "kingpommes_swv_patroltransport_imp" then
			self = p:GetViewEntity();
			local pos = self:LocalToWorld(self.FPVPos or Vector(0,0,0));
			View = SWVehicleView(self,self.ViewDistance or 800,self.ViewHeight or 250,pos,self:GetNWBool("HasLookaround"))
			return View;
		end
	end)
	
	
	--TESTING RENDERBOUNDS
	
	--hook.Add("HUDPaint", "TestingAoroundMF", function()
	--	for k, v in pairs(ents.GetAll()) do
	--		if v:GetClass() == "kingpommes_swv_patroltransport_imp" then
	--			local vec1, vec2 = v:GetRenderBounds()
	--			cam.Start3D()
	--				render.DrawWireframeBox(v:GetPos(), Angle(), vec1, vec2, Color(0, 0, 255, 255))
	--			cam.End3D()
	--		end
	--	end
	--end)
	
	

	function IMP_PATROLOfDoomReticle()
		local p = LocalPlayer()
		local Flying = p:GetNWBool("FlyingIMP_PATROL")
		local self = p:GetNWEntity("IMP_PATROL")
		local Gunner = p:GetNWBool("GunnerIMP_Patrol")
		local Weapon1 = p:GetNWVector("Weapon1IMP_PATROL")
		local Weapon2 = p:GetNWVector("Weapon2IMP_PATROL")

		if Flying and IsValid(self) then
			local x = ScrW()/4*0.1
			local y = ScrH()/4*2.5
			if(self:GetFPV()) then         
			end
			SW_HUD_DrawHull(self.StartHealth)
			SW_WeaponReticles(self)
			--SW_HUD_DrawOverheating(self)
			local pos = self:GetPos()+self:GetForward()*100+self:GetUp()*-45+self:GetRight()*0
			local x,y = SW_XYIn3D(pos)
			SW_HUD_Compass(self,x,y)
			SW_HUD_DrawSpeedometer()
			SW_HUD_WingsIndicator("patrol",x,y)
			SW_BlastIcon(self,15)
		end
	end
	hook.Add("HUDPaint", "IMP_PATROLReticle", IMP_PATROLOfDoomReticle)
end