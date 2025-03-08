
CD2.ProgressBars = {}

-- Registers a progress bar that will be shown near the given entity
-- Return true in the drawfunc to prompt the handler to bump the next progress bar down so they don't overlap.
-- This should never happen but this is just incase the map generator decides to place things with progress bars near each other
function CD2:SetupProgressBar( ent, range, drawfunc )
    self.ProgressBars[ #self.ProgressBars + 1 ] = { ent = ent, range = range ^ 2, drawfunc = drawfunc }
end

function CD2.HUDCOMPONENENTS.components.ProgressBars( ply, scrw, scrh, hudscale )
    local drawnindex = 0
    for i, progressbar in ipairs( CD2.ProgressBars ) do
        if !IsValid( progressbar.ent ) then table.remove( CD2.ProgressBars, i ) continue end
        if ply:SqrRangeTo( progressbar.ent ) < progressbar.range then
            local result = progressbar.drawfunc( ply, drawnindex )

            if result then
                drawnindex = drawnindex + 1
            end
        end
    end
end