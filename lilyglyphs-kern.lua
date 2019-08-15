local err, warn, info, log = luatexbase.provides_module({
    name               = "lilyglyphs-kern",
    version            = '0.1',
    date               = "2019/05/11",
    description        = "Kerning for lilyText.",
    author             = "Urs Liska",
    copyright          = "2019- Urs Liska",
    license            = "GPL 3",
})

local lilyglyphs_opts = lua_options.client('lilyglyphs')

--[[
    Table with kerning pairs, one subtable for each font.
    The subtables (defined in separate files lilyglyphs-kern-NN.lua)
    are structured as follows:
    - first-level entries:
      - key: first character of the kerning pair
      - value: subtable:
        - second-level entries:
          - key: second character of the kerning pair
          - value: kerning value
            this is a number (as string), interpreted in 'ex' units
    Any keys that are numbers or punctuation must be enclosed in
    square brackets and quotes:
      ['0'] = {
        ['+'] = '.25',
      },
    defining the kerning between '0' and '+' as 0.25ex

    NOTE: The following may be copied as a basis for a kerning pair subtable.
    Replace the main key with the desired left hand side and the values with the
    determined spacing (may be negative). Remove unmodified entries.

    ['f'] = {
        f = '.0',
        p = '.0',
        m = '.0',
        r = '.0',
        s = '.0',
        z = '.0',
        ['+'] = '.0',
        ['-'] = '.0',
        ['.'] = '.0',
        [','] = '.0',
        ['0'] = '.0',
        ['1'] = '.0',
        ['2'] = '.0',
        ['3'] = '.0',
        ['4'] = '.0',
        ['5'] = '.0',
        ['6'] = '.0',
        ['7'] = '.0',
        ['8'] = '.0',
        ['9'] = '.0',
    },

--]]
local data = {
    emmentaler = require('lilyglyphs-kern-emmentaler.lua'),
    lilyjazz   = require('lilyglyphs-kern-lilyjazz.lua'),
}

return function(text)
--[[
    Apply "kerning" to the given `text` by inserting \hspace
    elements according to the kerning pairs defined for the
    currently selected music font.
--]]
    local kerning_pairs = data[lilyglyphs_opts.options.font] or {}
    local pair
    for left, rights in pairs(kerning_pairs) do
        for right, kern in pairs(rights) do
            pair = left .. right
            -- process characters for the gsub
            pair = pair:gsub(
                '%+', '%%+'):gsub(
                '%-', '%%-'):gsub(
                '%.', '%%.')
            text = text:gsub(pair,
                string.format([[%s\hspace{%sex}%s]], left, kern, right))
        end
    end
    return text
end
