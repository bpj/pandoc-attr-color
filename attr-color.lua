--[==============================[
# attr-color.lua

A Pandoc filter which sets LaTeX text/background/frame color(s) on
Span and Div elements based on Pandoc attributes.

## Usage

See

## License

This software is Copyright (c) 2020 by Benct Philip Jonsson.

This is free software, licensed under:

  The MIT (X11) License

The MIT License

Permission is hereby granted, free of charge, to any person
obtaining a copy of this software and associated
documentation files (the "Software"), to deal in the Software
without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense,
and/or sell copies of the Software, and to permit persons to
whom the Software is furnished to do so, subject to the
following conditions:

The above copyright notice and this permission notice shall
be included in all copies or substantial portions of the
Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT
WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE AND NONINFRINGEMENT. IN NO EVENT
SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
CONNECTION WITH THE SOFTWARE OR THE USE OR
OTHER DEALINGS IN THE SOFTWARE.


--]==============================]

-- local dump = require"pl.pretty".dump -- for debugging

-- assert with format string
local function assertf (val, msg, ...)
  if val then return val end
  error(msg:format(...))
end

local rrggbb_keys = {'rr','gg','bb'}
local rgb_keys = {'r','g','b'}
local pats = {
  { keys = rrggbb_keys, pat = '^%#(%x%x)(%x%x)(%x%x)$' },
  { keys = rgb_keys, pat = '^%#(%x)(%x)(%x)$' },
  { keys = {'name'}, pat = '^(%a%w*)$' },
}

local color_attrs = {'fg','bg','fr'}

local tex_fmt = {
  fcolorbox = {
    pre  = '\\fcolorbox@(fr)@(bg){',
    post = '}',
  },
  colorbox = {
    pre  = '\\colorbox@(bg){',
    post = '}',
  },
  -- This is a 'pseudocommand',
  -- see https://tex.stackexchange.com/a/22928
  -- We might wish to define it but then the filter or
  -- the user will have to modify header-includes, so no!
  colorfbox = {
    pre  = '{\\colorlet{curcolor}{.}\\color@(fr)\\fbox{\\color{curcolor}',
    post = '}}',
  },
  -- Variation on colorfbox with a custom text/fg color to avoid redundancy
  -- although there will be some redundancy if the frame/text colors are
  -- the same, but can't check for that because User may say `{fr=blue fg="#00f"}`
  -- and knowing the values of named colors is too much work.
  textcolorfbox = {
    pre  = '{\\color@(fr)\\fbox{',
    post = '}}',
  },
  textcolor = {
    pre  = '\\textcolor@(fg){',
    post = '}',
  },
}

local function color2tex (name,value)
  local color
  for _,p in ipairs(pats) do
    local match = { value:match(p.pat) }
    if #match > 0 then
      for i,k in ipairs(p.keys) do
        match[k] = match[i]
      end
      color = match
      break
    end
  end
  assertf(
    color, 'Bad value for attribute %s: "%s"', name, value
  )
  if color.r then
    for _,x in ipairs(rgb_keys) do
      color[x .. x] = color[x] .. color[x]
    end
  end
  if color.rr then
    for _,xx in ipairs(rrggbb_keys) do
      color[xx] = color[xx]:upper()
    end
    color.name = color.rr .. color.gg .. color.bb
    color.model = '[HTML]'
  else
    color.model = "" -- named color
  end
  return color.model .. '{' .. color.name .. '}'
end

-- Interpolate table values into a string by replacing
-- placeholders of the form `@(KEY)` with the value of key KEY
local function interp (str, tab)
  local function _subst (k)
    return assertf(tab[k], "No value for key: %s", k)
  end
  return str:gsub('%@%(([^()]+)%)', _subst)
end

-- Generate the xcolor commands to 'wrap' around
-- the span contents according to which color attributes we found
local function make_tex (colors)
  -- The return values are two strings of raw LaTeX
  -- to put before and after the span contents.
  -- We always include a \strut to make sure that
  -- the box(es) be one \baselineskip high!
  local coms, pre, post = {}, {},{"\\strut"}
  if colors.fr then -- if frame
    if colors.bg then -- if also bground
      coms[#coms+1] = 'fcolorbox'
    elseif colors.fg then
      coms[#coms+1] = 'textcolorfbox'
    else
      coms[#coms+1] = 'colorfbox'
    end
  elseif colors.bg then
    coms[#coms+1] = 'colorbox'
  end
  if colors.fg then
    coms[#coms+1] = 'textcolor'
  end
  for _,com in ipairs(coms) do
    local com = assertf(
      tex_fmt[com],
      "No format for command: %s", com
    )
    pre[#pre+1] = interp(com.pre, colors)
    post[#post+1] = interp(com.post, colors)
  end
  pre = table.concat(pre)
  post = table.concat(post)
  return pre, post
end

local function color_span (elem)
  local colors
  for _,name in ipairs(color_attrs) do
    value = elem.attributes[name]
    if value then
      colors = colors or {}
      colors[name] = color2tex(name,value)
    end
  end
  if colors then
    local pre, post = make_tex(colors)
    return{
      pandoc.RawInline('latex', pre),
      elem,
      pandoc.RawInline('latex', post),
    }
  end
  return nil
end

-- -- for debugging without pandoc
-- local read = require"pl.pretty".read
-- for line in io.lines() do
--   colors = assert(read(line))
--   for _,name in ipairs(color_attrs) do
--     if colors[name] then
--       colors[name] = color2tex(name, colors[name])
--     end
--   end
--   print(line)
--   print( make_tex(colors) )
-- end

return {
  { Span = color_span },
  { Link = color_span },
}

