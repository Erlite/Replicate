AddCSLuaFile()

ReplicatedTable = {}
ReplicatedTable.__index = ReplicatedTable

function ReplicatedTable.new()
    local tbl = 
    {
        name = "",
        money = 0,
        has_team = false,
        team_color = Color(0, 0, 0),
        secondary_color = Color(0, 0, 0),
        inventory = {},
    }

    setmetatable(tbl, ReplicatedTable)
    return tbl
end

function ReplicatedTable:GetReplicatedProperties(rt)
    rt:AddString("name")
    rt:AddUInt("money", 32)
    rt:AddBool("has_team")

    rt:AddColor("team_color")
        :SetReplicationCondition(function(tbl) return tbl.has_team end)
    rt:AddColor("secondary_color")
        :SetDependsOn("team_color")

    rt:AddOrderedList("inventory", ReplicationType.String)
end

setmetatable(ReplicatedTable, {__call = ReplicatedTable.new})
Replicate.SetupMetaTable(ReplicatedTable, "ReplicatedTable")