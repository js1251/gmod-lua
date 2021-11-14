-- BASECLASS CREATED BY LUNA!
-- ADDITIONAL CODE BY JAKOB SAILER AKA KINGPOMMES AND ONINONI
-- DO NOT EDIT OR REUPLOAD THIS FILE
util.PrecacheModel("models/kingpommes/starwars/atte/lfs_front.mdl")
if not util.IsValidModel("models/kingpommes/starwars/atte/lfs_front.mdl") then return end
AddCSLuaFile("shared.lua")
AddCSLuaFile("cl_init.lua")
AddCSLuaFile("entities/lunasflightschool_atte/cl_ikfunctions.lua")
include("shared.lua")

function ENT:Initialize()
	local baseClass = scripted_ents.GetStored("lunasflightschool_atte")
	if not istable(baseClass) then return end
	baseClass = baseClass.t
	baseClass.Initialize(self)

	self.GibModels = {"models/kingpommes/starwars/atte/lfs_front.mdl", "models/kingpommes/starwars/atte/lfs_rear.mdl", "models/kingpommes/starwars/atte/lfs_leg1.mdl", "models/kingpommes/starwars/atte/lfs_leg2.mdl", "models/kingpommes/starwars/atte/lfs_leg3_front_r.mdl", "models/kingpommes/starwars/atte/lfs_leg3_front_l.mdl", "models/kingpommes/starwars/atte/lfs_bigleg1.mdl", "models/kingpommes/starwars/atte/lfs_bigleg2.mdl"}
end

function ENT:RunOnSpawn()
	self:SetColor(self.StartColor)

	local RearEnt = self:GetRearEnt()
	if not IsValid(RearEnt) then return end
	RearEnt:SetModel("models/kingpommes/starwars/atte/lfs_rear.mdl")

	-- Turret
	local TurretSeat = self:AddPassengerSeat(Vector(150, 0, 150), Angle(0, -90, 0))
	local ID = self:LookupAttachment("driver_turret")
	local TSAttachment = self:GetAttachment(ID)

	if TSAttachment then
		local Pos, Ang = LocalToWorld(Vector(0, -9, -11), Angle(180, 0, -90), TSAttachment.Pos, TSAttachment.Ang)
		TurretSeat:SetParent(NULL)
		TurretSeat:SetPos(Pos)
		TurretSeat:SetAngles(Ang)
		TurretSeat:SetParent(self, ID)
		TurretSeat:SetVehicleClass("phx_seat2")
		self:SetTurretSeat(TurretSeat)
	end

	-- Driver 
	self:GetDriverSeat():SetVehicleClass("phx_seat2")
	local GunnerSeat = self:AddPassengerSeat(Vector(-150, -11, 178), Angle(0, 98, -5))
	self:SetGunnerSeat(GunnerSeat)
	GunnerSeat:SetVehicleClass("phx_seat2")
	GunnerSeat:SetParent(RearEnt)
	GunnerSeat.LFSchecked = true
	GunnerSeat.LFSBaseEnt = self

	-- Passengers
	local PassengerPos = {
		{Vector(192, 0, 166), Angle(0, -90, -5)}, -- cockpit passenger
		{Vector(-152, 12, 178), Angle(0, 80, -5)}, -- rear passenger
		-- hull passengers
		{Vector(43.16, 24, 165), Angle(0, 180, 0)},
		{Vector(43.16, -24, 165), Angle(0, 0, 0)},
		{Vector(21.80, 24, 165), Angle(0, 180, 0)},
		{Vector(21.80, -24, 165), Angle(0, 0, 0)},
		{Vector(0.45, 24, 165), Angle(0, 180, 0)},
		{Vector(0.45, -24, 165), Angle(0, 0, 0)},
		{Vector(-20.90, 24, 165), Angle(0, 180, 0)},
		{Vector(-20.90, -24, 165), Angle(0, 0, 0)},
		{Vector(-42.26, 24, 165), Angle(0, 180, 0)},
		{Vector(-42.26, -24, 165), Angle(0, 0, 0)},
	}

	for k, _ in pairs(PassengerPos) do
		self:AddPassengerSeat(PassengerPos[k][1], PassengerPos[k][2])
		local Pod = self.pSeats[table.Count(self.pSeats)]

		if k < 3 then
			Pod:SetVehicleClass("phx_seat2")
		end

		if k >= 2 then
			Pod:SetParent(RearEnt)
			Pod.LFSchecked = true
			Pod.LFSBaseEnt = self
		end
	end
end

function ENT:OnTick()
	local baseClass = scripted_ents.GetStored("lunasflightschool_atte")
	if not istable(baseClass) then return end
	if not istable(baseClass) then return end
	baseClass = baseClass.t
	baseClass.OnTick(self)

	self:GetRearEnt():SetSkin(self:GetSkin())

	if not istable(self.Constrainer) then return end
	for _, v in pairs(self.Constrainer) do
		v:SetSkin(self:GetSkin())
	end
end

-- Rear BallTurrets Firing
function ENT:FireRearGun()
	local RearEnt = self:GetRearEnt()
	if not self:CanAltPrimaryAttack() or not IsValid(RearEnt) then return end
	local baseClass = scripted_ents.GetStored("lunasflightschool_atte")
	if not istable(baseClass) then return end
	baseClass = baseClass.t
	baseClass.FireRearGun(self)
	RearEnt:ResetSequence(RearEnt:LookupSequence("shoot_" .. self.FireIndexRear))
end

-- Front BallTurrets Firing
function ENT:PrimaryAttack()
	if self:GetIsCarried() then return end
	if not self:CanPrimaryAttack() or not self.MainGunDir then return end
	local baseClass = scripted_ents.GetStored("lunasflightschool_atte")
	if not istable(baseClass) then return end
	baseClass = baseClass.t
	baseClass.PrimaryAttack(self)

	if self:GetSequence() ~= self:LookupSequence("shoot_gun") then
		self:ResetSequence(self:LookupSequence("shoot_" .. self.FireIndex))
	end
end

function ENT:OnLandingGearToggled( bOn )
	if self:GetAI() then return end
	self:EmitSound("buttons/lightswitch2.wav")
	self:SetIsLightOn(bOn)
end

-- Turret Firing
function ENT:FireTurret()
	if not self:CanSecondaryAttack() then return end
	local baseClass = scripted_ents.GetStored("lunasflightschool_atte")
	if not istable(baseClass) then return end
	baseClass = baseClass.t
	baseClass.FireTurret(self)
	self:ResetSequence(self:LookupSequence("shoot_gun"))
end

function ENT:BecomeRagdoll()
	--self:SetModel("models/kingpommes/starwars/atte/atte_poseable_front.mdl")
	local baseClass = scripted_ents.GetStored("lunasflightschool_atte")
	if not istable(baseClass) then return end
	baseClass = baseClass.t
	baseClass.BecomeRagdoll(self)

	-- only replacing the models isnt perfect but until the baseclass is more modular it will do
	self.Constrainer[1]:SetModel("models/kingpommes/starwars/atte/lfs_leg3_front_r.mdl")
	self.Constrainer[2]:SetModel("models/kingpommes/starwars/atte/lfs_leg2.mdl")
	self.Constrainer[3]:SetModel("models/kingpommes/starwars/atte/lfs_leg1_r.mdl")
	self.Constrainer[4]:SetModel("models/kingpommes/starwars/atte/lfs_leg3_front_l.mdl")
	self.Constrainer[5]:SetModel("models/kingpommes/starwars/atte/lfs_leg2.mdl")
	self.Constrainer[6]:SetModel("models/kingpommes/starwars/atte/lfs_leg1_l.mdl")
	self.Constrainer[7]:SetModel("models/kingpommes/starwars/atte/lfs_leg3_rear.mdl")
	self.Constrainer[8]:SetModel("models/kingpommes/starwars/atte/lfs_leg2.mdl")
	self.Constrainer[9]:SetModel("models/kingpommes/starwars/atte/lfs_leg1_r.mdl")
	self.Constrainer[10]:SetModel("models/kingpommes/starwars/atte/lfs_leg3_rear.mdl")
	self.Constrainer[11]:SetModel("models/kingpommes/starwars/atte/lfs_leg2.mdl")
	self.Constrainer[12]:SetModel("models/kingpommes/starwars/atte/lfs_leg1_l.mdl")
	self.Constrainer[13]:SetModel("models/kingpommes/starwars/atte/lfs_bigleg2.mdl")
	self.Constrainer[14]:SetModel("models/kingpommes/starwars/atte/lfs_bigleg1_r.mdl")
	self.Constrainer[15]:SetModel("models/kingpommes/starwars/atte/lfs_bigleg2.mdl")
	self.Constrainer[16]:SetModel("models/kingpommes/starwars/atte/lfs_bigleg1_l.mdl")
end