function trim(s)
  if s then
    return s:gsub("^%s*(.-)%s*$", "%1")
  end

  return ''
end

function encode_uri(s)
  if s then
    s = s:gsub("([^%w%.%- ])", function(c) return string.format("%%%02X", string.byte(c)) end)

    return s:gsub(" ", "+")
  end

  return ''
end

string.inner_attr = function (s, prefix, suffix)
    local inner = nil;
    local begin_idx = s:find(prefix, nil, true)
    local end_idx = nil
    if begin_idx then
        if suffix then
          end_idx = s:find(suffix, begin_idx + string.len(prefix), true)
        else
          end_idx = string.len(s) + 1
        end

        if end_idx then
            inner = s:sub(begin_idx + string.len(prefix), end_idx - 1)
        end
    end

    return inner, end_idx
end

string.onebyone_find = function (s, separator)
  local tbl = {}

  local prefix = separator
  local begin_idx = s:find(prefix, nil, true)
  while begin_idx do
    local suffix = prefix
    end_idx = s:find(suffix, begin_idx + prefix:len(), true)
    local item = nil
    if end_idx then
      item = s:sub(begin_idx, end_idx - 1)
    else
      item = s:sub(begin_idx, s:len() - 1)
    end
    
    table.insert(tbl, item)

    begin_idx = end_idx
  end

  return tbl
end

function string:split(inSplitPattern, outResults)
   if not outResults then
      outResults = { }
   end
   local theStart = 1
   local theSplitStart, theSplitEnd = string.find( self, inSplitPattern, theStart, true)
   while theSplitStart do
      table.insert(outResults, string.sub(self, theStart, theSplitStart - 1))
      theStart = theSplitEnd + 1
      theSplitStart, theSplitEnd = string.find(self, inSplitPattern, theStart, true)
   end
   table.insert(outResults, string.sub(self, theStart))

   return outResults
end

function string:replace(target, replacement)
  local tbl = {}

  if not target or string.len(target) == 0 then
    return self
  end

  if not replacement then
    replacement = ''
  end

  local last_begin_idx = 0
  local begin_idx, end_idx = self:find(target, nil, true)
  while begin_idx do
    table.insert(tbl, self:sub(last_begin_idx + 1, begin_idx - 1))
    table.insert(tbl, replacement)
    last_begin_idx = end_idx
    begin_idx, end_idx = self:find(target, last_begin_idx, true)
  end
  if last_begin_idx ~= self:len() then
    table.insert(tbl, self:sub(last_begin_idx + 1, self:len()))
  end

  return table.concat(tbl, '')
end

function string:size(font_size, max_width)
    local size = StringCalculateSize(self, font_size, max_width)
    return size
end
