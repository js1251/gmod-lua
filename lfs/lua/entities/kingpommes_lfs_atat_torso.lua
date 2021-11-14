AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "gmod_atte_rear"
ENT.PrintName = "AT-AT Torso"
ENT.Author = "Jakob Sailer aka KingPommes"
ENT.AutomaticFrameAdvance = true
ENT.DoNotDuplicate = true
ENT.IdentifiesAsLFS = true

if SERVER then
	-- Override
	function ENT:Initialize()
		self:SetModel("models/kingpommes/starwars/atat/atat_body.mdl")
		--self:PhysicsInit(SOLID_VPHYSICS)
		--self:SetMoveType(MOVETYPE_VPHYSICS)
		--self:SetSolid(SOLID_VPHYSICS)
		self:SetRenderMode(RENDERMODE_TRANSALPHA)
		self:SetUseType(SIMPLE_USE)
		self:AddFlags(FL_OBJECT)
		self:DrawShadow(true)
	end
end