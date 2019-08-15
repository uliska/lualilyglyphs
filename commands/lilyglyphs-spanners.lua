local err, warn, info, log = luatexbase.provides_module({
    name               = "lilyglyphs-spanners",
    version            = '0.1',
    date               = "2019/05/11",
    description        = "lilyglyphs commands for (simple) spanners.",
    author             = "Urs Liska",
    copyright          = "2019- Urs Liska",
    license            = "GPL 3",
})

local spanners = lilyglyphs:new_library('spanners')

spanners:add_image_commands(
    {
        design = {
            scale = '0.9',
        },
    },
    {
        decresc_hairpin = {
            name = 'decrescHairpin',
            image = 'lily-decrescHairpin.pdf',
        },
        cresc_hairpin = {
            name = 'crescHairpin',
            image = 'lily-crescHairpin.pdf',
        },
    })



return spanners
