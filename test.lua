local WM_KEYDOWN   = 0x0100
local WM_KEYUP     = 0x0101
local WM_MOUSEMOVE = 0x0200

local VK_F2 = 113

local g_FontScriptDesc = g_App.DirectX:CreateFont(
  20, -- x
  10, -- y 
  400, -- FW_NORMAL
  false, -- italic
  "Arial" -- font name
)
  
local g_FontMyPCInfo = g_App.DirectX:CreateFont(18, 10, 400, false, "Arial");

local clRed = ARGB(255,255,0,0)
local clBlue = ARGB(255,0,0,255)
local clLightBlue = ARGB(255,0,255,255)
local clYellow = ARGB(255,255,255,0)

local g_CursorPos = Vector2(0,0)

local g_bMove = false

local g_lastTime = 0

function DisplayDescription(x,y, color, text)
  g_FontScriptDesc:Draw(x,y,0,0, color, text)
end

function GetDistance(p1, p2)
  local fLen = (p2.x - p1.x) * (p2.x - p1.x) + (p2.y - p1.y) * (p2.y - p1.y) + (p2.z - p1.z) * (p2.z - p1.z);
  if fLen > 0 then
	return math.sqrt(fLen)
  end
  return 0
end

function DrawArea(camera, range, pos)
  local step = (math.pi * 2) / 30 -- 30 is the precision, a higher value will increase a lot the cpu usage
  local a = 0.0;
  
  local sp = Vector3(0,0,0)
  local ep = Vector3(0,0,0)
	
  local oldpos = Vector3(0,0,0)
  local newpos = Vector3(0,0,0)
  
  if not camera:WorldToScreen(pos, newpos) then --first checks if the object is in screen space
    return
  end
        
  repeat  
    oldpos.x = (range * math.cos(a)) + pos.x
    oldpos.y = (range * math.sin(a)) + pos.y
    oldpos.z = pos.z
	
	a = a + step
	
	newpos.x = (range * math.cos(a)) + pos.x
	newpos.y = (range * math.sin(a)) + pos.y
	newpos.z = pos.z
  	    		
	if camera:WorldToScreen(newpos, sp) and camera:WorldToScreen(oldpos, ep) then	  
	  g_App.DirectX:Draw2DLine(sp.x,sp.y,ep.x,ep.y,1,clYellow)	  
	end		
  until a >= math.pi * 2
end

function OnUpdate()
  --DisplayDescription(100, 200, clRed, string.format("test %d", 123))
    
  local myPC = g_App.Game:GetMyPC()
  
  if not myPC then
    return
  end
    
  local game = g_App.Game
  local camera = game:GetCamera()
  
  --[[
  if g_bMove then
	  g_App.Game:Move2D(g_CursorPos)
	  g_bMove = false
  end
  --]]
  
  --g_App.DirectX:Draw2DLine(100,200,200, 400,2.0,clYellow)
    
  local entities = game:GetObjects()
      
  for i = 1, #entities do         
	local screen = Vector3(0,0,0)		
    local pc = entities[i]   
	local oid = pc:GetOID()
	    		
	if oid ~= 2 and pc:GetType() ~= 2 then

	  if oid ~= myPC:GetOID() then
	  --if true then

	    local pos = pc:GetPos()
	    DrawArea(camera, 4 * 100, pos) --4m is most monsters agro range
	  
	    if camera:WorldToScreen(pos,screen) then
		  		  
	      --g_FontMyPCInfo:Draw(screen.x,screen.y,0,0,clRed, string.format("%1.0f %1.0f %1.0f", pos.x, pos.y, pos.z))
		  
		  g_FontMyPCInfo:Draw(screen.x,screen.y,0,0,clYellow, string.format("%1.0fm %d", GetDistance(myPC:GetPos(), pos)/100, pc:GetSubState() ))
		end
	  else
	    -- this is my own character
		if camera:WorldToScreen(myPC:GetPos(),screen) then
		  --g_FontMyPCInfo:Draw(screen.x,screen.y,0,0,clRed, string.format("%d - %d", myPC:GetState(), myPC:GetSubState()))
		  DrawArea(camera, 50, myPC:GetPos())
		end		
	  end
	end
  end
end

function bytes(buf)
  result = "";
  for i = 1, string.len(buf), 1 do 
     result = string.format("%s%02X ", result, string.byte(buf, i))
  end
  return result
end

function OnSendPacket(p)
  --[[
  if p:dec2() == 0x1F then
    --print(">> "..bytes(p:getBuffer()))
	
	g_App:KeyDown(0x2E)
	g_App:KeyUp(0x2E)	
  end
  --]]
end

function WindowProc(msg)
-- msg.hwnd
-- msg.message
-- msg.wParam
-- msg.lParam

  if msg.message == WM_KEYUP then
    if msg.wParam == VK_F2 then
	  
      g_bMove = true
	  
	end
  elseif msg.message == WM_MOUSEMOVE then
    g_CursorPos.x = tonumber(LOWORD(msg.lParam))
	g_CursorPos.y = tonumber(HIWORD(msg.lParam))
	--print(string.format("%f,%f", g_CursorPos.x, g_CursorPos.y))
  end	
end

function Initialize()
  print("test script init")
  g_App:RegisterEventListener(EVENT_FRAMERENDER_UPDATE, OnUpdate)
  --g_App:RegisterEventListener(EVENT_OUTPACKET, OnSendPacket)
  --g_App:RegisterEventListener(EVENT_WINDOWPROC, WindowProc)
end

Initialize()
