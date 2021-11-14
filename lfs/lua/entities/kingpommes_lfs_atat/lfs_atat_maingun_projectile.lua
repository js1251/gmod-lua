
DEFINE_BASECLASS( "lfs_aat_maingun_projectile" )

if CLIENT then
	function ENT:Draw()
		local pos = self:GetPos()
		local dir = self:GetForward()
		local length = 100

        print(mat)

		render.SetMaterial( mat_laser )
		render.DrawBeam( pos + dir * length, pos, 40, 1, 0, Color(255,0,0,255) )
		render.DrawBeam( pos + dir * length, pos, 15, 1, 0, Color(255,255,255,255) )

		render.SetMaterial( mat )
		render.DrawSprite( pos + dir * length * 0.3, 100, 100, Color( 255, 0, 0, 255 ) )
		render.DrawSprite( pos + dir * length * 0.45, 100, 100, Color( 255, 0, 0, 255 ) )
		render.DrawSprite( pos + dir * length * 0.6, 100, 100, Color( 255, 0, 0, 255 ) )
		render.DrawSprite( pos + dir * length * 0.75, 100, 100, Color( 255, 0, 0, 255 ) )
		render.DrawSprite( pos + dir * length * 0.9, 100, 100, Color( 255, 0, 0, 255 ) )
	end
end