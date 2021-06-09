-- Licensed under MIT.
-- Enjoy!
AddCSLuaFile()

Replicate = Replicate or {}
Replicate.Funcs = Replicate.Funcs or {}
Replicate.Templates = Replicate.Templates or {}

function Replicate.SetupMetaTable(tbl, name)
    if not tbl or not istable(tbl) then
        error("Cannot setup a nil or invalid table.")
    end

    if not name or not isstring(name) or #name == 0 then
        error("You must provide a friendly name for the table!")
    end

    if not getmetatable(tbl) then
        error("Table must have a metatable set, normal tables will be networked with ReadTable()/WriteTable()")
    end

    if not tbl.GetReplicatedProperties then
        error("Table is missing the GetReplicatedProperties() function.")
    end

    local template = ReplicationTemplate()
    tbl:GetReplicatedProperties(template)
    template:SetName(name)

    if template:IsEmpty() then
        MsgC(Color(255, 196, 0), string.format("Metatable '%s' has no replicated properties!", template:GetName()), "\n")
        return
    end

    template:AssertValid()

    Replicate.Templates[getmetatable(tbl)] = template
    MsgC(Color(0, 255, 0), "Replicate: Registered metatable '", name, "'.", "\n")
end

function Replicate.WriteTable(tbl)
    -- Nil tables can just be written by WriteTable()
    if tbl == nil then
        Replicate.Log.Warning("Table is nil, writing using net.WriteTable()")
        net.WriteTable(tbl)
        return
    end

    -- Can't write anything other than a table.
    if not istable(tbl) then
        error("Expected to write a table, got: " .. type(tbl))
    end

    -- No metatable, use WriteTable()
    local meta = getmetatable(tbl)
    if not meta then
        Replicate.Log.Warning("Attempting to write a normal table, defaulting to net.WriteTable()")
        net.WriteTable(tbl)
        return
    end

    -- Unregistered metatables get the WriteTable() treatment.
    if not Replicate.Templates[meta] then
        Replicate.Log.Warning("Attempting to write an unregistered metatable, defaulting to net.WriteTable()")
        net.WriteTable(tbl)
        return
    end

    local template = Replicate.Templates[meta]
    Replicate.Log.Info(string.format("Starting to write using template '%s'.", template:GetName()))

    -- Write every registered property.
    for index, prop in ipairs(template:GetProperties()) do
        Replicate.WriteProperty(tbl, template, index, prop)
    end

    Replicate.Log.Info("Done!")
end

function Replicate.WriteProperty(tbl, template, index, prop)
    local depends_on = prop:GetDependsOn()

    -- This property depends on another. Let's check that the other was replicated.
    if depends_on then
        local _, dependency = template:GetPropertyByName(depends_on)
        if not dependency then
            error(string.format("Property '%s' depends on unknown dependency '%s'. This should never happen!", prop:GetName(), depends_on)
        end

        if not dependency:GetWasReplicated() then
            Replicate.Log.Warning(string.format("Skipping property '%s': dependency '%s' wasn't replicated.", prop:GetName(), depends_on))
            prop:SetWasReplicated(false)
            return
        end
    end

    -- Check if this property has a replication condition.
    local cond = prop:GetReplicationCondition()
    if cond then
        local shouldReplicate = cond(tbl)
        net.WriteBit(shouldReplicate)

        if not shouldReplicate then
            Replicate.Log.Warning(string.format("Skipping property '%s': replication condition not met.", prop:GetName()))
            prop:SetWasReplicated(false)
            return
        end
    end

    Replicate.Funcs["Write" .. prop:GetType()](prop, tbl[prop:GetName()])
    prop:SetWasReplicated(true)

    Replicate.Log.Info(string.format("Wrote property '%s' of type '%s'", prop:GetName(), propType))
end


--[[
    Write functions
--]]

function Replicate.Funcs.WriteString(prop, value)
    net.WriteString(value)
end

function Replicate.Funcs.WriteFloat(prop, value)
    net.WriteFloat(value)
end

function Replicate.Funcs.WriteDouble(prop, value)
    net.WriteDouble(value)
end

function Replicate.Funcs.WriteUInt(prop, value)
    Replicate.Funcs.Assert.IsValidBitAmount(prop:GetBits())
    net.WriteUInt(value, prop:GetBits())
end

function Replicate.Funcs.WriteInt(prop, value)
    Replicate.Funcs.Assert.IsValidBitAmount(prop:GetBits())
    net.WriteInt(value, prop:GetBits())
end

function Replicate.Funcs.WriteBool(prop, value)
    net.WriteBool(value)
end

function Replicate.Funcs.WriteBit(prop, value)
    net.WriteBit(value)
end

function Replicate.Funcs.WriteColor(prop, value)
    net.WriteColor(value)
end

function Replicate.Funcs.WriteVector(prop, value)
    net.WriteVector(value)
end

function Replicate.Funcs.WriteAngle(prop, value)
    net.WriteAngle(value)
end

function Replicate.Funcs.WriteEntity(prop, value)
    net.WriteEntity(value)
end

-- Haha recursion go brrrrt
function Replicate.Funcs.WriteTable(prop, value) 
    Replicate.WriteTable(value)
end

function Replicate.Funcs.WriteList(prop, value)
    net.WriteUInt(#value, prop:GetBits())

    local writeFunc = Replicate.Funcs["Write" .. prop:GetValueType()]
    for _, v in pairs(value) do
        writeFunc(prop, v)
    end
end

function Replicate.Funcs.WriteOrderedList(prop, value)
    net.WriteUInt(#value, prop:GetBits())

    local writeFunc = Replicate.Funcs["Write" .. prop:GetValueType()]
    for _, v in ipairs(value) do
        writeFunc(prop, v)
    end
end