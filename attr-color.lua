--[==============================[
# attr-color.lua

A Pandoc filter which sets text/background/frame color(s) on
Span and Link elements based on Pandoc attributes.

## Version

This is version 2020121418 of the filter.

## Usage

See https://github.com/bpj/pandoc-attr-color

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

-- This sets the defaults in case metadata/environment variables are unset
-- Feel free to change these in your local copy if you can find a good reason.
local config = {
  format = FORMAT,          -- (string) defaults to Pandoc's current output format
  keep_attrs = false,       -- must be a boolean
  fallback_format = 'html', -- string
}

-- local dump = require"pl.pretty".dump -- for debugging

-- assert with format string
local function assertf (val, msg, ...)
  if val then return val end
  error(msg:format(...))
end

-- Fall back to another value if a value is nil
local function if_nil (a,b)
  if nil == a then return b else return a end
end

-- Get the keys of a table as an array
local function keys_of (tab)
  local keys = {}
  for k in pairs(tab) do
    keys[#keys+1] = k
  end
  return keys
end

local rrggbb_keys = {'rr','gg','bb'}
local rgb_keys = {'r','g','b'}
local color_pats = {
  { keys = rrggbb_keys, pat = '^%#(%x%x)(%x%x)(%x%x)$' },
  { keys = rgb_keys, pat = '^%#(%x)(%x)(%x)$' },
  { keys = {'name'}, pat = '^(%a%w*)$' },
}

local color_attrs = {'fg','bg','fr'}

local latex_fmt = {
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

local css_fmt = {
  fg = 'color: @(fg);',
  bg = 'background-color: @(bg);',
  fr = 'border: 0.01em solid @(fr);',
}

local css_pad = {
  bg = true,
  fr = true,
}

local function color2latex (name,value)
  local color
  for _,p in ipairs(color_pats) do
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
local function make_latex (colors)
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
      latex_fmt[com],
      "No format for command: %s", com
    )
    pre[#pre+1] = interp(com.pre, colors)
    post[#post+1] = interp(com.post, colors)
  end
  pre = table.concat(pre)
  post = table.concat(post)
  return pre, post
end

local function add_style (elem, colors)
  local style = {}
  for k,v in pairs(css_pad) do
    if colors[k] then
      style[#style+1] = 'padding: 0.1em;'
      break
    end
  end
  for _,attr in ipairs(color_attrs) do
    if colors[attr] then
      style[#style+1] = interp(css_fmt[attr], colors)
    end
  end
  if #style > 0 then
    style = table.concat(style, " ")
    if elem.attributes.style then
      elem.attributes.style = elem.attributes.style:gsub(';?%s*$', "; ")
    else
      elem.attributes.style = ""
    end
    elem.attributes.style = elem.attributes.style .. style
    return elem
  end
  return nil
end

-- TODO: support ConTeXt if I can find out how to do frame and background on the fly.
formats = {
  latex = {
    name = 'latex',
    make_color  = color2latex,
    make_markup = make_latex,
  },
  html = {
    name = 'html',
    modify_elem = add_style,
  },
}

-- for _,key in ipairs{'html4', 'html5'} do
--   formats[key] = formats[html]
-- end

local function color_span (elem)
  local format = formats[config.format] or formats[config.fallback_format]
  if not format then return nil end
  local colors
  for _,name in ipairs(color_attrs) do
    value = elem.attributes[name]
    if value then
      colors = colors or {}
      if format.make_color then
        colors[name] = format.make_color(name,value)
      else
        colors[name] = value
      end
      if not config.keep_attrs then
        elem.attributes[name] = nil
      end
    end
  end
  if colors then
    if format.make_markup then
      local pre, post = format.make_markup(colors)
      return{
        pandoc.RawInline(format.name, pre),
        elem,
        pandoc.RawInline(format.name, post),
      }
    elseif format.modify_elem then
      return format.modify_elem(elem, colors)
    end
  end
  return nil
end

local str2bool = {
  ['true'] = true,
  ['false'] = false,
}

local function get_config (meta)
  for _,key in ipairs(keys_of(config)) do
    local dflt = config[key]
    meta_key = "attr_color_" .. key
    env = "PDC_ATTR_COLOR_" .. key:upper()
    val = if_nil(meta[meta_key], os.getenv(env))
    if nil ~= val then
      if 'table' == type(val) then
        val = pandoc.utils.stringify(val)
      end
      if 'boolean' == type(dflt) then
        val = str2bool[tostring(val):lower()]
        assertf(
          ('boolean' == type(val)),
          "Expected meta.%s or env %s to be 'true' or 'false'", meta_key, env
        )
      end
      config[key] = val
    end
  end
  return nil
end



-- -- for debugging without pandoc
-- local read = require"pl.pretty".read
-- for line in io.lines() do
--   colors = assert(read(line))
--   for _,name in ipairs(color_attrs) do
--     if colors[name] then
--       colors[name] = color2latex(name, colors[name])
--     end
--   end
--   print(line)
--   print( make_latex(colors) )
-- end

return {
  { Meta = get_config },
  { Span = color_span,
    Link = color_span,
  },
}

