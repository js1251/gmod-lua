------------------------------------
------ Created by Jakob Sailer -----
------ LFS Base by blu / Luna ------
----------- DO NOT edit or ---------
------------ reupload!! ------------
------------------------------------

AddCSLuaFile()

ENT.Type = "anim"
ENT.PrintName = "AT-AT FootCollider"
ENT.Author = "Jakob Sailer aka KingPommes"
ENT.DoNotDuplicate = true
ENT.IdentifiesAsLFS = true

if SERVER then
	-- Override
	function ENT:Initialize()
		self:SetModel("models/kingpommes/starwars/atat/atat_collider_foot.mdl")
		self:PhysicsInit(SOLID_VPHYSICS)
		self:SetMoveType(MOVETYPE_VPHYSICS)
		self:SetSolid(SOLID_VPHYSICS)
		self:SetRenderMode(RENDERMODE_TRANSALPHA)
		self:SetColor(Color(0, 0, 0, 0))
		self:DrawShadow(false)
	end

	function ENT:Touch(ent)
		if not IsValid(self.baseEnt) then return end
		local baseVelocity = self.baseEnt.smSpeed
		if (baseVelocity == nil) then return end
		local lift = math.abs(self:GetPos().z - ent:GetPos().z)
		if baseVelocity > 2 and lift > 32 then
			ent:TakeDamage(baseVelocity * 0.5, self, self)
		end
	end
end