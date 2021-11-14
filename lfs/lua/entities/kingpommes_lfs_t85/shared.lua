ENT.Type            = "anim"
DEFINE_BASECLASS( "lunasflightschool_basescript" )

ENT.PrintName = "T85 X-Wing"
ENT.Author = "Jakob Sailer aka KingPommes"
ENT.Information = ""
ENT.Category = "[LFS] KingPommes"

ENT.Spawnable		= true
ENT.AdminSpawnable	= false

ENT.MDL = "models/kingpommes/starwars/t85xwing/t85_xwing.mdl"

ENT.GibModels = {
	"models/XQM/wingpiece2.mdl",
	"models/XQM/wingpiece2.mdl",
	"models/XQM/jetwing2medium.mdl",
	"models/XQM/jetwing2medium.mdl",
	--"models/props_phx/misc/propeller3x_small.mdl",
	"models/props_c17/TrapPropeller_Engine.mdl",
	"models/props_junk/Shoe001a.mdl",
	"models/XQM/jetbody2fuselage.mdl",
	"models/XQM/jettailpiece1medium.mdl",
	"models/XQM/pistontype1huge.mdl",
}

ENT.AITEAM = 2

ENT.Mass = 5000 -- lower this value if you encounter spazz
ENT.Inertia = Vector(250000,250000,250000) -- you must increase this when you increase mass or it will spazz
ENT.Drag = -1 -- drag is a good air brake but it will make diving speed worse

--ENT.HideDriver = true -- hide the driver?
ENT.SeatPos = Vector(30,0,-7)
ENT.SeatAng = Angle(0,-90,0)

ENT.WheelMass = 800
ENT.WheelRadius = 5
ENT.WheelPos_L = Vector(-46,67.5,-49)
ENT.WheelPos_R = Vector(-46,-67.5,-49)
ENT.WheelPos_C = Vector(166,0,-49)

ENT.IdleRPM = 1 -- idle rpm. this can be used to tweak the minimum flight speed
ENT.MaxRPM = 2200 -- rpm at 100% throttle
ENT.LimitRPM = 3000 -- max rpm when holding throttle key
ENT.RPMThrottleIncrement = 1000 -- how fast the RPM should increase/decrease per second

ENT.RotorPos = Vector(160,0,0) -- make sure you set these correctly or your plane will act wierd.
ENT.WingPos = Vector(50,5,20) -- make sure you set these correctly or your plane will act wierd. Excessive values can cause spazz.
ENT.ElevatorPos = Vector(-150,5,20) -- make sure you set these correctly or your plane will act wierd. Excessive values can cause spazz.
ENT.RudderPos = Vector(-150,5,20) -- make sure you set these correctly or your plane will act wierd. Excessive values can cause spazz.

ENT.MaxVelocity = 3000 -- max theoretical velocity at 0 degree climb
--ENT.MaxPerfVelocity = 2500 -- speed in which the plane will have its maximum turning potential

ENT.MaxThrust = 25000 -- max power of rotor

ENT.MaxTurnPitch = 600 -- max turning force in pitch, lower this value if you encounter spazz
ENT.MaxTurnYaw = 600 -- max turning force in yaw, lower this value if you encounter spazz
ENT.MaxTurnRoll = 250 -- max turning force in roll, lower this value if you encounter spazz

ENT.MaxHealth = 800
ENT.MaxShield = 200  -- uncomment this if you want to use deflector shields. Dont use excessive amounts because it regenerates.
ENT.RepairValue = 10 -- the amount the astromech repairs the ship every 0.5 if IN_ATTACK1 is pressed

ENT.Stability = 0.7   -- if you uncomment this the plane will always be able to turn at maximum performance. This causes MaxPerfVelocity to get ignored
ENT.MaxStability = 0.7 -- lower this value if you encounter spazz. You can increase this up to 1 to aid turning performance at MaxPerfVelocity-speeds but be careful

ENT.VerticalTakeoff = true -- move vertically with landing gear out? REQUIRES ENT.Stability
ENT.VtolAllowInputBelowThrottle = 10 -- number is in % of throttle. Removes the landing gear dependency. Vtol mode will always be active when throttle is below this number. In this mode up movement is done with "Shift" key instead of W
ENT.MaxThrustVtol = 10000 -- amount of vertical thrust

ENT.MaxPrimaryAmmo = 800   -- set to a positive number if you want to use weapons. set to -1 if you dont
ENT.MaxSecondaryAmmo = 8 -- set to a positive number if you want to use weapons. set to -1 if you dont

-- function ENT:AddDataTables() -- use this to add networkvariables instead of ENT:SetupDataTables().
-- 	--[[DO NOT USE SLOTS SMALLER THAN 10]]--
-- 	self:NetworkVar("Float", 10, "BoostAdd")
-- 	--self:NetworkVar("Bool", 11, "Wings")
-- end

sound.Add ( {
	name = "T85_START",
	channel = CHAN_STATIC,
	volume = 0.5,
	level = 125,
	pitch = { 75, 120 },
	sound = "kingpommes/starwars/t85xwing/startup.wav",
} )

sound.Add ( {
	name = "T85_IDLE",
	channel = CHAN_STATIC,
	volume = 0.8,
	level = 125,
	pitch = 50,
	sound = "kingpommes/starwars/t85xwing/idle.wav",
} )

sound.Add ( {
	name = "T85_STOP",
	channel = CHAN_STATIC,
	volume = 0.5,
	level = 125,
	pitch = { 75, 120 },
	sound = "kingpommes/starwars/t85xwing/shutdown.wav",
} )

sound.Add ( {
	name = "T85_BOOST",
	channel = CHAN_STATIC,
	volume = 1.0,
	level = 125,
	pitch = { 75, 120 },
	sound = "kingpommes/starwars/t85xwing/boost.mp3",
} )

sound.Add ( {
	name = "T85_BREAK",
	channel = CHAN_STATIC,
	volume = 1.0,
	level = 125,
	pitch = { 75, 120 },
	sound = "kingpommes/starwars/t85xwing/break.mp3",
} )

sound.Add ( {
	name = "T85_LGEAR",
	channel = CHAN_STATIC,
	volume = 0.5,
	level = 125,
	pitch = { 80, 110 },
	sound = "kingpommes/starwars/t85xwing/landing_gear.wav",
} )

sound.Add ( {
	name = "T85_WINGS",
	channel = CHAN_STATIC,
	volume = 1.0,
	level = 125,
	pitch = { 70, 75 },
	sound = "kingpommes/starwars/t85xwing/s_foils.wav",
} )

sound.Add ( {
	name = "T85_COCKPIT",
	channel = CHAN_STATIC,
	volume = 0.5,
	level = 125,
	pitch = { 75, 120 },
	sound = "kingpommes/starwars/t85xwing/cockpit.wav",
} )

sound.Add ( {
	name = "T85_FIRE",
	channel = CHAN_WEAPON,
	volume = 1.0,
	level = 125,
	pitch = { 95, 105 },
	sound = "kingpommes/starwars/t85xwing/fire.wav",
} )

sound.Add ( {
	name = "T85_PROTON",
	channel = CHAN_WEAPON,
	volume = 1.0,
	level = 125,
	pitch = { 70, 110 },
	sound = "kingpommes/starwars/t85xwing/torpedo.wav",
} )

sound.Add ( {
	name = "T85_REPAIR",
	channel = CHAN_STATIC,
	volume = 1.0,
	level = 125,
	pitch = { 70, 110 },
	sound = {
		"ambient/energy/spark1.wav",
		"ambient/energy/spark2.wav",
		"ambient/energy/spark3.wav",
		"ambient/energy/spark4.wav",
		"ambient/energy/spark5.wav",
		"ambient/energy/spark6.wav",
	}
} )
