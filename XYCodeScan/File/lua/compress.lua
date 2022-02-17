
args = args or arg

local compress = zlib.deflate()
local depress = zlib.inflate()

local folder = args[1];
local saveTo = args[2];
local pathPrefix = args[3] or ""
local allContent = ""

function string.ends(String,End)
   return End=='' or string.sub(String,-string.len(End))==End
end

function ignoreFiles(p)
    if not p then return true end
	local ignored = { ".", ".." , ".DS_Store", ".vscode" }
	for _, v in ipairs(ignored) do
		if v == p then
			return true
		end
	end
	return false
end

function watchDir(folder, root)
	for _f in lfs.dir(folder) do
		if not ignoreFiles(_f) then

	      	local curRoot
	      	if root ~= "" then
	      		curRoot = root .. "." .. _f
	      	else 
	      		curRoot = _f
	      	end
			local p = folder .. "/" .. _f
			local attr = lfs.attributes(p)
		    if attr.mode == "directory" then
		      	watchDir(p, curRoot)
			else
				if string.ends(p, ".lua") or string.ends(p, ".luac") then
					local file = io.open(p, "rb")
			      	local content = file:read("*all")
			      	file:close()
			      	curRoot = string.gsub(curRoot,"%.luac?$","")
					print(curRoot)
			      	allContent = allContent .. "[[" .. #curRoot .. "]]" .. curRoot
			      	allContent = allContent .. "[[" .. attr.size .. "]]" .. content
			   		if #content ~= attr.size then
			   			print("error:" , p)
			   		end
				end
			end
		end
	end

end
watchDir(folder, pathPrefix)

local function parseCode(code)
	local index = 0;
	local totalLen = #code
	local getNextLen = function()
		local s, e = string.find(code, "^%[%[%d*%]%]", index + 1)
		local val = string.sub(code, s + 2, e - 2) 
		index = e;
		return tonumber(val)
	end
	local getContent = function()
		local len = getNextLen();
		local val = string.sub(code, index + 1, index + len) 
		index = index + len
		return val
	end
	while(index < totalLen) do
		local name = getContent();
		-- print(name)
		local c = getContent();
		package.preload[name] = function()
			assert(load(c))()
		end
	end
end

function depressCode(path)
	local depress = zlib.inflate()
	local file = io.open(path, "rb")
  	local content = file:read("*all")
  	file:close()
	local depressContent = depress(content, "finish")
	parseCode(depressContent)
end

local afterContent = compress(allContent, "finish")

if saveTo then
	if not string.ends(saveTo, ".id") then
		saveTo = saveTo .. "/out.id"
	end
	local wf = io.open(saveTo, "wb")
	wf:write(afterContent)
	wf:close()
end

print("生成成功")
