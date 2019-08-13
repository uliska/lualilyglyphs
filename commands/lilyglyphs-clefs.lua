local err, warn, info, log = luatexbase.provides_module({
    name               = "lilyglyphs-clefs",
    version            = '0.1',
    date               = "2019/05/11",
    description        = "lilyglyphs commands for clefs.",
    author             = "Urs Liska",
    copyright          = "2019- Urs Liska",
    license            = "GPL 3",
})

local clefs = lilyglyphs:new_library('clefs')

clefs:add_glyph_commands(
-- Natural clef variants
    {
        design = {
            voffset = '0.5',
            scale = '0.6',
        }
    },
    {
        c = {
            name = 'clefC',
            glyph = 'clefs.C',
            design = {
                voffset = '0.5',
                scale = '0.55',
            }
        },
        f = {
            name = 'clefF',
            glyph = 'clefs.F',
        },
        g = {
            name = 'clefG',
            glyph = 'clefs.G',
            design = {
                scale = '0.5',
                voffset = '0.5'
            },
        },
        percussion = {
            name = 'clefPercussion',
            glyph = 'clefs.percussion',
        },
        tab = {
            name = 'clefTab',
            glyph = 'clefs.tab',
            design = {
                scale = '0.5',
                voffset = '0.6',
            },
        },
    })

clefs:add_glyph_commands(
-- Inline clef variants
    {
        c_inline = {
            name = 'clefCInline',
            glyph = 'clefs.C_change',
            design = {
                voffset = '0.75',
                scale = '0.6',
            }
        },
        f_inline = {
            name = 'clefFInline',
            glyph = 'clefs.F_change',
            design = {
                voffset = '0.55',
                scale = '0.65',
            }
        },
        g_inline = {
            name = 'clefGInline',
            glyph = 'clefs.G_change',
            design = {
                scale = '0.5',
                voffset = '0.3'
            },
        },
        percussion_inline = {
            name = 'clefPercussionInline',
            glyph = 'clefs.percussion_change',
            design = {
                voffset = '0.5',
                scale = '0.7',
            }
        },
        tab_inline = {
            name = 'clefTabInline',
            glyph = 'clefs.tab_change',
            design = {
                scale = '0.5',
                voffset = '0.6',
            },
        },
    })

return clefs
