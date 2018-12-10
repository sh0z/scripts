require 'maps\\luluvillage'

_fmt = string.format

class 'CMapMgr'
function CMapMgr:__init(app)
  self.spots = luluvillage_spots
  
  print("CMapMgr()") --debug
end

function CMapMgr:DebugSpots(priestBot)
  for i = 1, #self.spots do
    local spot = self.spots[i]
	priestBot:DrawArea(priestBot.camera, spot.radius*100, clGreen, spot.pos) --4m radius
  end
end

function CMapMgr:Debug(priestBot)
  self:DebugSpots(priestBot)

  local pos = priestBot.myPC:GetPos()
  local out = Vector3(0,0,0)
  
  if priestBot.camera:WorldToScreen(pos, out) then
    priestBot.fontObjectList:Draw(out.x, out.y - 20, 0, 0, clGreen, _fmt("%1.0f %1.0f %1.0f", pos.x, pos.y, pos.z))
  end
end
