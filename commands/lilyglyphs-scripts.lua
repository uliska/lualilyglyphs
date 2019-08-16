local err, warn, info, log = luatexbase.provides_module({
    name               = "lilyglyphs-scripts",
    version            = '0.1',
    date               = "2019/05/11",
    description        = "lilyglyphs commands for scripts (articulations).",
    author             = "Urs Liska",
    copyright          = "2019- Urs Liska",
    license            = "GPL 3",
})

local lib = require('luaoptions-lib')
local scripts = lilyglyphs:new_library('scripts')

--[[
    Provide *one* command for scripts.
    Mandatory argument is the glyphname part after 'scripts.' as
    per the Emmentaler documentation (http://lilypond.org/doc/v2.19/Documentation/notation/the-emmentaler-font#script-glyphs)
    There are bidirectional and unidirectional script glyphs available,
    bidirectional glyphs are printed in their 'up' variant if the option
    'down' is not given.

    TODO: Handle `dots` option
--]]
scripts:add_command('script',
    { 'scale', 'voffset', 'font', 'weight' },
    {
        comment = 'Insert a script glyph',
        options = {
            ['down'] = { 'false', 'true', '' },
        },
        glyph_map = {
            bidi = {
                { 'fermata', },
                { 'shortfermata', },
                { 'longfermata', },
                { 'verylongfermata', },
                { 'staccatissimo', },
                { 'portato', },
                { 'marcato', },
                { 'pedalheel', },
                { 'pedaltoe', },
                { 'accentus', },
                { 'semicirculus', },
                { 'signumcongruentiae', },
            },
            uni = {
                { 'thumb', },
                { 'sforzato', },
                { 'espr', },
                { 'staccato', },
                { 'tenuto', },
                { 'open', },
                { 'halfopen', },
                { 'halfopenvertical', },
                { 'stopped', },
                { 'upbow', },
                { 'downbow', },
                { 'reverseturn', },
                { 'turn', },
                { 'trill', },
                { 'flageolet', },
                { 'segno', },
                { 'varsegno', },
                { 'coda', },
                { 'varcoda', },
                { 'rcomma', },
                { 'lcomma', },
                { 'rvarcomma', },
                { 'lvarcomma', },
                { 'arpeggio', },
                -- TODO: trill_element throughout trilelement
                { 'prall', },
                { 'mordent', },
                { 'prallprall', },
                { 'prallmordent', },
                { 'upprall', },
                { 'upmordent', },
                { 'pralldown', },
                { 'downprall', },
                { 'downmordent', },
                { 'prallup', },
                { 'lineprall', },
                { 'caesura.curved', },
                { 'caesura.straight', },
                { 'tickmark', },
                { 'snappizzicato', },
                { 'ictus', },
                { 'circulus', },
                { 'augmentum', },
            },
        },
        func = function(self, script, options)

            local function get_glyph_entry()
                local map = self._glyph_map
                for _, group in ipairs({ 'bidi', 'uni'} ) do
                    for _, def in ipairs(map[group]) do
                        if def[1] == script then
                            return def, group
                        end
                    end
                end
            end

            local target
            local glyph_entry, group = get_glyph_entry()
            if not glyph_entry then
                warn(string.format([[
Unknown script key '%s'
]], script))
                return self:format('lily.glyph', 'X')
            end

            if group == 'bidi' then
                local prefix = options.down and 'd' or 'u'
                target = prefix .. glyph_entry[1]
            else
                target = glyph_entry[1]
            end

            -- Set design options
            options._design = {
                voffset = .35,
            }
            local glyph_design = glyph_entry[2] or {}
            for k, v in pairs(glyph_design) do
                options._design[k] = v
            end
            return self:format(
                'lily.glyph',
                'scripts.'..target, options)
        end,
})

return scripts
