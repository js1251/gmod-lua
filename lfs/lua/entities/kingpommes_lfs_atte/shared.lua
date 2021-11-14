-- BASECLASS CREATED BY LUNA!
-- ADDITIONAL CODE BY JAKOB SAILER AKA KINGPOMMES AND ONINONI
-- DO NOT EDIT OR REUPLOAD THIS FILE
ENT.Type = "anim"
DEFINE_BASECLASS("lunasflightschool_atte")
ENT.PrintName = "AT-TE"
ENT.Author = "Blu, KingPommes, Oninoni"
ENT.Category = "[LFS] KingPommes"
ENT.Spawnable = true
ENT.AdminSpawnable = false
ENT.LAATC_PICKUPABLE = true
ENT.LAATC_PICKUP_POS = Vector(-230, 0, -150)
ENT.MDL = "models/kingpommes/starwars/atte/lfs_front.mdl"
ENT.SeatPos = Vector(238, 0, 150)
ENT.SeatAng = Angle(0, -90, -5)
ENT.StartColor = Color(151, 87, 87, 255)

function ENT:AddDataTables()
	local baseClass = scripted_ents.GetStored("lunasflightschool_atte")
	if not istable(baseClass) then return end
	baseClass = baseClass.t
	baseClass.AddDataTables(self)
	
	self:NetworkVar("Bool", 3, "IsLightOn")
end

function ENT:GetPassengerSeats()
	if not istable(self.pSeats) then
		self.pSeats = {}
		local DriverSeat = self:GetDriverSeat()

		for _, v in pairs(self:GetChildren()) do
			if v ~= DriverSeat and v:GetClass():lower() == "prop_vehicle_prisoner_pod" then
				table.insert(self.pSeats, v)
			end
		end

		local RearEnt = self:GetRearEnt()

		for _, v in pairs(RearEnt:GetChildren()) do
			if v ~= DriverSeat and v:GetClass():lower() == "prop_vehicle_prisoner_pod" then
				table.insert(self.pSeats, v)
			end
		end
	end

	return self.pSeats
end

sound.Add({
	name = "ATTE_STEP_SOFT",
	channel = CHAN_AUTO,
	volume = 1.0,
	level = 90,
	pitch = {95, 105},
	sound = {"KingPommes/starwars/atte/soft1.wav", "KingPommes/starwars/atte/soft2.wav", "KingPommes/starwars/atte/soft3.wav", "KingPommes/starwars/atte/soft4.wav",}
})

sound.Add({
	name = "ATTE_STEP_HARD1",
	channel = CHAN_AUTO,
	volume = 1.0,
	level = 90,
	pitch = {95, 105},
	sound = "KingPommes/starwars/atte/hard1.wav"
})

sound.Add({
	name = "ATTE_STEP_HARD2",
	channel = CHAN_AUTO,
	volume = 1.0,
	level = 90,
	pitch = {95, 105},
	sound = "KingPommes/starwars/atte/hard2.wav"
})