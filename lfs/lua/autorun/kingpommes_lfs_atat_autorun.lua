if SERVER then
	hook.Add("OnEntityCreated", "KingPommes.ATAT.LAATC_DROPPER", function(ent)
		if ent:GetClass() ~= "lunasflightschool_laatcgunship" and ent.Base ~= "lunasflightschool_laatcgunship" then return end
		if not isfunction(ent.CanDrop) then return end

		-- backup the old function
		ent.CanDropOld = ent.CanDrop

		-- override the CanDrop function
		ent.CanDrop = function()
			-- if the held vehicle is the atat always allow it to be dropped. Else return the regulat function
			if ent:GetHeldEntity():GetClass() == "kingpommes_lfs_atat" then
				return true
			else
				return ent.CanDropOld(ent)
			end
		end
	end)
end

if CLIENT then
	killicon.Add( "kingpommes_lfs_atat_footcollider", "HUD/killicons/atat_crushed", Color( 255, 80, 0, 255 ) )
	killicon.Add( "kingpommes_lfs_atat_head", "HUD/killicons/atat_shot", Color( 255, 80, 0, 255 ) )
	killicon.Add( "kingpommes_lfs_atat", "HUD/killicons/atat_shot", Color( 255, 80, 0, 255 ) )
	language.Add( "kingpommes_lfs_atat_footcollider", "AT-AT" )
end

local Category = "Map Utilities"

local function StandAnimation( vehicle, player )
	return player:SelectWeightedSequence( ACT_HL2MP_IDLE )
end

local Seat = {
	Name = "Standing Seat",
	Model = "models/kingpommes/starwars/misc/seats/seat_stand.mdl",
	Class = "prop_vehicle_prisoner_pod",
	Category = Category,

	Author = "KingPommes",
	Information = "Seat with a standing animation",
	Offset = 16,

	KeyValues = {
		vehiclescript = "scripts/vehicles/prisoner_pod.txt",
		limitview = "0"
	},
	Members = {
		HandleAnimation = StandAnimation
	}
}

list.Set( "Vehicles", "kingpommes_lfs_seat_standing", Seat )
