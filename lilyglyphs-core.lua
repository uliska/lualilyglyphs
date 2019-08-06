local err, warn, info, log = luatexbase.provides_module({
    name               = "lyluatexmp-formatters",
    version            = '0.1',
    date               = "2019/05/11",
    description        = "Lua formatters for the lyluatexmp package.",
    author             = "Urs Liska",
    copyright          = "2019- Urs Liska",
    license            = "GPL 3",
})

local lilyglyph_opts = lua_options.client('lilyglyphs')
local lib = require(kpse.find_file('luaoptions-lib') or 'luaoptions-lib')

-- Store font ids for the optical sizes of the current music font
local font_sizes = {
    [11] = '', [13] = '', [14] = '', [16] = '',
    [18] = '', [20] = '', [23] = '', [26] = ''
}

core = lua_formatters:new_client{
    name = 'lilyglyphs-core',
    namespace = {
        'lily'
    }
}


--[[
    Internal functionality, to be used from the formatters, but not from outside
--]]

function core:get_glyph_by_name(name)
--[[
    Retrieve a (music) glyph through its (LilyPond) glyph name.
    Look up the font according to the currently active font weight,
    retrieve the slot id and return the code to create a character
    from it in LaTeX.
--]]
    local weight = tonumber(lilyglyph_opts.options.weight)
    local font_id = font_sizes[weight]
    local chr = luaotfload.aux.slot_of_name(font_id, name, false)
    if chr and type(chr) == "number" then
        -- TODO: Is it possible to return the character "as-is"?
        return string.format([[\char"%X]], chr)
    else
        warn(string.format([[
Trying to retrieve inexistent glyph %s
from font '%s'.
]], name, lilyglyph_opts.options.font))
        return [[\char"0]]
    end
end

function core:get_glyph_by_number(number)
--[[
    Simply return the code to create a character at the given code point.
--]]
    -- TODO: Is it possible to *check* whether a glyph is at that position?
    -- luaotfload.aux.name_of_slot(font_sizes[weight], number)
    -- doesn't seem to return meaningful values.
    return string.format([[\char"%X]], number)
end


core:add_local_formatters{
--[[
    These local formatters handle the printing to LaTeX,
    they should be used by the public formatters in this module.
    Actual commands have to use the public formatters,
    therefore we don't need to check options here.
--]]

    output = {
        comment = "Wrap final result in a raisebox",
        -- TODO: add options for horizontal padding
        template = [[\raisebox{<<<voffset>>>ex}{<<<content>>>}%%
]],
    },

    output_text = {
        comment = "Output 'text', handling the music font",
        template = [[
{\fontspec[Scale=<<<scale>>>]{<<<font>>>-<<<weight>>>.otf}<<<content>>>}%%
]],
        func = function(self, content, options)
            local content = self:apply_template{
                scale   = options.scale,
                font    = options.font,
                weight  = options.weight,
                content = content
            }
            return self:_format('output', {
                voffset = options.voffset,
                content = content
            })
        end,
    },

    output_image = {
        comment = "TBD: Output an image based music glyph",
        template = [[
\includegraphics[scale=<<<scale>>>]{<<<image>>>}%%
]],
        func = function(self, image, options)
            local content = self:apply_template{
                scale = options.scale,
                image = image
            }
            return self:_format('output', {
                voffset = options.voffset,
                content = content
            })
        end,
    },
}


core:add_formatters('Handling choice of music font', 'lily', {
--[[
    Handling selecting music font and "weights"
    ("Weights" are actually optional sizes of the LilyPond fonts,
    weights 11, 13, 14, 16, 18, 20, 23, 26 are proceeding from bold to light)
--]]

    set_font = {
        comment = "Initialize a music font to be used",
        template = [[
\begingroup
<<<fonts>>>
\endgroup
]],
        get_font = [[
\fontspec{<<<font>>>-<<<weight>>>.otf}%%
\directlua{lua_formatters:client('lilyglyphs-core').store_font(<<<weight>>>, font.current())}%%
]],
        func = function(self, name)
            lua_options.set_option('lilyglyphs','font', name)
            local result = ''
            for k, _ in pairs(font_sizes) do
                result = result..self:replace(self._get_font, {
                    font = name,
                    weight = k
                })
            end
            return self:apply_template(result)
        end,
        color = 'nocolor',
    },

    set_weight = {
        comment = "Set the 'weight' of the music font",
        func = function(self, weight)
            lilyglyph_opts:set_option('weight', weight)
            return ''
        end,
        color = 'nocolor'
    }
})

core:add_formatters('Handling the printing of music symbols from *font*', 'lily', {
--[[
    Public formatters with the fundamental and generic typesetting routines.
    These can be accessed from documents or from more specific commands.
--]]

    glyph = {
        comment = "Print a glyph from a (LilyPond) font",
        desc    = [[
            Print a glyph from a LilyPond font, looking it up
            by its glyph name (canonical way) or its
            Unicode number (not really stable).
        ]],
        client_options = {
            lilyglyphs = { 'scale', 'voffset', 'font', 'weight' }
        },
        func    = function(self, glyph, options)
            number = tonumber(glyph)
            if number then
                glyph = self:get_glyph_by_number(glyph)
            else
                glyph = self:get_glyph_by_name(glyph)
            end
            return self:format('lily.text', glyph, options)
        end,
        color = 'nocolor',
    },

    text = {
        comment = "Print some text (dynamics, number and + - . ,)",
        desc    = [[
            Print some text using a (LilyPond) font.
            This works only for a selection of characters:
            - dynamic letters (pfmrzs)
            - numbers
            - + - . ,
        ]],
        client_options = {
            lilyglyphs = { 'scale', 'voffset', 'font', 'weight' }
        },
        func    =
        function(self, text, options)
            return self:_format('output_text', text, options)
        end,
        color = 'nocolor',
    },
})

function core.store_font(size, index)
--[[
    Store the font index for a font with a given size/weight index.
    This is implicitly called from \lilySetFont and shouldn't be
    used otherwise.
--]]
    font_sizes[size] = index
end


return core
