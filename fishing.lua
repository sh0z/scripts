local g_FishingBot = nil

class 'CFishingBot'
function CFishingBot:__init(app)
  self.app = app
  self.game = app.Game
  self.dx = app.DirectX
  self.fontStatus = self.dx:CreateFont(18, 10, 400, false, "Arial")  
  self.mainsystem = self.game:GetMainSystem()
  self.imgBtnBG = self.dx:CreateImageFromFile(app:GetDirectoryPath().."\\scripts\\images\\btnBG.png")
  self.enabled = false
  self.lbuttondown = false
  self.id = 0
  self.state = 1 
  self.mouse = Vector2(0,0)
  self.mouseClickPos = Vector2(0,0)
  self.time_last = 0
  self.buttonRect = {
    left = 220,
    top = 100,
	right = self.imgBtnBG.Width,
	bottom = self.imgBtnBG.Height
  }
  print("CFishingBot()") --debug
end

function CFishingBot:MousePtInRect(rect)
  return self.mouse.x > rect.left and self.mouse.x < rect.left + rect.right and
         self.mouse.y > rect.top and self.mouse.y < rect.top + rect.bottom
end

function CFishingBot:DrawButtonBG()  
  local transparencyText = 200
  local transparencyBG = 100
  local sBotStatus = "OFF"
  local clickedoffset = 0
   
  if self:MousePtInRect(self.buttonRect) then
    color = clGreen
	transparencyText = 255
	transparencyBG = 120
	
	if self.lbuttondown then
	  clickedoffset = 2
	end
  end
  
  local color = ARGB(transparencyText,255,0,0)
    
  if self.enabled then
    sBotStatus = "ON"
	color = ARGB(transparencyText,0,255,0)
  end
    
  self.imgBtnBG:Draw(self.buttonRect.left,self.buttonRect.top,transparencyBG)
  self.fontStatus:Draw(self.buttonRect.left + 10 + clickedoffset, self.buttonRect.top + 10 - clickedoffset, 0, 0, color, string.format("FishingBot: %s", sBotStatus))
end

function CFishingBot:ShowButton()
  self:DrawButtonBG()
end

function CFishingBot:DXUpdate()
  self:ShowButton()
end

function CFishingBot:WindowProc(msg)
  if msg.message == WM_KEYUP then
    if msg.wParam == VK_F3 then
      self.enabled = not self.enabled
	end
  elseif msg.message == WM_LBUTTONDOWN then
    self.mouseClickPos.x = self.mouse.x
	self.mouseClickPos.y = self.mouse.y
    self.lbuttondown = true	
  elseif msg.message == WM_LBUTTONUP then
    self.lbuttondown = false	
	if self:MousePtInRect(self.buttonRect) then
	  self.enabled = not self.enabled 
    end	
  elseif msg.message == WM_MOUSEMOVE then
    self.mouse.x = LOWORD(msg.lParam)
	self.mouse.y = HIWORD(msg.lParam)		 
  end	
end

function FishingBot_OnUpdate()
  g_FishingBot:DXUpdate()
end

function CFishingBot:GetClientTime()
  return self.mainsystem:GetClientTime()
end

function bytes(buf)
  result = "";
  for i = 1, string.len(buf), 1 do 
     result = string.format("%s%02X ", result, string.byte(buf, i))
  end
  return result
end

function FishingBot_OnSendPacket(p)
  --print(">> "..bytes(p:getBuffer()))
  local id = p:dec2()
  if id == 0x12 then  -- this packet is synchronizer, we can use it as our timer     
    local state = g_App.Game:GetMyPC():GetSubState()	
	local interval = g_FishingBot:GetClientTime() - g_FishingBot.time_last
	if interval < 500 then
	  return
	end
	g_FishingBot.time_last = g_FishingBot:GetClientTime()
		
	if g_FishingBot.id ~= 0 and g_FishingBot.enabled then
		
	  if state == 125 or state == 126 then
	    local out = COutPacket(0x73) -- throw
	    out:enc1(9)
		out:enc4(g_FishingBot.id)
		g_App.Game:SendPacket(out)	
	  elseif state == 127 then -- catch
	    local out = COutPacket(0x73)
        out:enc1(8)
        out:enc1(1)
        g_App.Game:SendPacket(out)
	  end
	end	
  elseif id == 0x73 then
    local action = p:dec1()
	if action == 9 then
	  g_FishingBot.id = p:dec4()
	end
  end
end

function FishingBot_WindowProc(msg)
  g_FishingBot:WindowProc(msg)
end

g_App:AllocConsole()
g_FishingBot = CFishingBot(g_App)
g_App:RegisterEventListener(EVENT_FRAMERENDER_UPDATE, FishingBot_OnUpdate)
g_App:RegisterEventListener(EVENT_WINDOWPROC, FishingBot_WindowProc)
g_App:RegisterEventListener(EVENT_OUTPACKET, FishingBot_OnSendPacket)

