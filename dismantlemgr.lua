
_fmt = string.format

class 'CDismantleMgr'
function CDismantleMgr:__init(app)
  self.app = app
  self.font = app.DirectX:CreateFont(20, 15, 700, false, "Arial")  
  self.enabled = false
  self.time_last = 0
  self.interval = 2000
  print("CDismantleMgr") --debug
end


function CDismantleMgr:GetClientTime()
  return self.app.Game:GetMainSystem():GetClientTime()
end

function CDismantleMgr:Dismantle()
  local interval = self:GetClientTime() - self.time_last
  if interval < self.interval then
    return
  end
    
  self.app.Game:DismantleItems(0,36)
  
  self.time_last = self:GetClientTime()  
end

function CDismantleMgr:OnUpdate()
  local status = "OFF"
  local color = clRed
  if self.enabled then
    status = "ON"
	color = clGreen
  end
  self.font:Draw(340,100,0,0, color, string.format("Dismantling system %s", status))
end

function CDismantleMgr:WindowProc(msg)
  if msg.message == WM_KEYUP then
    if msg.wParam == VK_F3 then
	  self.enabled = not self.enabled
	end
  end
end