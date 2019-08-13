local err, warn, info, log = luatexbase.provides_module({
    name               = "lilyglyphs-accidentals",
    version            = '0.1',
    date               = "2019/05/11",
    description        = "lilyglyphs commands for accidentals.",
    author             = "Urs Liska",
    copyright          = "2019- Urs Liska",
    license            = "GPL 3",
})

local accidentals = lilyglyphs:new_library('accidentals')

accidentals:add_glyph_commands(
-- Natural glyph variants
    {
        design = {
            voffset = '0.5',
            scale = '1.5'
        }
    },
    {
        natural = {
            create = 'renew*',
            name = 'natural',
            glyph = 'accidentals.natural',
        },
        natural_arrowup = {
            name = 'naturalArrowup',
            glyph = 'accidentals.natural.arrowup',
        },
        natural_arrowdown = {
            name = 'naturalArrowdown',
            glyph = 'accidentals.natural.arrowdown',
        },
        natural_arrowboth = {
            name = 'naturalArrowboth',
            glyph = 'accidentals.natural.arrowboth',
        },
    })

accidentals:add_glyph_commands(
-- Sharp glyph variants
    {
        design = {
            voffset = '0.5',
            scale = '1.5'
        }
    },
    {
        sharp = {
            create = 'renew*',
            name = 'sharp',
            glyph = 'accidentals.sharp',
        },
        sharpArrowup = {
            name = 'sharpArrowup',
            glyph = 'accidentals.sharp.arrowup',
        },
        sharpArrowdown = {
            name = 'sharpArrowdown',
            glyph = 'accidentals.sharp.arrowdown',
        },
        sharpArrowboth = {
            name = 'sharpArrowboth',
            glyph = 'accidentals.sharp.arrowboth',
        },
        sharpSlashslashStem = {
            name = 'sharpSlashslashStem',
            glyph = 'accidentals.sharp.slashslash.stem',
        },
        sharpSlashslashStemstemstem = {
            name = 'sharpSlashslashStemstemstem',
            glyph = 'accidentals.sharp.slashslash.stemstemstem',
        },
        sharpSlashslashslashStem = {
            name = 'sharpSlashslashslashStem',
            glyph = 'accidentals.sharp.slashslashslash.stem',
        },
        sharpSlashslashslashStemstem = {
            name = 'sharpSlashslashslashStemstem',
            glyph = 'accidentals.sharp.slashslashslash.stemstem',
        },
        doublesharp = {
            name = 'doublesharp',
            glyph = 'accidentals.doublesharp',
        },
    })

accidentals:add_glyph_commands(
-- Flat glyph variants
    {
        design = {
            voffset = '0.2',
            scale = '1.5'
        }
    },
    {
        -- Flat glyph variants
        flat = {
            create = 'renew*',
            name = 'flat',
            glyph = 'accidentals.flat',
        },
        flat_arrowup = {
            name = 'flatArrowup',
            glyph = 'accidentals.flat.arrowup',
        },
        flat_arrowdown = {
            name = 'flatArrowdown',
            glyph = 'accidentals.flat.arrowdown',
        },
        flat_arrowboth = {
            name = 'flatArrowboth',
            glyph = 'accidentals.flat.arrowboth',
        },
        flat_slash = {
            name = 'flatSlash',
            glyph = 'accidentals.flat.slash',
        },
        flat_slashslash = {
            name = 'flatSlashslash',
            glyph = 'accidentals.flat.slashslash',
        },
        mirroredflat = {
            name = 'mirroredflat',
            glyph = 'accidentals.mirroredflat',
        },
        mirroredflat_flat = {
            name = 'mirroredflatFlat',
            glyph = 'accidentals.mirroredflat.flat',
        },
        mirroredflat_backslash = {
            name = 'mirroredflatBackslash',
            glyph = 'accidentals.mirroredflat.backslash',
        },
        flatflat = {
            name = 'flatflat',
            glyph = 'accidentals.flatflat',
        },
        flatflat_slash = {
            name = 'flatflatSlash',
            glyph = 'accidentals.flatflat.slash',
        },
    })

return accidentals
