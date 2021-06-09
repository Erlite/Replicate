AddCSLuaFile()

Replicate = Replicate or {}
Replicate.Log = {}

function Replicate.Log.Info(...)
    MsgC(Color(255, 255, 255, 255), "Replicate: " , {...}, "\n")
end

function Replicate.Log.Warning(...)
    MsgC(Color(255, 166, 0), "Replicate: " , {...}, "\n")
end

function Replicate.Log.Error(...)
    MsgC(Color(255, 90, 90), "Replicate: " , {...}, "\n")
end