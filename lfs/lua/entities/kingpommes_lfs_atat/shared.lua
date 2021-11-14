------------------------------------
------ Created by Jakob Sailer -----
------ LFS Base by blu / Luna ------
----------- DO NOT edit or ---------
------------ reupload!! ------------
------------------------------------

ENT.debugEnabled = false -- requires developer 1

-- Things that should never be changed!
ENT.Base = "lunasflightschool_atte"
ENT.Type = "anim"
ENT.PrintName = "AT-AT"
ENT.Author = "KingPommes"
ENT.Information = ""
ENT.Category = "[LFS] KingPommes" -- TODO: change to SW category
ENT.AutomaticFrameAdvance = true
ENT.Spawnable = true
ENT.AdminSpawnable = false
ENT.LAATC_PICKUPABLE = true
ENT.LAATC_PICKUP_POS = Vector(-256, 0, -200)
ENT.LAATC_PICKUP_Angle = Angle(0, 0, 0)

-- More things that should never be changed
ENT.MDL = "models/kingpommes/starwars/atat/atat_legs.mdl"
ENT.TORSO = "models/kingpommes/starwars/atat/atat_body.mdl"
ENT.HEAD = "models/kingpommes/starwars/atat/atat_head.mdl"
ENT.GibModels = nil
ENT.Mass = 100000

-- Movement Behavious
ENT.Walkspeed = 64
ENT.Sprintspeed = 130
ENT.DoorSpeed = 1
ENT.Turnrate = 4
ENT.HeadMovementBeforeTurn = 45
ENT.HeadTurnrate = 30
ENT.TipOverThreashold = {
	pitch = 35,
	roll = 20
}

-- Stats
ENT.AITEAM = 1
ENT.MaxHealth = 12000
ENT.RagdollHealth = 3000
ENT.MaxPrimaryAmmo = 200
ENT.MaxSecondaryAmmo = 1000
ENT.ExplosionDamageOnly = true

-- Things that are LFS but are not used
ENT.RotorPos = Vector(600, 0, 200)
ENT.SeatPos = Vector(0, 0, 0) --this is used by LFS Overhaul instead of the actual ent:GetDriverSeat() which is stupid
ENT.SeatAng = Angle(0, 0, 0)

function ENT:AddDataTables()
	local baseClass = scripted_ents.GetStored("lunasflightschool_atte")
	if not istable(baseClass) then return end
	baseClass = baseClass.t
	baseClass.AddDataTables(self)

	self:NetworkVar( "Entity", 25, "TorsoEnt" )
	self:NetworkVar( "Entity", 26, "HeadEnt" )
	self:NetworkVar( "Entity", 27, "Ballsocket" )
end

-- Sounds
sound.Add( {
	name = "ATAT_ENGINE",
	channel = CHAN_AUTO,
	volume = 1.0,
	level = 80,
	pitch = 100,
	sound = "ambient/machines/train_idle.wav"
} )

sound.Add( {
	name = "ATAT_ELEPHANT1",
	channel = CHAN_AUTO,
	volume = 1.0,
	level = 90,
	pitch = { 95, 105 },
	sound = "KingPommes/starwars/atat/elephant01.wav"
} )

sound.Add( {
	name = "ATAT_ELEPHANT2",
	channel = CHAN_AUTO,
	volume = 1.0,
	level = 90,
	pitch = { 95, 105 },
	sound = "KingPommes/starwars/atat/elephant02.wav"
} )

sound.Add( {
	name = "ATAT_IMPACT1",
	channel = CHAN_AUTO,
	volume = 1.0,
	level = 90,
	pitch = { 95, 105 },
	sound = "KingPommes/starwars/atat/impact01.wav"
} )

sound.Add( {
	name = "ATAT_IMPACT2",
	channel = CHAN_AUTO,
	volume = 1.0,
	level = 90,
	pitch = { 95, 105 },
	sound = "KingPommes/starwars/atat/impact02.wav"
} )

sound.Add( {
	name = "ATAT_DISTANT",
	channel = CHAN_AUTO,
	volume = 1.0,
	level = 130,
	pitch = { 95, 105 },
	sound = "KingPommes/starwars/atat/distant.wav"
} )

sound.Add( {
	name = "ATAT_CANNON",
	channel = CHAN_AUTO,
	volume = 1.0,
	level = 100,
	pitch = { 90, 110 },
	sound = "KingPommes/starwars/atat/shoot_cannon.wav"
} )

sound.Add( {
	name = "ATAT_TURRET",
	channel = CHAN_AUTO,
	volume = 1.0,
	level = 90,
	pitch = { 90, 110 },
	sound = "KingPommes/starwars/atat/shoot_turret.wav"
} )

-- Override
function ENT:GetPassengerSeats()
	-- self.pSeats only exists correctly on the server so clientside this has to be done:
	if not istable( self.pSeats ) then
		self.pSeats = {}
		local DriverSeat = self:GetDriverSeat()
		-- all seats that are connected to self
		for _, v in pairs( /*self:GetTorsoEnt():GetChildren()*/ self:GetChildren() ) do
			if v ~= DriverSeat and v:GetClass():lower() == "prop_vehicle_prisoner_pod" then
				table.insert( self.pSeats, v )
			end
		end

		-- the gunner
		table.insert(self.pSeats, self:GetGunnerSeat())
		-- the commander (using turretseat)
		table.insert(self.pSeats, self:GetTurretSeat())
	end
	return self.pSeats
end

hook.Add("OnEntityCreated", "KingPommes.ATAT.SeatSync", function(ent)
	if ent:GetClass() ~= "kingpommes_lfs_atat" then return end
	-- Timer is needed because of SetupDataTables being called after OnEntityCreated, so no Network Vars exist yet clientside.
	local entIndex = ent:EntIndex()

	timer.Create("KingPommes.SpawnATAT." .. entIndex, 0.2, 0, function()
		if IsValid(ent) and isfunction(ent.GetHeadEnt) then
			local ents = {ent:GetHeadEnt(), ent, /*ent:GetTorsoEnt()*/}
			for _, v in pairs(ents) do
				if not IsValid(v) then return end
				--v.LFS = true
				for _, w in pairs( v:GetChildren() ) do
					if w:GetClass():lower() == "prop_vehicle_prisoner_pod" then
						w.LFSchecked = true
						w.LFSBaseEnt = ent
					end
				end
			end
		end
		timer.Remove("KingPommes.SpawnATAT." .. entIndex)
	end)
end)