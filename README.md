# Replicate 
A networking framework to read and write tables efficiently for Garry's Mod.

## What is it?
Replicate has been made as a replacement for `net.ReadTable()` and `net.WriteTable()`.
It requires a little bit more setting up for tables, but once done, will handle networking these efficiently and effortlessly.

## Why do I see `net.ReadTable()` and `net.WriteTable()` in the code then?

This library does not make use of these, except for the following reasons:

- You're networking a table that wasn't setup (i.e. your fault.)
- You're networking a nil table (net.WriteTable() is fine since it'll just say it's nil, it isn't costly at all)

I'm looking at you `gmodstore`, this library's usage of the functions shouldn't be "prohibited" as long as the developers respect the usage.

## Usage
This assumes your tables are already metatables, if not, check this [wiki page](https://wiki.facepunch.com/gmod/Object_Oriented_Lua#method2metatables) out.

First, you need to add the `GetReplicatedProperties(rt)` function to your metatable.
This function is used to generate a "ReplicationTemplate" for your table, and will let Replicate handle networking automatically.

You must add each property you wish to network, as they will be the only ones sent.
```lua
function ReplicatedTable:GetReplicatedProperties(rt)
rt:AddString("name")
rt:AddUInt("money",  32)
rt:AddBool("has_team")

-- Properties can have replication conditions, and will be sent if the condition returns true.
rt:AddColor("team_color")
  :SetReplicationCondition(function(tbl)  return tbl.has_team end)

-- They can also depend on other properties, and will only be sent if the dependency was replicated.
rt:AddColor("secondary_color")
  :SetDependsOn("team_color")
  
-- You can replicate lists, the values will be sent.
-- The last argument is the number of bits that may represent the maximum amount of elements in the list.
rt:AddOrderedList("inventory", ReplicationType.String, 8)
end
```
You must then call `Replicate.SetupMetaTable()` at the end of your table.
```lua
setmetatable(ReplicatedTable,  {__call = ReplicatedTable.new})
-- The second argument is a debug/friendly name to give to your metatable.
Replicate.SetupMetaTable(ReplicatedTable,  "ReplicatedTable")
```

Replicate will generate everything needed to network your table (or throw an error if you've done something wrong!)
You can check the example metatable [here](https://github.com/Erlite/Replicate/blob/master/lua/replicate/example.lua).

## Supported types
Every type supported by the [net library](https://wiki.facepunch.com/gmod/net) is supported, as well as some custom helpers. You can find the complete list [here](https://github.com/Erlite/Replicate/blob/master/lua/replicate/rep_property.lua).

## Sending the table
Instead of using `net.WriteTable()`, you simply call `Replicate.WriteTable()`
```lua
net.Start("MyNetMessage")
	Replicate.WriteTable(tbl)
net.SendToServer()
```
Be careful: any table that isn't registered or doesn't have a metatable will default to `net.WriteTable()`

## Receiving the table.

Same as above, but using `Replicate.ReadTable()`. You must supply the meta table to grab a template from.
```lua
net.Receive("MyNetMessage", function(len, ply)
	local tbl = Replicate.ReadTable(MyMetaTable)
end)
```
