------------------------------------
------ Created by Jakob Sailer -----
------ LFS Base by blu / Luna ------
----------- DO NOT edit or ---------
------------ reupload!! ------------
------------------------------------
util.PrecacheModel("models/kingpommes/starwars/atat/atat_legs.mdl")
if (not util.IsValidModel("models/kingpommes/starwars/atat/atat_legs.mdl")) then return end
AddCSLuaFile("shared.lua")
AddCSLuaFile("cl_init.lua")
include("shared.lua")

------------------ DONE: walking backwards
------------------ DONE: health below ragdoll threashold
------------------ DONE: ragdoll death?
------------------ WONT: how to get in? --people need to build structures etc
------------------ DONE: thrid person camera clipping
------------------ DONE: ghost movement when no driver active
------------------ DONE: motion-enable when stood still but shooting the main guns (recoil)
------------------ DONE: blastdoors exterior
------------------ DONE: blastdoors interior
------------------ WONT: cargo parenting room? --> only parent things that do not have a parent themselfes -- meh...
------------------ DONE: commander seat model and type
------------------ DONE: fix seat switchen from head
------------------ DONE: add commander seat to seat switching list
------------------ DONE: investigate local gravity support
-- TODO: fix all the scattered around TODOs
------------------ DONE: move dismount attachments away from the wall a little
------------------ DONE: Head and Torso not solid to other ships and rockets etc --> use betterWeld function instead of parent --> fix anything relying on parenting
------------------ DONE: Some passenger seats lower cannot be entered
------------------ DONE: improve inconsistent foot damage
------------------ DONE: secondary turrets disabled when primary ammo is empty
------------------ DONE: Playermodel appears miles away when switching seats (bcs of leavevehicle hook)
------------------ DONE: passenger seat animations
------------------ CANT: eyeangles to model wrong in some seats (passengers, commander) --> bcs LFS is fucked >:( --> parent to torso instead to fix...
------------------ DONE: rotated spawning would be nice?
------------------ DONE: faster turn rate when walking faster
------------------ DONE: dissapearing head model ugh
------------------ DONE: floaty physics
------------------ DONE: more consistent falling over
------------------ DONE: exit mod when ATAT fell over
-- TODO: overly agressive head bobbing when in freelook
------------------ DONE: headbobbing disable when falling over
------------------ WONT: angle vehicle to reach where poseparams cant -- too much additionaly stuff needs to be done for this. not worth it
------------------ DONE: turn anim sounds
------------------ DONE: ATAT turns when no driver active sometimes
------------------ DONE: Head still adjustst even if the ATAT is falling over
------------------ DONE: turn while walking pose parameter
------------------ DONE: third person for commander
------------------ WONT: move commander eyepos down a little -- its already in his chest
------------------ DONE: move gunner/ driver eyepos down a little
------------------ DONE: body bobbing
------------------ DONE: head spazzing ugh wtf glua is the worst language Ive coded in by a long shot
------------------ DONE: better lod for interior (railings and such, closed hatch for upper level)
------------------ DONE: parent passenger seats to body instead of self (for closer anim alignment)
------------------ DONE: add attachment points to the body for doors etc
------------------ DONE: lod for z fighting parts at greater distances
------------------ DONE: footcollider should not collide with the world
------------------ DONE: physhandle should not be visible / collidable
------------------ DONE: add texture to commander seat / self nomesh to allow it to be invisible
------------------ DONE: fix broken af ballsocket of head in ragdoll mode -- gmod sucks again
------------------ KNDA: floaty ragdoll when falling over sideways
-- TODO: add reverse animation to avoid animation event bugs
------------------ DONE: add animation fading
------------------ DONE: seat texture
------------------ DONE: [lfsports] addons/lfsports/lua/entities/kingpommes_lfs_atat_footcollider.lua:25: attempt to compare number with nil
------------------       1. unknown - addons/lfsports/lua/entities/kingpommes_lfs_atat_footcollider.lua:25 (x2)
------------------ DONE: backwards turning is fucked
------------------ DONE: [lfsports] addons/lfsports/lua/entities/kingpommes_lfs_atat_head.lua:156: attempt to call method 'ShootCannon' (a nil value)
------------------       1. unknown - addons/lfsports/lua/entities/kingpommes_lfs_atat_head.lua:156
------------------ DONE: [lfsports] addons/lfsports/lua/entities/kingpommes_lfs_atat/shared.lua:142: attempt to call method 'GetHeadEnt' (a nil value)
------------------       1. unknown - addons/lfsports/lua/entities/kingpommes_lfs_atat/shared.lua:142
--TODO: fallover alarm
------------------ DONE: bottom chute blastdoor
------------------ DONE: top hatch blastdoor
------------------ DONE: ladder mesh is hovering away from the main mesh
------------------ DONE: blastdoor sounds
--TODO: blastdoor collider offsets when ragdoll
------------------ DONE: weird shivering when walking / turning. especially when throwing with physgun
function ENT:SpawnFunction(ply, tr, ClassName)
	if not tr.Hit then return end
	local ent = ents.Create(ClassName)
	ent.dOwnerEntLFS = ply
	ent:SetPos(tr.HitPos + tr.HitNormal + Vector(0, 0, 512))
	local angles = ply:GetAngles()
	angles.z = 0
	angles.x = 0
	ent:SetAngles(angles)
	ent:Spawn()
	ent:Activate()

	return ent
end

function ENT:CreateAttachmentEnt(attachmentName)
	local attachmentPos = self:GetAttachment(self:LookupAttachment(attachmentName))
	if not istable(attachmentPos) then return end
	local attachment = ents.Create("prop_dynamic")
	attachment:SetModel("models/hunter/blocks/cube025x025x025.mdl")
	attachment:SetParent(self)
	attachment:SetPos(attachmentPos.Pos)
	attachment:SetRenderMode(RENDERMODE_TRANSALPHA)
	attachment:SetColor(Color(0, 0, 0, 0))
	attachment:DrawShadow(false)
	attachment:Fire("SetParentAttachment", attachmentName)
	attachment:Spawn()
	attachment:Activate()
	attachment.DoNotDuplicate = true
	self:dOwner(attachment)
	self:DeleteOnRemove(attachment)

	return attachment
end

function ENT:Initialize()
	timer.Simple(0, function()
		-- create a new entity
		self:InitializeModel()
		-- create driver seat
		self:InitPod()
		self:AdjustPod()
		-- activate vehicle
		self:RunOnSpawn()
		self:InitWheels()
		self.pitch = 0
		self.roll = 0
		self.GetRearEnt = nil
	end)
end

function ENT:AdjustPod()
	local Pod = self:GetDriverSeat()
	Pod:SetParent(nil)
	Pod:SetModel("models/kingpommes/starwars/atat/seat_driver.mdl")
	Pod:SetVehicleClass("phx_seat3")
	Pod:SetColor(Color(255, 255, 255, 255))
	Pod:SetParent(self.Head)
	Pod:Fire("SetParentAttachment", "seat.driver")
end

function ENT:InitializeModel()
	self:InitializeLegs()
	self:InitializeTorso()
	self:InitializeHead()
	self:InitializeColliders()
end

function ENT:InitializeLegs()
	self:SetModel(self.MDL)
	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_VPHYSICS)
	self:SetSolid(SOLID_VPHYSICS)
	self:SetUseType(SIMPLE_USE)
	self:SetRenderMode(RENDERMODE_TRANSALPHA)
	self:AddFlags(FL_OBJECT)
	self.DoNotDuplicate = true
	local PObj = self:GetPhysicsObject()

	if not IsValid(PObj) then
		self:Remove()
		print("LFS: missing model. Plane terminated.")

		return
	end

	PObj:EnableMotion(false)
	PObj:SetMass(self.Mass)
	PObj:SetDragCoefficient(self.Drag)
	self.LFSInertiaDefault = PObj:GetInertia()
	self.Inertia = self.LFSInertiaDefault
	PObj:SetInertia(self.Inertia)
end

function ENT:InitializeTorso()
	local ent = ents.Create("kingpommes_lfs_atat_torso")
	local attachment = self:GetAttachment(self:LookupAttachment("attach.torso"))

	if not istable(attachment) then
		self:Remove()

		return
	end

	ent:SetPos(attachment.Pos)
	ent:SetAngles(attachment.Ang)
	ent:Spawn()
	ent:Activate()
	ent:SetParent(self)
	ent:Fire("SetParentAttachment", "attach.torso")
	ent:DeleteOnRemove(self)
	self:DeleteOnRemove(ent)
	--ent:SetBaseEnt(self)
	self:dOwner(ent)
	self.Torso = ent
	self:SetTorsoEnt(ent)
	ent.ATTEBaseEnt = self
end

function ENT:InitializeHead()
	local Attachment = self:GetAttachment(self:LookupAttachment("attach.head"))
	if not istable(Attachment) then return end
	local ent = ents.Create("kingpommes_lfs_atat_head")
	ent:SetPos(Attachment.Pos)
	ent:SetAngles(Attachment.Ang)
	ent:Spawn()
	ent:Activate()
	-- x: roll, y: pitch, z: yaw
	local min = Angle(-20, -30, -45)
	local max = Angle(20, 30, 45)
	self.headsocket = constraint.AdvBallsocket(self, ent, 0, 0, self:WorldToLocal(Attachment.Pos), Vector(0, 0, 0), 0, 0, min.x, min.y, min.z, max.x, max.y, max.z, 0, 0, 0, 0, 1)
	local phys = ent:GetPhysicsObject()
	if not IsValid(phys) then return end
	phys:EnableGravity(false)
	phys:SetMass(1)
	self:DeleteOnRemove(ent)
	self:dOwner(ent)
	self.Head = ent
	self:SetHeadEnt(ent)
	ent:SetBaseEnt(self)
	ent.ATTEBaseEnt = self -- leaving this in bcs of functions in baseclass
	ent:SetLightingOriginEntity(self.Torso)
end

function ENT:InitializeColliders()
	local FeetAttachments = {
		rl = "attach.rear.L",
		rr = "attach.rear.R",
		fl = "attach.front.L",
		fr = "attach.front.R"
	}

	self.footCollider = {}

	for k, v in pairs(FeetAttachments) do
		local attachment = self:CreateAttachmentEnt(v)
		if not IsValid(attachment) then return end
		local footCollider = ents.Create("kingpommes_lfs_atat_footcollider")
		footCollider:PhysicsInit(SOLID_VPHYSICS)
		footCollider:SetMoveType(MOVETYPE_PUSH)
		footCollider:SetSolid(SOLID_VPHYSICS)
		footCollider:SetModel("models/kingpommes/starwars/atat/atat_collider_foot.mdl")
		footCollider:SetPos(attachment:GetPos())
		footCollider:Spawn()
		footCollider:Activate()
		footCollider.baseEnt = self
		self:DeleteOnRemove(footCollider)
		self:dOwner(footCollider)
		self.footCollider[k] = footCollider
		self:dOwner(constraint.NoCollide(Entity(0), footCollider, 0, 0))
		self:dOwner(constraint.NoCollide(self, footCollider, 0, 0))
		self:dOwner(constraint.Weld(attachment, footCollider, 0, 0, 0, true, true))
	end
end

-- Override
function ENT:RunOnSpawn()
	self:InitializeSeats()
	self:InitializeBlastdoors()
	self:SetLightingOriginEntity(self.Torso)
	--local test = ents.Create("prop_physics")
	--test:SetModel("models/kingpommes/starwars/atat/atat_blastdoorR.mdl")
	--test:SetPos(self:GetPos() + Vector(0, 256, -480))
	--test:SetParent(self)
	--test:Spawn()
	--test:Activate()
end

function ENT:InitializeSeats()
	-- GunnerSeat
	local gunnerSeat = self:AddPassengerSeat(Vector(0, 0, 0), Angle(0, 0, 0))
	gunnerSeat:SetModel("models/kingpommes/starwars/atat/seat_driver.mdl")
	gunnerSeat:SetParent(nil)
	gunnerSeat:SetParent(self.Head)
	gunnerSeat:Fire("SetParentAttachment", "seat.gunner")
	gunnerSeat:SetVehicleClass("phx_seat3")
	gunnerSeat:SetColor(Color(255, 255, 255, 255))
	gunnerSeat:SetLightingOriginEntity(self.Torso)
	self:SetGunnerSeat(gunnerSeat)
	-- commander
	local commanderSeat = self:AddPassengerSeat(Vector(0, 0, 0), Angle(0, 0, 0))
	commanderSeat:SetModel("models/kingpommes/starwars/atat/seat_stand.mdl")
	commanderSeat:SetParent(nil)
	commanderSeat:SetParent(self.Head)
	commanderSeat:SetRenderMode(RENDERMODE_TRANSALPHA)
	commanderSeat:SetColor(Color(0, 0, 0, 0))
	commanderSeat:DrawShadow(false)
	commanderSeat:Fire("SetParentAttachment", "seat.commander")
	commanderSeat:SetVehicleClass("kingpommes_lfs_seat_standing")
	commanderSeat:SetLightingOriginEntity(self.Torso)
	self:SetTurretSeat(commanderSeat)
	-- passengers
	local passengerSeatNumber = 22

	for i = 1, passengerSeatNumber do
		local passengerSeat = self:AddPassengerSeat(Vector(0, 0, 0), Angle(0, 0, 0))
		passengerSeat:SetModel("models/kingpommes/starwars/atat/seat_passenger.mdl")
		passengerSeat:SetParent(nil)
		passengerSeat:SetParent(self) -- for whatever reason parenting to self fucks up the view angles / player head angles with LFS ?!
		passengerSeat:Fire("SetParentAttachment", "seat.passenger." .. i)
		--passengerSeat:SetKeyValue("limitview", 1) -- Cant do this when parented to self because of shit above ...
		passengerSeat:ResetSequence(passengerSeat:LookupSequence("open"))
		passengerSeat:SetColor(Color(255, 255, 255, 255))
		passengerSeat:SetLightingOriginEntity(self.Torso)

		if i <= 8 then
			passengerSeat:PhysicsInit(SOLID_BBOX)
		end
	end
end

function ENT:InitializeBlastdoors()
	self.Doors = {}
	self.DoorConstraints = {}

	local doors = {
		interiorL = {
			model = "models/kingpommes/starwars/atat/atat_collider_interiordoor.mdl",
			attachment = "door.interior.L",
			poseparam = "interiordoor_L",
			openoffset = Vector(0, 0, 80),
			sound = "doors/doormove2.wav"
		},
		interiorR = {
			model = "models/kingpommes/starwars/atat/atat_collider_interiordoor.mdl",
			attachment = "door.interior.R",
			poseparam = "interiordoor_R",
			openoffset = Vector(0, 0, 80),
			sound = "doors/doormove2.wav"
		},
		blastdoorL = {
			model = "models/kingpommes/starwars/atat/atat_collider_blastdoorL.mdl",
			attachment = "door.blast.L",
			poseparam = "blastdoor_L",
			openoffset = Vector(9, 0, 75),
			sound = "ambient/levels/outland/ol12a_overhead_slider_open.wav"
		},
		blastdoorR = {
			model = "models/kingpommes/starwars/atat/atat_collider_blastdoorR.mdl",
			attachment = "door.blast.R",
			poseparam = "blastdoor_R",
			openoffset = Vector(-9, 0, 75),
			sound = "ambient/levels/outland/ol12a_overhead_slider_open.wav"
		},
		chute = {
			model = "models/kingpommes/starwars/atat/atat_collider_chute.mdl",
			attachment = "door.chute",
			poseparam = "chute",
			openoffset = Vector(0, -50, 0),
			sound = "ambient/levels/outland/ol12a_slidergate_open.wav"
		},
		hatch = {
			model = "models/kingpommes/starwars/atat/atat_collider_hatch.mdl",
			attachment = "door.hatch",
			poseparam = "hatch",
			openoffset = Vector(-42, 0, 8),
			sound = "ambient/levels/outland/ol12a_slidergate_open.wav"
		}
	}

	for k, v in pairs(doors) do
		local attachment = self:GetAttachment(self:LookupAttachment(v["attachment"]))
		if not istable(attachment) then continue end
		local door = ents.Create("prop_dynamic")
		door:SetModel(v["model"])
		door:SetPos(attachment.Pos)
		door:SetAngles(attachment.Ang)
		door:SetColor(Color(0, 0, 0, 0))
		door:SetRenderMode(RENDERMODE_TRANSALPHA)
		door:PhysicsInit(SOLID_VPHYSICS)
		door:SetSolid(SOLID_VPHYSICS)
		door:SetUseType(SIMPLE_USE) -- dont think this works for prop_dynamic
		door:Spawn()
		door:Activate()
		--door:SetParent(self, self:LookupAttachment(v["attachment"]))
		door:SetParent(self)
		--door.canexplode = v["canexplode"]
		door.poseparam = v["poseparam"]
		door.sound = v["sound"]
		door.openoffset = v["openoffset"]
		door.ATATblastdoorBaseent = self
		door.nextUse = CurTime()
		door.LastPose = 0
		door.DesiredPose = 0
		door:SetLightingOriginEntity(self.Torso)
		self.Doors[k] = door
		self:DeleteOnRemove(door)
		door:DeleteOnRemove(self)
	end
end

function ENT:AdjustBlastdoors()
	if not istable(self.Doors) then return end

	for _, v in pairs(self.Doors) do
		v.LastPose = Lerp(FrameTime() * self.DoorSpeed, v.LastPose, v.DesiredPose)
		self.Torso:SetPoseParameter(v.poseparam, v.LastPose)
	end
end

-- Override
function ENT:Use(ply)
	if not IsValid(ply) then return end

	if self:GetlfsLockedStatus() or (simfphys.LFS.TeamPassenger:GetBool() and ((self:GetAITEAM() ~= ply:lfsGetAITeam()) and ply:lfsGetAITeam() ~= 0 and self:GetAITEAM() ~= 0)) then
		self:EmitSound("doors/default_locked.wav")

		return
	end

	-- prioritise pods that the player might be looking at
	local eyeTrace = ply:GetEyeTrace()
	local traceEnt = eyeTrace.Entity

	if (traceEnt:GetClass() == "prop_vehicle_prisoner_pod") then
		local pod = traceEnt
		if not IsValid(pod) or pod:GetNWInt("pPodIndex") == 0 or IsValid(pod:GetDriver()) then return end
		ply:EnterVehicle(pod)

		return
	end

	-- then check if the player is close to the neck airlock or the ladder
	local enterPoints = {
		head = "dismount.head",
		ladder = "dismount.ladder",
	}

	local threasholdDist = 32

	for k, v in pairs(enterPoints) do
		local attachment = self:GetAttachment(self:LookupAttachment(v))
		if not istable(attachment) then return end
		local attachmentPos = attachment.Pos + self:GetUp() * 50

		if self.debugEnabled then
			debugoverlay.Cross(attachmentPos, 32, 2, Color(255, 0, 0), false)
		end

		local dist = ply:EyePos():Distance(attachmentPos)

		if dist < threasholdDist then
			self:EnterATAT(ply, k)

			return
		end
	end
end

function ENT:EnterATAT(ply, location)
	if not IsValid(ply) or not isstring(location) then return end

	if location == "head" then
		self:EnterHead(ply)
	elseif location == "ladder" then
		self:EnterAsPassengerUp(ply)
	end
end

function ENT:EnterHead(ply)
	local AI = self:GetAI()
	local DriverSeat = self:GetDriverSeat()
	local GunnerSeat = self:GetGunnerSeat()
	local CommanderSeat = self:GetPassengerSeats()[3]

	if IsValid(DriverSeat) and not IsValid(DriverSeat:GetDriver()) and not AI then
		ply:EnterVehicle(DriverSeat)

		return
	end

	if IsValid(GunnerSeat) and not IsValid(GunnerSeat:GetDriver()) then
		ply:EnterVehicle(GunnerSeat)

		return
	end

	if IsValid(CommanderSeat) and not IsValid(CommanderSeat:GetDriver()) then
		ply:EnterVehicle(CommanderSeat)

		return
	end
end

function ENT:EnterAsPassengerUp(ply)
	local Seat = NULL
	local Dist = 500000

	for k, v in pairs(self:GetPassengerSeats()) do
		if isUp and k < 12 then continue end

		if IsValid(v) and not IsValid(v:GetDriver()) then
			local cDist = (v:GetPos() - ply:GetPos()):Length()

			if cDist < Dist then
				Seat = v
				Dist = cDist
			end
		end
	end

	if IsValid(Seat) then
		ply:EnterVehicle(Seat)
	end
end

-- Override to remove
function ENT:FireRearGun()
end

-- Override to remove
function ENT:UnRagdoll()
end

-- Override to remove
function ENT:BecomeRagdoll()
end

-- Override to remove
function ENT:FireTurret()
end

-- Override
function ENT:PrimaryAttack()
	self.Head:ShootPrimary()
end

-- Override
function ENT:GunnerWeapons(_, _, _)
	self.Head:ShootSecondary()
end

-- Override
function ENT:SecondaryAttack()
	if IsValid(self:GetGunner()) then return end
	self.Head:ShootSecondary()
end

-- Override to remove
function ENT:MainGunPoser(_, _)
end

local GroupCollide = {
	[COLLISION_GROUP_DEBRIS] = true,
	[COLLISION_GROUP_DEBRIS_TRIGGER] = true,
	[COLLISION_GROUP_PLAYER] = true,
	[COLLISION_GROUP_WEAPON] = true,
	[COLLISION_GROUP_VEHICLE_CLIP] = true,
	[COLLISION_GROUP_WORLD] = true,
}

local CanMoveOn = {
	["func_door"] = true,
	["func_movelinear"] = true,
	["func_rotating"] = true,
	["func_tracktrain"] = true,
	["prop_physics_multiplayer"] = true,
	["prop_physics"] = true,
}

function ENT:HandleAnimation()
	local walkspeed = self.smSpeed / 56
	local turnspeed = math.abs(self.IsTurnMove) / 0.03

	if (math.abs(self.smSpeed) > self.Walkspeed * 0.05) then
		self:ResetSequence("walk")
		self:SetPlaybackRate(walkspeed)
		--self.Torso:ResetSequence("walk")
		--self.Torso:SetPlaybackRate(walkspeed)
	elseif (self.IsTurnMove > 0.01) then
		self:ResetSequence("turn_left")
		self:SetPlaybackRate(turnspeed)
	elseif (self.IsTurnMove < -0.01) then
		--self.Torso:ResetSequence("turn_left")
		--self.Torso:SetPlaybackRate(turnspeed)
		self:ResetSequence("turn_right")
		self:SetPlaybackRate(turnspeed)
	else --self.Torso:ResetSequence("turn_right") --self.Torso:SetPlaybackRate(turnspeed)
		self:ResetSequence("idle")
		--self.Torso:ResetSequence("idle")
	end
end

function ENT:GetPlayerInput(Driver)
	local EyeAngles = Angle(0, 0, 0)
	local KeyForward = false
	local KeyBack = false
	local KeyLeft = false
	local KeyRight = false
	local Sprint = false
	local FreeLook = false

	if IsValid(Driver) then
		EyeAngles = Driver:EyeAngles()
		KeyForward = Driver:lfsGetInput("+THROTTLE")
		KeyBack = Driver:lfsGetInput("-THROTTLE")
		KeyLeft = Driver:lfsGetInput("+ROLL")
		KeyRight = Driver:lfsGetInput("-ROLL")
		FreeLook = Driver:lfsGetInput("FREELOOK")

		if KeyBack then
			KeyForward = false
		end

		Sprint = Driver:lfsGetInput("VSPEC") or Driver:lfsGetInput("+PITCH") or Driver:lfsGetInput("-PITCH")
	end

	return EyeAngles, KeyForward, KeyBack, KeyLeft, KeyRight, Sprint, FreeLook
end

function ENT:GetGroundInformation()
	local FloorAttachments = {
		rl = "floor.rear.L",
		rr = "floor.rear.R",
		fl = "floor.front.L",
		fr = "floor.front.R"
	}

	local FeetAttachments = {
		rl = "attach.rear.L",
		rr = "attach.rear.R",
		fl = "attach.front.L",
		fr = "attach.front.R"
	}

	local FloorOffset = {}
	local HitNormal = {}
	local HitEntity = {}
	local UpOffset = 128
	local traceSize = 48

	for k, _ in pairs(FloorAttachments) do
		local FloorAttachment = self:GetAttachment(self:LookupAttachment(FloorAttachments[k]))
		local FootAttachment = self:GetAttachment(self:LookupAttachment(FeetAttachments[k]))

		if (istable(FloorAttachment) and istable(FootAttachment)) then
			local TraceStart = FloorAttachment.Pos + self:GetUp() * UpOffset
			local TraceEnd = FloorAttachment.Pos + self:GetUp() * -UpOffset

			local Trace = util.TraceHull({
				start = TraceStart,
				endpos = TraceEnd,
				filter = function(ent) return not (ent == self or ent:GetModel() == "models/kingpommes/starwars/atat/atat_collider_foot.mdl" or ent:IsPlayer() or ent:IsNPC() or ent:IsVehicle() or ent:IsRagdoll() or GroupCollide[ent:GetCollisionGroup()]) end,
				mins = Vector(-traceSize, -traceSize, 0),
				maxs = Vector(traceSize, traceSize, 0),
			})

			FloorOffset[k] = -((TraceStart - Trace.HitPos):Length() - UpOffset)
			HitNormal[k] = Trace.HitNormal
			HitEntity[k] = Trace.Entity

			if self.debugEnabled then
				debugoverlay.Line(TraceStart, TraceEnd, 0.1, Color(55, 64, 143), false)
				debugoverlay.Box(FloorAttachment.Pos, Vector(-traceSize, -traceSize, 0), Vector(traceSize, traceSize, 0), 0.1, Color(78, 26, 109, 80))
				debugoverlay.Box(FloorAttachment.Pos, Vector(-traceSize, -traceSize, 0), Vector(traceSize, traceSize, FloorOffset[k]), 0.1, Color(55, 64, 143, 30))
			end
		end
	end

	return FloorOffset, HitNormal, HitEntity
end

function ENT:GetGroundDifference(FloorOffsets)
	local min = 0
	local max = 0
	local LegsOnGround = 0

	local FootOffsetRange = {
		min = -45.7,
		max = 78.3
	}

	for _, v in pairs(FloorOffsets) do
		if v < min then
			min = v
		elseif v > max then
			max = v
		end

		if (v > FootOffsetRange["min"]) then
			LegsOnGround = LegsOnGround + 1
		end
	end

	local FloorOffset = 0
	local frontTooHigh = FloorOffsets["fl"] > FootOffsetRange["max"] and FloorOffsets["fr"] > FootOffsetRange["max"]
	local frontTooLow = FloorOffsets["fl"] < FootOffsetRange["min"] and FloorOffsets["fr"] > FootOffsetRange["min"]
	local rearTooHigh = FloorOffsets["rl"] > FootOffsetRange["max"] and FloorOffsets["rr"] > FootOffsetRange["max"]
	local rearTooLow = FloorOffsets["rl"] < FootOffsetRange["min"] and FloorOffsets["rr"] > FootOffsetRange["min"]

	if frontTooHigh or rearTooHigh then
		FloorOffset = -(max - FootOffsetRange["max"])
	end

	if frontTooLow or rearTooLow then
		FloorOffset = (min - FootOffsetRange["min"])
	end

	min = math.max(min, FootOffsetRange["min"])
	max = math.min(max, FootOffsetRange["max"])
	local offsetAsymetry = 16
	FloorOffset = FloorOffset + (min + max - offsetAsymetry) * 0.5
	local minRange = FootOffsetRange["min"] * 0.99
	local fl = self:GetPoseParameter("leg_offset_front_L") >= minRange
	local fr = self:GetPoseParameter("leg_offset_front_R") >= minRange
	local rl = self:GetPoseParameter("leg_offset_rear_L") >= minRange
	local rr = self:GetPoseParameter("leg_offset_rear_R") >= minRange
	fl = FloorOffsets["fl"] >= minRange
	fr = FloorOffsets["fr"] >= minRange
	rl = FloorOffsets["rl"] >= minRange
	rr = FloorOffsets["rr"] >= minRange
	local frontOnGround = fl or fr
	local rearOnGround = rl or rr
	local threePoints = LegsOnGround >= 3
	local IsOnGround = frontOnGround and rearOnGround and threePoints

	return FloorOffset, IsOnGround
end

function ENT:GetGroundNormal(HitNormal)
	local Normal = Vector(0, 0, 0)

	for _, v in pairs(HitNormal) do
		Normal = Normal + v
	end

	Normal = Normal:GetNormalized()
	self.smNormal = self.smNormal or Normal
	Normal.x = math.ApproachAngle(self.smNormal.x, Normal.x, FrameTime() * 5)
	Normal.y = math.ApproachAngle(self.smNormal.y, Normal.y, FrameTime() * 5) * 0.6
	Normal.z = math.ApproachAngle(self.smNormal.z, Normal.z, FrameTime() * 5)

	return Normal
end

function ENT:AdjustNormalForPoseparams(TraceNormal, FloorOffsets)
	-- side to side can be adjusted by offsetting the feet a bit instead of rotating the whole body
	TraceNormal.y = TraceNormal.y * 0.6

	-- if the poseparameters hit their limit somewhere adjust the rotation of the whole vehicle
	local FootOffsetRange = {
		min = -45.7,
		max = 78.3
	}

	if (FloorOffsets["fl"] > FootOffsetRange["max"] and FloorOffsets["fr"] > FootOffsetRange["max"]) then
		local force = math.max(FloorOffsets["fl"], FloorOffsets["fr"]) - FootOffsetRange["max"] * 0.0001
		TraceNormal = TraceNormal - self:GetForward() * force
	end

	if self.debugEnabled then
		debugoverlay.Line(self:GetPos() + self:GetUp() * -400, self:GetPos() + self:GetUp() * -300 + TraceNormal * 100, 0.1, Color(143, 68, 55), true)
	end

	return TraceNormal:GetNormalized()
end

function ENT:IsBalanced()
	if self.debugEnabled then
		local up = 400
		local rollLength = up * math.tan(math.rad(self.TipOverThreashold["roll"]))
		local pitchLength = up * math.tan(math.rad(self.TipOverThreashold["pitch"]))
		local rollOffsetL = self:GetPos() - self:GetRight() * rollLength + self:GetUp() * up
		local rollOffsetR = self:GetPos() + self:GetRight() * rollLength + self:GetUp() * up
		local pitchOffsetR = self:GetPos() - self:GetForward() * pitchLength + self:GetUp() * up
		local pitchOffsetF = self:GetPos() + self:GetForward() * pitchLength + self:GetUp() * up
		debugoverlay.Triangle(self:GetPos(), rollOffsetL, rollOffsetR, 0.1, Color(255, 174, 0, 20), true)
		debugoverlay.Triangle(self:GetPos(), rollOffsetR, rollOffsetL, 0.1, Color(255, 174, 0, 20), true)
		debugoverlay.Triangle(self:GetPos(), pitchOffsetR, pitchOffsetF, 0.1, Color(255, 174, 0, 20), true)
		debugoverlay.Triangle(self:GetPos(), pitchOffsetF, pitchOffsetR, 0.1, Color(255, 174, 0, 20), true)
		debugoverlay.Line(self:GetPos(), self:GetPos() + Vector(0, 0, 1) * 400, 0.1, Color(0, 0, 0), true)
	end

	self.pitch = Lerp(FrameTime(), self.pitch, self:GetAngles().p)
	self.roll = Lerp(FrameTime(), self.roll, self:GetAngles().r)

	return math.abs(self.pitch) <= self.TipOverThreashold["pitch"] and math.abs(self.roll) <= self.TipOverThreashold["roll"]
end

function ENT:AdjustFeetPos(FloorOffset)
	local FeetPoseParams = {
		rl = "leg_offset_rear_L",
		rr = "leg_offset_rear_R",
		fl = "leg_offset_front_L",
		fr = "leg_offset_front_R"
	}

	self.floorOffsetPose = self.floorOffsetPose or {
		rl = FloorOffset["rl"],
		rr = FloorOffset["rr"],
		fl = FloorOffset["fl"],
		fr = FloorOffset["fr"]
	}

	for k, v in pairs(FloorOffset) do
		self.floorOffsetPose[k] = Lerp(FrameTime() * 10, self.floorOffsetPose[k], v)
		self:SetPoseParameter(FeetPoseParams[k], self.floorOffsetPose[k])
	end
end

function ENT:AdjustFeetTwist()
	self.turnPoseValue = self.turnPoseValue or 0
	local newTurnValue = 0

	if math.abs(self.smSpeed) > 0.5 then
		newTurnValue = self.IsTurnMove / self.Turnrate * 5 * self.smSpeed / math.abs(self.smSpeed)
	end

	self.turnPoseValue = Lerp(FrameTime(), self.turnPoseValue, newTurnValue)
	self:SetPoseParameter("leg_turn", -self.turnPoseValue)
end

function ENT:IsOnMoveable(HitEntity)
	for _, v in pairs(HitEntity) do
		if (IsValid(v) and CanMoveOn[v:GetClass()]) then return true end
	end

	return false
end

function ENT:OnLandingGearToggled(bOn)
	if self:GetAI() then return end
	self.Head:EmitSound("buttons/lightswitch2.wav")
	self.Head:SetIsLightOn(bOn)
end

function ENT:OnTick()
	if not IsValid(self) then return end
	self:CopyEffects()
	self:AdjustBlastdoors()
	local PObj = self:GetPhysicsObject()
	if not IsValid(PObj) then return end
	local HeadPObj = self.Head:GetPhysicsObject()
	if not IsValid(HeadPObj) then return end

	-- dont allow AI
	if self:GetAI() then
		self:SetAI(false)
	end

	-- enable engines (?)
	if not self:GetEngineActive() then
		self:SetEngineActive(true)
	end

	-- basic stuff
	local FT = FrameTime()
	--local FTtoTick = FT * 66.66666
	local FTtoTick = FT * FT * 1000
	local TurnRate = FT * self.Turnrate -- how fast the vehicle can turn
	local Vel = self:GetVelocity()
	local VelL = self:WorldToLocal(self:GetPos() + Vel)
	local Right = self:GetRight()
	local Up = self:GetUp()
	local FloorOffsets, HitNormals, HitEntities = self:GetGroundInformation()
	self:AdjustFeetPos(FloorOffsets)
	local DistanceDifference, IsOnGround = self:GetGroundDifference(FloorOffsets)
	local TraceNormal = self:GetGroundNormal(HitNormals)
	--local TraceNormal = self:AdjustNormalForPoseparams(self:GetGroundNormal(HitNormals), FloorOffsets)
	local HitMoveable = self:IsOnMoveable(HitEntities)
	local IsBalanced = self:IsBalanced()
	self:SetTurretHeat(math.max(self:GetTurretHeat() - 25 * FrameTime(), 0))
	-- move entity
	self:SetMove(self:GetMove() + self:WorldToLocal(self:GetPos() + Vel).x * FT * 1.8)
	local Move = self:GetMove()

	-- wrap rotation
	if Move > 360 then
		self:SetMove(Move - 360)
	end

	if Move < -360 then
		self:SetMove(Move + 360)
	end

	local Gunner = self:GetGunner()
	local DriverPod = self:GetDriverSeat()
	if not IsValid(DriverPod) then return end
	local Driver = DriverPod:GetDriver()

	-- pose the front guns
	if IsValid(Gunner) then
		self.Head:PoseTurrets(self:GetGunnerSeat(), Gunner:EyeAngles())
		Gunner:CrosshairDisable()

		if (Gunner:KeyDown(IN_ATTACK)) then
			self.Head:ShootSecondary()
		end
	end

	if self:GetIsCarried() then
		self.IsCarried = true
		self.Head:ResetHead(10000)
	else
		self.IsCarried = false
	end

	-- adjust head to where driver is looking
	self.StoredEyeAnglesATTE = self.StoredEyeAnglesATTE or DriverPod:GetAngles()

	if (self.debugEnabled) then
		local start = DriverPod:GetPos()
		local endpos = start + DriverPod:WorldToLocalAngles(self.StoredEyeAnglesATTE):Forward() * 1000
		debugoverlay.Line(start, endpos, FrameTime() * 2, Color(62, 66, 255), true)
	end

	-- adjust vehicle depinding on driver view
	if IsValid(Driver) then
		local EyeAngles, KeyForward, KeyBack, KeyLeft, KeyRight, Sprint, Freelook = self:GetPlayerInput(Driver)

		if not Freelook then
			self.StoredEyeAnglesATTE = EyeAngles
		end

		-- pose turrets from driver eyes if gunner is not present
		if not IsValid(Gunner) then
			self.Head:PoseTurrets(DriverPod, EyeAngles)
		end

		-- adjust feet twist
		self:AdjustFeetTwist()
		-- fix for smY
		self.smY = self.smY or self:GetAngles().y

		if math.abs(self:GetAngles().y - self.smY) > 2 then
			self.smY = self:GetAngles().y
		end

		-- set the move speed
		if IsBalanced and IsOnGround then
			self.Head:AdjustHead(FT, DriverPod, self.StoredEyeAnglesATTE)
			self.Head:ClampHead()
			local MoveSpeed = Sprint and self.Sprintspeed or self.Walkspeed
			self.smSpeed = self.smSpeed + ((KeyForward and MoveSpeed or 0) - (KeyBack and MoveSpeed or 0) - self.smSpeed) * FTtoTick * 0.05

			--self:SetRPM(self.smSpeed)
			local AddYaw = (KeyRight and 30 or 0) - (KeyLeft and 30 or 0)

			-- turn rate is faster when in sprint
			TurnRate = math.max(TurnRate, TurnRate * 2.3 * self.smSpeed / self.Sprintspeed)
			local desiredAngles = DriverPod:WorldToLocalAngles(self.StoredEyeAnglesATTE + Angle(0, AddYaw, 0))
			local NEWsmY = math.ApproachAngle(self.smY, desiredAngles.y, TurnRate)
			local isInHeadRange = math.abs(self:GetAngles().y - desiredAngles.y) <= self.HeadMovementBeforeTurn and math.abs(self.smSpeed) <= 0.05
			self.IsTurnMove = isInHeadRange and 0 or NEWsmY - self.smY
			self.smY = isInHeadRange and self:GetAngles().y or NEWsmY
		else
			self.smSpeed = 0
			self.IsTurnMove = 0
			self.smY = self:GetAngles().y
		end
	else
		-- atat is no longer turning
		self.StoredEyeAnglesATTE = DriverPod:GetAngles()
		self.IsTurnMove = 0
		self.smSpeed = 0
		self:ResetSequence("idle")
		-- reset head
		--[[
		if (IsBalanced and IsOnGround) then
			self.Head:ResetHead()
		end
		]]
	end

	self.smSpeed = self.smSpeed or 0
	self:SetIsMoving(math.abs(self.smSpeed) > 1 or (self.IsTurnMove and math.abs(self.IsTurnMove) > TurnRate * 0.9))
	-- adjust physics behaviour
	local normalDifference = self.smNormal and (self.smNormal - self:GetUp()):Length() or 0
	local groundDistance = math.abs(DistanceDifference)
	local ShouldMotionEnable = self:GetIsMoving() or normalDifference > 0.002 or groundDistance > 6.1
	ShouldMotionEnable = ShouldMotionEnable or self:IsPlayerHolding() or self.Torso:IsPlayerHolding() or self.Head:IsPlayerHolding()
	ShouldMotionEnable = ShouldMotionEnable or not IsOnGround or not IsBalanced
	PObj:EnableGravity((not IsOnGround or not IsBalanced) and not self.IsCarried)
	HeadPObj:EnableGravity((not IsOnGround or not IsBalanced) and not self.IsCarried)
	PObj:EnableMotion(ShouldMotionEnable or HitMoveable or self.IsShootingCannon or self.IsCarried)
	HeadPObj:EnableMotion(ShouldMotionEnable or HitMoveable or self.IsShootingCannon or self.IsCarried)

	if IsOnGround and IsBalanced then
		-- handle the walking animation
		self:HandleAnimation()
		self.Head:ApplyBobbing()
		local Force = Up * 0
		HeadPObj:SetMass(1)
		self.Head:SetGravity(1)
		self:SetGravity(1)

		for _, v in pairs(self.footCollider) do
			v:SetCollisionGroup(COLLISION_GROUP_NONE)
		end

		-- up force
		if FrameTime() >= 1 / 16 then
			Force = (Up * DistanceDifference * 3 - Up * VelL.z + Right * VelL.y) * 0.05
		else
			Force = (Up * DistanceDifference * 3 - Up * VelL.z + Right * VelL.y) * 0.5
		end
		PObj:ApplyForceCenter(Force * self.Mass * FTtoTick)

		-- angle force
		self.smNormal = self.smNormal and self.smNormal + (TraceNormal - self.smNormal) * FTtoTick or TraceNormal
		local AngForce = Angle(0, 0, 0)

		if IsValid(Driver) then
			AngForce.y = self:WorldToLocalAngles(Angle(self:GetAngles().x, self.smY, self:GetAngles().z)).y
		end

		local forceApplyOffset = PObj:GetMassCenter().z
		local forceMultiplyer = 8
		local spacing = 512

		self:ApplyAngForceTo(self, (AngForce * 50 - self:GetAngVelFrom(self) * 2) * self.Mass * forceMultiplyer * 3 * FTtoTick)

		-- ground ajustment
		if self.debugEnabled then
			local start1 = self:GetPos() + forceApplyOffset * Up + Up * spacing
			local end1 = start1 + self:GetRight() * -self.smNormal * 1000
			local start2 = self:GetPos() + forceApplyOffset * Up - Up * spacing
			local end2 = start2 + self:GetRight() * self.smNormal * 1000
			debugoverlay.Line(start1, end1, 0.1, Color(255, 0, 0), true)
			debugoverlay.Line(start2, end2, 0.1, Color(255, 0, 0), true)
		end

		if FrameTime() >= 1 / 16 then
			local factor = 0.2
			PObj:ApplyForceOffset(-self.smNormal * self.Mass * forceMultiplyer * FTtoTick * factor, forceApplyOffset * Up - Up * spacing)
			PObj:ApplyForceOffset(self.smNormal * self.Mass * forceMultiplyer * FTtoTick * factor, forceApplyOffset * Up + Up * spacing)
		else
			PObj:ApplyForceOffset(-self.smNormal * self.Mass * forceMultiplyer * FTtoTick, forceApplyOffset * Up - Up * spacing)
			PObj:ApplyForceOffset(self.smNormal * self.Mass * forceMultiplyer * FTtoTick, forceApplyOffset * Up + Up * spacing)
		end

		-- forward force
		local ForwardForce = self:GetForward() * (self.smSpeed - VelL.x)

		if self.debugEnabled then
			local start1 = self:LocalToWorld(PObj:GetMassCenter())
			local end1 = start1 + ForwardForce * self.Mass * 0.1 * FTtoTick
			debugoverlay.Line(start1, end1, 0.1, Color(0, 255, 0), true)
		end

		PObj:ApplyForceCenter(ForwardForce * self.Mass * 0.1 * FTtoTick)
	else
		self:ResetSequence("idle")
		--self.Torso:ResetSequence("idle")
		HeadPObj:SetMass(1000)
		self.Head:SetGravity(3)
		self:SetGravity(3)

		for _, v in pairs(self.footCollider) do
			v:SetCollisionGroup(21)
		end
	end
end

function ENT:OnTakeDamage(dmginfo)
	if (dmginfo:IsDamageType(DMG_BULLET) or dmginfo:IsDamageType(DMG_AIRBOAT)) and self.ExplosionDamageOnly then return end
	self:TakePhysicsDamage(dmginfo)
	self:StopMaintenance()
	local Damage = dmginfo:GetDamage()
	local CurHealth = self:GetHP()
	local NewHealth = math.Clamp(CurHealth - Damage, -self:GetMaxHP(), self:GetMaxHP())
	self:SetHP(NewHealth)

	if NewHealth <= 0 then
		if self.isAlreadyDead then return end
		self.isAlreadyDead = true
		self:DieEffect()
	end
end

function ENT:DieEffect()
	timer.Simple(1, function()
		if not IsValid(self) then return end
		self:EmitSound("kingpommes/starwars/atat/falling.wav", 120)
	end)

	self:SetModel("models/kingpommes/starwars/atat/atat_legs_nomesh.mdl")
	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetSolid(SOLID_VPHYSICS)
	self:Activate()
	local HeadPObj = self.Head:GetPhysicsObject()
	if not IsValid(HeadPObj) then return end
	HeadPObj:SetMass(1000)
	self.Head:SetGravity(3)
	HeadPObj:EnableMotion(true)
	HeadPObj:EnableGravity(true)
	local ragdoll = ents.Create("prop_ragdoll")
	ragdoll:SetModel("models/kingpommes/starwars/atat/atat_legs_ragdoll.mdl")
	ragdoll:SetPos(self:GetPos())
	ragdoll:SetAngles(self:GetAngles())
	ragdoll:PhysicsInit(SOLID_VPHYSICS)
	ragdoll:SetSolid(SOLID_VPHYSICS)
	ragdoll:SetMoveType(MOVETYPE_VPHYSICS)
	ragdoll:Spawn()
	ragdoll:Activate()
	self:DeleteOnRemove(ragdoll)
	ragdoll:DeleteOnRemove(self)
	ragdoll:SetLightingOriginEntity(self.Torso)
	ragdoll.baseATAT = self
	self.ragdoll = ragdoll
	self:SetParent(ragdoll)
	self:Fire("SetParentAttachment", "attach.root")
	self.Torso:SetParent(nil)
	self.Torso:SetParent(self)
	self.Torso:Fire("SetParentAttachment", "attach.torso")
	local retardedWorkaround = ents.Create("prop_physics")
	retardedWorkaround:SetModel("models/hunter/blocks/cube025x025x025.mdl")
	retardedWorkaround:SetPos(self.ragdoll:GetPos())
	retardedWorkaround:Spawn()
	retardedWorkaround:Activate()
	retardedWorkaround:SetRenderMode(RENDERMODE_TRANSALPHA)
	retardedWorkaround:SetColor(Color(255, 255, 255, 0))
	retardedWorkaround:SetCollisionGroup(COLLISION_GROUP_IN_VEHICLE)
	retardedWorkaround:GetPhysicsObject():EnableCollisions(false)
	constraint.Weld(retardedWorkaround, self.ragdoll, 0, 0, 0, 0, 0)
	self:DeleteOnRemove(retardedWorkaround)
	self.physHandle = retardedWorkaround

	if math.random(1, 2) == 1 then
		self:FallOverFront()
	else
		self:FallOverSide()
	end

	self.Use = nil
	self.Head.Think = nil
	local seats = self:GetPassengerSeats()
	table.insert(seats, self:GetDriverSeat())

	for _, v in pairs(seats) do
		local ply = v:GetDriver()
		if not IsValid(ply) then continue end
		ply:Kill()
		v:Fire("Lock")
	end

	for _, v in pairs(self.footCollider) do
		v:Remove()
	end

	for _, v in pairs(self.Doors) do
		constraint.NoCollide(ragdoll, v, 0, 0)
		--v:SetParent(self)
	end

	local min, max = self:GetTorsoEnt():GetCollisionBounds()

	for k = 1, 5 do
		timer.Simple((k - 1) * 0.3, function()
			if not IsValid(self) then return end
			local effectdata = EffectData()
			local attachment = self.Torso:GetPos() + Vector(math.random(min.x, max.x), math.random(min.y, max.y), math.random(min.z, max.z))
			effectdata:SetOrigin(attachment)
			util.Effect("lfs_explosion_nodebris", effectdata)
			ParticleEffectAttach("env_fire_large_smoke", PATTACH_POINT_FOLLOW, self, math.random(13, 38))
		end)
	end
end

function ENT:FallOverSide()
	local max = 0

	local dir = {1, -1}

	self.falloverDir = 1

	for _, v in pairs(dir) do
		local trace = util.TraceLine({
			start = self:GetPos(),
			endpos = self:GetPos() + self:GetRight() * v * 1000 + self:GetUp() * -1 * 1000,
			filter = self
		})

		local length = (self:GetPos() - trace.HitPos):Length()

		if length > max then
			self.falloverDir = -v
			max = length
		end
	end

	self.Head:Remove()
	ParticleEffectAttach("explosion_huge_smoking_chunks", PATTACH_POINT_FOLLOW, self, self:LookupAttachment("attach.neck"))

	self.OnTick = function()
		if not isnumber(self.falloverDir) then return end
		local applyPos = self:GetPos() + self:GetUp() * 500
		local force = self:GetRight() * self.falloverDir * 100 + Vector(0, 0, 50)
		local multiplier = force:GetNormalized():Dot(Vector(0, 0, -1))
		local handlePhysObj = self.physHandle:GetPhysicsObject()

		if multiplier > 0.25 then
			handlePhysObj:SetMass(200)
		else
			handlePhysObj:SetMass(math.max(handlePhysObj:GetMass(), 1 + math.abs(multiplier) * 100))
		end

		debugoverlay.Line(applyPos, applyPos + force * (1 - multiplier), FrameTime() * 2, Color(255, 0, 0), false)
		handlePhysObj:ApplyForceOffset(force * (1 - multiplier), applyPos)
		self:TryFreezeRagdoll()
	end

	for _, v in pairs(self.DoorConstraints) do
		v:Remove()
	end
	--[[ -- TODO: exploding doors ?
	for _, v in pairs(self.Doors) do
		if not IsValid(v) then continue end
		if not v.canexplode then continue end

		constraint.NoCollide(ragdoll, v, 0, 0)
		local forcedir = v:GetPos() - self:GetPos()
		v:ForceClose()

		local phys = v:GetPhysicsObject()
		timer.Simple(0, function()
			phys:ApplyForceOffset(forcedir * 3000, v:GetPos() - Vector(0, 0, -10))
		end)
	end
	]]
end

function ENT:FallOverFront()
	local attachment = self.ragdoll:GetAttachment(self.ragdoll:LookupAttachment("attach.head"))
	self.Head:SetPos(attachment.Pos)
	self.Head:SetAngles(attachment.Ang)
	self.Head:GetPhysicsObject():SetMass(100)
	self.headsocket:Remove()
	local min = Angle(-20, -30, -45)
	local max = Angle(20, 30, 45)
	constraint.AdvBallsocket(self.Head, self.ragdoll, 0, 0, Vector(0, 0, 0), self.ragdoll:WorldToLocal(attachment.Pos), 0, 0, min.x, min.y, min.z, max.x, max.y, max.z, 0, 0, 0, 0, 1)
	constraint.Keepupright(self.ragdoll, Angle(0, 0, 0), 0, 100)

	self.OnTick = function()
		self.physHandle:GetPhysicsObject():ApplyForceOffset(self:GetUp() * -300 + self:GetForward() * 300, self:GetPos())
		self.Head:GetPhysicsObject():ApplyForceOffset(self.Head:GetUp() * 100, self.Head:GetPos() + self.Head:GetForward() * 1000)
		self:TryFreezeRagdoll()
	end
end

function ENT:TryFreezeRagdoll()
	if not IsValid(self) then return end
	local vel = self.ragdoll:GetVelocity():Length()

	local trace = util.TraceLine({
		start = self:GetPos(),
		endpos = self:GetPos() + Vector(0, 0, -1000),
		filter = {self, self.ragdoll, self.physHandle}
	})

	local floorDistance = (self:GetPos() - trace.HitPos):Length()
	if not (vel < 30 or floorDistance < 100) or floorDistance > 200 then return end

	self.OnTick = function()
		self:CopyEffects(self)
		self:AdjustBlastdoors(self)
	end

	for k = 0, self.ragdoll:GetPhysicsObjectCount() - 1 do
		local phys = self.ragdoll:GetPhysicsObjectNum(k)
		if not IsValid(phys) then continue end
		phys:EnableMotion(false)
	end

	if IsValid(self.physHandle) then
		self.physHandle:Remove()
	end
end

function ENT:CopyEffects()
	local color = self:GetColor()
	local material = self:GetMaterial()
	local skin = self:GetSkin()
	self.Torso:SetColor(color)
	self.Torso:SetMaterial(material)
	self.Torso:SetSkin(skin)

	if IsValid(self.Head) then
		self.Head:SetColor(color)
		self.Head:SetMaterial(material)
		self.Head:SetSkin(skin)
	end

	for _, v in pairs(self:GetPassengerSeats()) do
		if not IsValid(v) then continue end
		v:SetColor(color)
		v:SetMaterial(material)
	end
end

hook.Add("PlayerEnteredVehicle", "KingPommes.ATAT.ExitMod", function(ply, pod, _)
	--if pod:GetModel() ~= "models/kingpommes/starwars/atat/seat_passenger.mdl" then return end
	local parent = pod:GetParent()
	if not IsValid(parent) then return end
	if (parent:GetClass() ~= "kingpommes_lfs_atat" and parent:GetClass() ~= "kingpommes_lfs_atat_head") then return end
	pod:ResetSequence("close")
	ply.ATATExitforGood = false
end)

hook.Add("PlayerLeaveVehicle", "KingPommes.ATAT.ExitMod", function(ply)
	-- receive the pod and confirm that its LFS
	local pod = ply:GetVehicle()
	local index = pod:GetNWInt("pPodIndex")
	if index == 0 then return end
	local atatPart = pod:GetParent()
	local atat = nil
	if not IsValid(atatPart) then return end
	if (atatPart:GetClass() ~= "kingpommes_lfs_atat" and atatPart:GetClass() ~= "kingpommes_lfs_atat_head") then return end

	-- get the atat entity
	if (atatPart:GetClass() == "kingpommes_lfs_atat_head") then
		atat = atatPart:GetBaseEnt()
	else
		atat = atatPart
	end

	if not IsValid(atat) then return end
	-- if the atat fell over or is freefalling dont exitmod
	local atatPhysObj = atat:GetPhysicsObject()
	if not IsValid(atatPhysObj) then return end
	if atatPhysObj:IsGravityEnabled() then return end
	local dismountPos = atat:GetPos()
	local dismountAng = atat:GetAngles()

	if index <= 3 then
		-- driver, gunner or commander: eject at neck airlock
		local dismount = atat:GetAttachment(atat:LookupAttachment("dismount.head"))
		if not istable(dismount) then return end
		dismountPos = dismount.Pos
		dismountAng = dismount.Ang
		pod:ResetSequence("open")
	elseif index <= 11 then
		-- passengers lower: eject infront of the pod
		local attachment = atat:GetAttachment(pod:GetParentAttachment())
		if not istable(attachment) then return end
		dismountPos = attachment.Pos + attachment.Ang:Right() * -48
		dismountAng = attachment.Ang + Angle(0, 90, 0)
		pod:ResetSequence("open")
	else
		-- passengers upper: eject at ladder
		local dismount = atat:GetAttachment(atat:LookupAttachment("dismount.ladder"))
		if not istable(dismount) then return end
		dismountPos = dismount.Pos
		dismountAng = dismount.Ang
	end

	-- teleport the player to the dismount location for each seat
	-- timer because of source / gmod fuckery
	ply.ATATExitforGood = true -- this will be set back to false if the player is just switching seats

	timer.Simple(0.1, function()
		if not ply.ATATExitforGood then return end
		ply:SetPos(dismountPos)
		ply:SetAngles(dismountAng)
	end)
end)

hook.Add("EntityTakeDamage", "KingPommes.ATAT.RagdollDamage", function(ent, dmgInfo)
	if ent:GetClass() ~= "prop_ragdoll" or ent:GetModel() ~= "models/kingpommes/starwars/atat/atat_legs_ragdoll.mdl" then return end
	if dmgInfo:GetDamageType() == DMG_CRUSH then return end
	ent.ATATHealth = ent.ATATHealth and ent.ATATHealth - dmgInfo:GetDamage() or ent.baseATAT.RagdollHealth

	if ent.ATATHealth <= 0 then
		ParticleEffect("explosion_huge", ent:GetPos() + Vector(0, 0, -200), Angle(0, 0, 0))
		ent:EmitSound("ambient/explosions/explode_2.wav", 120)
		ent:Remove()
	end
end)

hook.Add("PlayerUse", "KingPommes.ATAT.DoorPressed", function(_, ent)
	if not IsValid(ent.ATATblastdoorBaseent) or ent.ATATblastdoorBaseent:GetClass() ~= "kingpommes_lfs_atat" then return end
	if not ent.nextUse or ent.nextUse > CurTime() then return end
	ent:EmitSound(ent.sound)
	local openoffset = ent:GetRight() * ent.openoffset.x + ent:GetForward() * ent.openoffset.y + ent:GetUp() * ent.openoffset.z

	if not ent.Open then
		ent.DesiredPose = 1
		ent.Open = true
		ent:SetParent(nil) -- because gmod fuckery...
		ent:SetPos(ent:GetPos() + openoffset)
		ent:SetParent(ent.ATATblastdoorBaseent)
	else
		ent.DesiredPose = 0
		ent.Open = false
		ent:SetParent(nil) -- because gmod fuckery...
		ent:SetPos(ent:GetPos() - openoffset)
		ent:SetParent(ent.ATATblastdoorBaseent)
	end

	ent.nextUse = CurTime() + 1
end)

hook.Add("PhysgunPickup", "KingPommes.ATAT.DoorPhysgun", function(_, ent)
	if IsValid(ent.ATATblastdoorBaseent) then return false end
end)