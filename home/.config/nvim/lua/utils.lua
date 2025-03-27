local M = {}

M.create_get_opts = function(lhs)
	return function(rhs)
		local merged = {}
		for k, v in pairs(lhs) do
			merged[k] = v
		end
		for k, v in pairs(rhs) do
			merged[k] = v
		end
		return merged
	end
end

M.border = "solid"

return M
