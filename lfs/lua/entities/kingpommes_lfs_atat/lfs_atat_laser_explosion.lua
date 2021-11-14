AddCSLuaFile()
DEFINE_BASECLASS("lfs_aat_laser_explosion")

function EFFECT:Render()
	local Scale = (self.DieTime - CurTime()) / self.LifeTime
	render.SetMaterial(self.mat)
	render.DrawSprite(self.Pos, 1200 * Scale, 1200 * Scale, Color(45, 219, 45))
end