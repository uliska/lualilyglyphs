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


-- This is intentionally stored in a global variable
lilyglyphs = lua_formatters:new_client{
    name = 'lilyglyphs-core',
    namespace = {
        'lily'
    },
}
-- Store font ids for the optical sizes of the current music font
lilyglyphs._font_weights = {
        [11] = '', [13] = '', [14] = '', [16] = '',
        [18] = '', [20] = '', [23] = '', [26] = ''
}

--[[
    Internal functionality, to be used from the formatters, but not from outside
--]]

function lilyglyphs:get_glyph_by_name(name)
--[[
    Retrieve a (music) glyph through its (LilyPond) glyph name.
    Look up the font according to the currently active font weight,
    retrieve the slot id and return the code to create a character
    from it in LaTeX.
--]]
    local weight = tonumber(lilyglyph_opts.options.weight)
    local font_id = self._font_weights[weight]
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

function lilyglyphs:get_glyph_by_number(number)
--[[
    Simply return the code to create a character at the given code point.
--]]
    -- TODO: Is it possible to *check* whether a glyph is at that position?
    -- luaotfload.aux.name_of_slot(lilyglyphs._font_weights[weight], number)
    -- doesn't seem to return meaningful values.
    return string.format([[\char"%X]], number)
end

function lilyglyphs:process_design_options(options)
    --TODO: WIP
    return options
end

function lilyglyphs:_register_font_weight(weight, index)
--[[
    Store the font index for a font with a given size/weight index.
    This is implicitly called from \lilySetFont and shouldn't be
    used otherwise.
--]]
    lilyglyphs._font_weights[weight] = index
end


function lilyglyphs:scale_to_current_fontsize()
--[[
    Return a scaling factor for glyphimages to be adjusted relative to the
    current font size.
    10.95 is the "design size" for which the images have by default been
    compiled. (TODO: check if that is correct, with more examples).
    Image are scaled by this value depending on the current font size,
    and this takes effect in addition to any design or local scale options.
--]]
    return lib.current_font_size() / (65536 * 10.95)
end


--[[
    Create the generic formatters used by the actual commands
--]]

lilyglyphs:add_local_formatters{
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
            options = self:process_design_options(options)
            local scale = options.scale * self:scale_to_current_fontsize()
            local content = self:apply_template{
                scale = scale,
                image = image
            }
            return self:_format('output', {
                voffset = options.voffset,
                content = content
            })
        end,
    },
}


lilyglyphs:add_formatters('Handling choice of music font', 'lily', {
--[[
    Handling selecting music font and "weights"
    ("Weights" are actually optional sizes of the LilyPond fonts,
    weights 11, 13, 14, 16, 18, 20, 23, 26 are proceeding from bold to light)
--]]

    set_font = {
        comment = "Initialize a music font to be used",
        group_template = [[
\begingroup
<<<fonts>>>
\endgroup
]],
        template = [[
\fontspec{<<<font>>>-<<<weight>>>.otf}%%
\directlua{lilyglyphs:_register_font_weight(<<<weight>>>, font.current())}%%
]],
        func = function(self, name)
            lua_options.set_option('lilyglyphs','font', name)
            local results = {}
            for k, _ in pairs(lilyglyphs._font_weights) do
                table.insert(results, self:apply_template{
                    font = name,
                    weight = k
                })
            end
            return self:replace(self._group_template, table.concat(results, '\n'))
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

lilyglyphs:add_formatters('Handling the printing of music symbols from *font*', 'lily', {
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

    image = {
        comment = "Print an image file",
        desc    = [[

        ]],
        client_options = {
            lilyglyphs = { 'scale', 'voffset' }
        },
        func    = function(self, image, options)
            return self:_format('output_image', image, options)
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
        func    = function(self, text, options)
            return self:_format('output_text', text, options)
        end,
        color = 'nocolor',
    },
})

return lilyglyphs
