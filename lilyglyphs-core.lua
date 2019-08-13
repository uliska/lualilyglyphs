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


-- `lilyglyphs` is a descendant of FormattersTable, a lua_formatters client,
-- and it is intentionally stored in a global variable.
lilyglyphs = lua_formatters:new_client{
    name = 'lilyglyphs-core',
    namespace = {
        'lily'
    },
}
-- Rebuild index method due to meddling with FormattersTable structure
lilyglyphs.__index = function(t, key)
    return lilyglyphs[key]
    or lua_formatters[key]
end

-- Store font ids for the optical sizes of the current music font
lilyglyphs._font_weights = {
        [11] = '', [13] = '', [14] = '', [16] = '',
        [18] = '', [20] = '', [23] = '', [26] = ''
}

function lilyglyphs:new_library(properties)
--[[
    Register a new library of lilyglyphs commands,
    this is a variant of lua_formatters:new_client(), creating a
    client with a mandatory 'lily-' prefix.
--]]
    if type(properties) == 'string' then
        properties = { name = 'lilyglyphs-'..properties }
    elseif properties.name then
        properties.name = 'lilyglyphs-'..properties.name
    else
        err([[
Trying to register lilyglyphs library
without providing a 'name' property.]])
end
    -- force a namespace including `lily.`
    properties.namespace = properties.namespace or {}
    if not lib.contains_key(properties.namespace, 'lily') then
        table.insert(properties.namespace, 'lily')
    end
    local library = lua_formatters:new_client(properties)
    setmetatable(library, self)
    library.__index = self
    return library
end

function lilyglyphs:add_library(library)
-- alias for use in lilyglyphs macro \addLilyglyphsLibrary
    return lua_formatters:add(library)
end


--[[
    Extending functionality of FormattersTable.
    lilyglyphs is a FormattersTable descendant with special support
    for adding lilyglyphs commands with as little redundancy as possible.
--]]

function lilyglyphs:add_command(key, client_options, properties)
--[[
    Generic function to add a lilyglyphs command.
    Enforces a `lily.` namespace, by default macros will be named
    \lilyNNN.
    client_options is an array with keys that are to be set as
    client_option values (=> all XXX commands have YYY as client options).
--]]
    local lily = key:find('lily')
    if not lily or lily == 1 then key = 'lily.'..key end

    --TODO: validate design options if given

    -- initialize client options for `lilyglyphs` key
    client_options = {
        lilyglyphs = client_options or {}
    }
    -- initialize *all* client options
    if properties.client_options then
        for client, options in pairs(properties.client_options) do
            client_options[client] = client_options[client] or {}
            for k,v in pairs(options) do
                client_options[client][k] = v
            end
        end
    end
    properties.client_options = client_options
    self:add_formatter(key, properties)
end

function lilyglyphs:add_glyph_command(key, properties)
--[[
    Add a single glyph command.
    Inject the formatter's design options into the function call.
    Specify client options.
--]]
    properties.func = function(self, options)
        options._design = self._design
        return self:format('lily.glyph', properties.glyph, options)
    end
    self:add_command(key,
        { 'scale', 'voffset', 'font', 'weight' },
        properties)
end

function lilyglyphs:add_glyph_commands(commons, definitions)
--[[
    Add a set of glyph commands.
    If two tables are given then the first is a "template" table
    whose values are injected into every command. This is to avoid
    redundant specification of e.g. design options.
--]]
    if not definitions then
        -- transpose the first table to `definitions`
        definitions = commons
        commons = {}
    end
    for key, properties in pairs(definitions) do
        -- inject commons
        for k,v in pairs(commons) do
            properties[k] = properties[k] or v
        end
        -- create command
        self:add_glyph_command(key, properties)
    end
end


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
    local font_id = lilyglyphs._font_weights[weight]
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

local function design_add(design_opt, loc_opt)
--[[
    Design option handler *adding* the value
--]]
    return tostring(tonumber(design_opt) + tonumber(loc_opt))
end

local function design_mult(design_opt, loc_opt)
--[[
    Design option handler *multiplying* the value
--]]
    return tostring(tonumber(design_opt) * tonumber(loc_opt))
end

-- Map design option to handlers
local design_handlers = {
    voffset = design_add,
    scale = design_mult
}
function lilyglyphs:process_design_options(options)
--[[
    Process design options in the final stage of outputting a lilyglyph item.
    Package and local options are not set in absolute values with lilyglyphs
    but relative to an original/designed appearance. Typically the option
    values are *scaled* or *added* to the design option.
    `self` refers to the Formatter object here.
--]]
    local design_options = options._design
    if design_options then
        local cur_value, handler
        for k,v in pairs(design_options) do
            cur_value = options[k]
            if not cur_value then
                -- no given option, use design option
                options[k] = v
            else
                -- handle option relative to design options_obj
                handler = design_handlers[k]
                if handler then
                    options[k] = handler(v, cur_value)
                else
                    warn("Unhandled design option")
                    options[k] = cur_value
                end
            end
        end
    end
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
    compiled. (TODO: check if that is OK, with more examples).
    Images are scaled by this value depending on the current font size,
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
            options = self:process_design_options(options)
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
