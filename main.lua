
local g_FontScriptDesc = g_App.DirectX:CreateFont(20, 10, 400, false, "Arial");

local clRed = ARGB(255,255,0,0)

function DisplayDescription(x,y, color, text)
  g_FontScriptDesc:Draw(x,y,0,0, color, text)
end

function OnUpdate()
  -- DRAW YOUR STUFF HERE
  
  DisplayDescription(100, 200, clRed, string.format("test %d", 123))
  --[[
  local myPC = g_App.Game:GetMyPC()
  
  if not myPC then
    return
  end --]] 
  
--  local pos = myPC:GetPos()
  
  --print(string.format("%f %f %f", pos.x, pos.y, pos.z))
end

function bytes(buf)
  result = "";
  for i = 1, string.len(buf), 1 do 
     result = string.format("%s%02X ", result, string.byte(buf, i))
  end
  return result
end

function OnSendPacket(buf)
  --print(">> "..bytes(buf))
end

function WindowProc(msg)
  print("msgg")
end

function Initialize()
  print("Script init")
  g_App:RegisterEventListener(EVENT_FRAMERENDER_UPDATE, OnUpdate)
  g_App:RegisterEventListener(EVENT_INPACKET, OnSendPacket)
  g_App:RegisterEventListener(EVENT_WINDOWPROC, WindowProc)
end

Initialize()





