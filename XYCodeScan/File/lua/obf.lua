local uglify = require "uglify"
local minify = require "minify"
args = args or arg
setmetatable(_G, {
    __newindex = function(_, name, value)
        error(string.format("CANNOT SET GLOBAL VARIABLE: %s", name), 0)
    end
})

local input, output, isminify ,isuglify
local len = #args

local i = 1
while i <= len do
    if args[i] == "--minify" then
        isminify = true
        i = i + 1
    elseif args[i] == "--uglify" then
        isuglify = true
        i = i + 1
    elseif args[i] == "--input" then
        i = i + 1
        if i <= len then
	        input = args[i]
	        i = i + 1
       	end
    elseif args[i] == "--output" then
        i = i + 1
        if i <= len then
	        output = args[i]
	        i = i + 1
       	end
    else
        i = i + 1
    end
end

if input then
    if not output then
        output = input
    end
    if isminify then
    	minify.run(input, output)
   	end
    if isuglify then
    	uglify.run(input, output)
   	end
end
