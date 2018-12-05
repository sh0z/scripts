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

function DisplayDescription(x,y, color, text)
  g_FontScriptDesc:Draw(x,y,0,0, color, text)
end

function DrawArea(camera, range, pos)
  local step = (math.pi * 2.0) / 60.0;
  local a = 0.0;
  
  local oldpos = Vector3(0,0,0)
  local newpos = Vector3(0,0,0)
    
  oldpos.x = (range * math.cos(a)) + pos.x
  oldpos.y = (range * math.sin(a)) + pos.y
  oldpos.z = pos.z
    
  repeat
    
    a = a + step
	
    newpos.x = (range * math.cos(a)) + pos.x
	newpos.y = (range * math.sin(a)) + pos.y
	newpos.z = pos.z
	
	local sp = Vector3(0,0,0)
	local ep = Vector3(0,0,0)
    		
	if camera:WorldToScreen(newpos, sp) and camera:WorldToScreen(oldpos, ep) then
	  --g_App.DirectX:Draw2DLine(sp.x,sp.y,ep.x,ep.y,2.0,clYellow)	  
	  oldpos = newpos	  
	  g_FontMyPCInfo:Draw(sp.x, sp.y, 0, 0, clBlue, ".")
	end
		
  until a > math.pi * 2.0
end

function OnUpdate()
  --DisplayDescription(100, 200, clRed, string.format("test %d", 123))
    
  local myPC = g_App.Game:GetMyPC()
  
  if not myPC then
    return
  end
    
  local game = g_App.Game
  local camera = game:GetCamera()
  
  if g_bMove then
	  g_App.Game:Move2D(g_CursorPos)
	  g_bMove = false
  end
    
  local entities = game:GetObjects()
      
  for i = 1, #entities do         
	local screen = Vector3(0,0,0)		
    local pc = entities[i]   
	local oid = pc:GetOID()
		
	if oid ~= 2 then

	  --if oid ~= myPC:GetOID() then
	  if true then

	    local pos = pc:GetPos()
	      DrawArea(camera, 60.0, pos)
	  
	    if camera:WorldToScreen(pos,screen) then
		  		  
	      --g_FontMyPCInfo:Draw(screen.x,screen.y,0,0,clRed, string.format("%1.0f %1.0f %1.0f", pos.x, pos.y, pos.z))
		  
		  g_FontMyPCInfo:Draw(screen.x,screen.y,0,0,clYellow, string.format("%s State: %d", pc:GetNameA(), pc:GetState()))
		end
	  else
	    -- this is my own character
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
  if p:dec2() == 0x1F then
    print(">> "..bytes(p:getBuffer()))
  end
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
  print("Script init")
  g_App:RegisterEventListener(EVENT_FRAMERENDER_UPDATE, OnUpdate)
  --g_App:RegisterEventListener(EVENT_OUTPACKET, OnSendPacket)
  g_App:RegisterEventListener(EVENT_WINDOWPROC, WindowProc)
end

Initialize()
