-- Create a matrix of all combinations of LilyPond notation font 'letters'
-- in order to check out kerning values

local chars = {
    'f', 'p', 'm', 'r', 's', 'z', '.', ',', '+', '-',
    '0', '1', '2', '3', '4', '5', '6', '7', '8', '9'
}
local result = ''
local line, LHS
for i, char in ipairs(chars) do
    line = ''
    LHS = chars[i]
    for _, RHS in ipairs(chars) do
        line = line .. LHS .. RHS .. ' '
    end
    tex.print(string.format([[\noindent\lilyText{%s}\par

]], line):explode('\n'))
end
