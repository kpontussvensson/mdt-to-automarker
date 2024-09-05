-- 1. Get MDT dungeon files and place them in the input folder
-- 2. Run the script
-- 3. Copy the Mythic+ Auto Marker from inside WeakAuras.lua SavedVariables into a text editor
-- 4. Replace all ["IID1234"] with the script output
-- 5. Get the right IID's from https://wago.tools/db2/Map?page=1
-- 6. Replace dungeon names with the right IID's and also change the IID's and dungeon names in the authorOptions to map them together

function table.containsKey(table, element)
    for key, _ in pairs(table) do
        if key == element then
            return true
        end
    end
    return false
end

function table.containsValue(table, element)
    for _, value in pairs(table) do
        if value == element then
            return true
        end
    end
    return false
end

local blacklisted_mobs = {"Vy Relic", "Wo Relic", "Urh Relic", "Oros Coldheart", "Incinerator Arkolath", "Executioner Varruth", "Soggodon the Breaker"}

local output_filename = "output-" .. os.date("%Y%m%d%H%M%S") .. ".lua"

local inspect = require("libs.inspect")
local input_dungeons = {}
for input in io.popen([[dir "C:\WS\mdt-to-automarker\input\" /b]]):lines() do
    table.insert(input_dungeons, input)
end

for i = 1, #input_dungeons, 1 do
    local file = io.open("C:\\WS\\mdt-to-automarker\\input\\" .. input_dungeons[i], "r")
    if file == nil then return end

    local whole_file = file:read("a")
    local delim = "MDT.dungeonEnemies[dungeonIndex] ="
    local pos = whole_file:find(delim, 1, true)

    if pos then
        whole_file = whole_file:sub(pos + string.len(delim))
        whole_file = "return" .. whole_file
        file:close()

        file = io.open("C:\\WS\\mdt-to-automarker\\input\\" .. input_dungeons[i], "w")
        if file == nil then return end
        file:write(whole_file)
        file:flush()
        file:close()
    else
        file:close()
    end

    local input = require("input." .. input_dungeons[i]:match("(.+)%..+$"))

    local output = {}

    for k, v in pairs(input) do
        if not table.containsValue(blacklisted_mobs, v["name"]) then
            local mob = {}
            if table.containsKey(v, "isBoss") then
                mob["npcName"] = " BOSS: " .. v["name"]
            else
                mob["npcName"] = v["name"]
            end
            mob["enemyGroup"] = 1
            mob["npcId"] = tostring(v["id"])
            mob["shouldMark"] = false

            table.insert(output, mob)
        end
    end

    local output_string = inspect(output)
    output_string, _ = string.gsub(output_string, "  ", "")
    output_string, _ = string.gsub(output_string, "{ {", "[\"" .. input_dungeons[i]:match("(.+)%..+$") .. "\"] = {\n{")
    output_string, _ = string.gsub(output_string, "enemyGroup", "[\"enemyGroup\"]")
    output_string, _ = string.gsub(output_string, "npcId", "[\"npcId\"]")
    output_string, _ = string.gsub(output_string, "npcName", "[\"npcName\"]")
    output_string, _ = string.gsub(output_string, "shouldMark", "[\"shouldMark\"]")
    output_string, _ = string.gsub(output_string, "}, {", "},\n{")
    output_string, _ = string.gsub(output_string, "} }", "},\n},\n")

    file = io.open(output_filename, "a")
    if file == nil then return end
    file:write(output_string)
    file:flush()
    file:close()
end
