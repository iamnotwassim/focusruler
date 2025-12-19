local serpent = require("ffi/serpent")
local logger = require("logger")

local M = {}

M.dump = function(obj)
    local serialized = serpent.block(obj, { comment = false, nocode = true })
    logger.info(serialized)
end

return M
