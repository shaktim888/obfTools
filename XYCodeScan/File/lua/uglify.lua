local llex = require "llex"

local function print_err(...)
    print("Error:", ...)
end

local function TryRemoveUtf8BOM(ret)
    if string.byte(ret,1)==239 and string.byte(ret,2)==187 and string.byte(ret,3)==191 then
        ret=string.char( string.byte(ret,4,string.len(ret)) )
    end
    return ret;
end

local function getFileName(filename)
    local fn_flag = string.find(filename, "\\")
    if fn_flag then
        return string.match(filename, ".+\\([^\\]*%.%w+)$")
    end
    fn_flag = string.find(filename, "/")
    if fn_flag then
        return string.match(filename, ".+/([^/]*%.%w+)$")
    end
end

local function shuffle(arr)
  local cursor = 1;
  for i = #arr, 1, -1 do
      local index = math.random(1, i)
      if index ~= i then
          arr[i], arr[index] = arr[index], arr[i]
      end
      cursor = cursor + 1
  end
  return arr
end

local function uglify_file(infile_fn, outfile_fn)
	local keywords = { "and", "break", "do", "else", "elseif",
    			"end", "false", "for", "function", "if",
        		"in", "local", "nil", "not", "or", "repeat",
            	"return", "then", "true", "until", "while" }
    local base_char = 128;
	local infile, err = io.open(infile_fn);
	if not infile then
		print_err("Can't open input file for reading: "..tostring(err));
		return;
	end

	local data = infile:read("*a");
	infile:close();
	data = TryRemoveUtf8BOM(data)
	
    local outfile, err = io.open(outfile_fn, "wb");
        if not outfile then
            print_err("Can't open output file for writing: "..tostring(err));
        return;
    end

	local shebang, newdata = data:match("^(#.-\n)(.+)$");
	local code = newdata or data;
	if shebang then
		outfile:write(shebang)
	end

	local dd = "["..string.char(base_char).."-"..string.char(base_char+#keywords-1).."]"
	while base_char + #keywords <= 255 and code:find("["..string.char(base_char).."-"..string.char(base_char+#keywords-1).."]") do
		base_char = base_char + 1;
	end
	if base_char + #keywords > 255 then
		-- Sorry, can't uglify this file :(
		-- We /could/ use a multi-byte marker, but that would complicate
		-- things and lower the compression ratio (there are quite a few 
		-- 2-letter keywords)
		outfile:write(code);
		outfile:close();
		return;
	end

	-- Write loadstring and open string
	local maxequals = 0;
	data:gsub("(=+)", function (equals_string) maxequals = math.max(maxequals, #equals_string); end);
	
	-- Go lexer!
	llex.init(code, "@"..infile_fn);
	llex.llex()
	local seminfo = llex.seminfo;
	
	if base_char+#keywords < 255 then
		-- Find longest TK_NAME and TK_STRING tokens
		local scores = {};
		for k,v in ipairs(llex.tok) do
			if v == "TK_NAME" or v == "TK_STRING" then
				local key = string.format("%q,%q", v, seminfo[k]);
				if not scores[key] then
					scores[key] = { type = v, value = seminfo[k], count = 0 };
					scores[#scores+1] = scores[key];
				end
				scores[key].count = scores[key].count + 1;
			end
		end
		for i=1,#scores do
			local v = scores[i];
			v.score = (v.count)*(#v.value-1)- #string.format("%q", v.value) - 1;
		end
		table.sort(scores, function (a, b) return a.score > b.score; end);
		local free_space = 255-(base_char+#keywords);
		for i=free_space+1,#scores do
			scores[i] = nil; -- Drop any over the limit
		end
	
		local base_keywords_len = #keywords;
		for k,v in ipairs(scores) do
			if v.score > 0 then
				table.insert(keywords, v.value);
			end
		end
	end
	
    shuffle(keywords);
	local keyword_map_to_char = {}

	for i , keyword in ipairs(keywords) do
		keyword_map_to_char[keyword] = string.char(base_char + i);
	end

	outfile:write("local base_char,keywords=", tostring(base_char), ",{");
	for _, keyword in ipairs(keywords) do
		outfile:write(string.format("%q", keyword), ',');
	end
	outfile:write[[}; local function prettify(code) return code:gsub("["..string.char(base_char).."-"..string.char(base_char+#keywords).."]", 
	function (c) return keywords[c:byte()-base_char]; end) end ]]
	
	outfile:write [[return assert(loadstring(prettify]]
	outfile:write("[", string.rep("=", maxequals+1), "[");
	
	-- Write code, substituting tokens as we go
	for k,v in ipairs(llex.tok) do
		if v == "TK_KEYWORD" or v == "TK_NAME" or v == "TK_STRING" then
			local keyword_char = keyword_map_to_char[seminfo[k]];
			if keyword_char then
				outfile:write(keyword_char);
			else -- Those who think Lua shouldn't have 'continue, fix this please :)
				outfile:write(seminfo[k]);
			end
		else
			outfile:write(seminfo[k]);
		end
	end

	-- Close string/functions
    outfile:write("]");
	outfile:write(string.rep("=", maxequals+1));
    outfile:write("]");
	outfile:write(", '@", getFileName(outfile_fn),"'))()");
	outfile:close();
end

return {
    run = uglify_file
}

