---@meta

-- Busted exports luassert as the global `assert` inside a spec, but luassert's library declares only the class, so a
-- spec would otherwise see Lua's builtin and none of luassert's fields. The call signature keeps `assert(x)` valid in
-- the config itself, where `assert` is the builtin.
---@class luassert.global: luassert
---@operator call(value: any, message?: string): any

---@type luassert.global
assert = assert
