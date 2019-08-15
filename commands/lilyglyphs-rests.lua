local err, warn, info, log = luatexbase.provides_module({
    name               = "lilyglyphs-rests",
    version            = '0.1',
    date               = "2019/05/11",
    description        = "lilyglyphs commands for rests.",
    author             = "Urs Liska",
    copyright          = "2019- Urs Liska",
    license            = "GPL 3",
})

local rests = lilyglyphs:new_library('rests')

--[[
    Provide *one* command for rests.
    Mandatory argument is the (main) duration (in LilyPond duration notation),
    or one of the three MMR keys M1, M2, or M3.
    Options are only effective for specific durations:
    - key '4', option classical: print classical crotchet rest
    - key '1', '2', or 'M', options noline: variants without staffline segment

    TODO: Handle `dots` option
--]]
rests:add_command('rest',
    { 'scale', 'voffset', 'font', 'weight' },
    {
        comment = 'Insert a rest glyph',
        name = 'rest',
        options = {
            ['classical'] = { 'false', 'true', '' },
            ['noline'] = { 'false', 'true', '' },
            ['dots'] = { '0', lua_options.is_int }
        },
        glyph_map = {
            ['1'] = {'0o', { voffset = .75 } },
            ['2'] = {'1o',},
            ['4'] = {'2', { voffset = .5 }},
            ['8'] = {'3', { voffset = .5 }},
            ['16'] = {'4', {voffset = 1 }},
            ['32'] = {'5',},
            ['64'] = {'6', {voffset = .85 }},
            ['128'] = {'7',},
            ['M1'] = {'M1o', {voffset = .2 }},
            ['M2'] = {'M2', {voffset = .8 }},
            ['M3'] = {'M3', {voffset = .8 }},
        },
        func = function(self, rest, options)
            local glyph_entry = self._glyph_map[rest]
            -- check for valid key
            if not glyph_entry then
                warn(string.format([[
Unknown rest key %s
]], rest))
                return self:format('lily.glyph', 'X')
            end
            local target = glyph_entry[1]
            -- Set design options
            options._design = {
                voffset = '.4',
                scale = '.85',
            }
            local glyph_design = glyph_entry[2] or {}
            for k, v in pairs(glyph_design) do
                options._design[k] = v
            end
            -- Handle special cases:
            if rest == '4' and options.classical then
                -- "classical" quarter rest
                target = '2classical'
            elseif options.noline then
                -- rest glyphs without staffline segment(s)
                if rest == '1' then target = '0'
                elseif rest == '2' then target = '1'
                elseif rest == 'M' then target = 'M1'
                end
            end
            return self:format('lily.glyph', 'rests.'..target, options)
        end,
})

return rests
