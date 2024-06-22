-- Build script that compiles and publishes songs in the song folder to Roblox

local remodel = require("remodel.luau")
local serpent = require("serpent.luau")

local fs = require("@lune/fs")
local serde = require("@lune/serde")
local roblox = require("@lune/roblox")
local stdio = require("@lune/stdio")

local env = {}

for _, line in fs.readFile(".env"):split("\n") do
    local k, v = string.match(line, "([^=]+)=([^=]+)")

    if k and v then
        env[k] = if tonumber(v) then tonumber(v) else v
    end
end

function splitStringIntoChunks(inputString, chunkSize)
    local chunks = {}
    local length = #inputString
    for i = 1, length, chunkSize do
        table.insert(chunks, inputString:sub(i, i + chunkSize - 1))
    end
    return chunks
end

local Instance = roblox.Instance

local BASE_DIR = "src/export"
local OUT_FILE = "out.rbxm"

local function generateModelFile()
    local songsDir = fs.readDir(BASE_DIR)

    local songs = Instance.new("Model")
    songs.Name = "Songs"

    local hitObjectsFolder = Instance.new("Folder")
    hitObjectsFolder.Name = "HitObjects"
    hitObjectsFolder.Parent = songs
    
    local metadataOut = {}
    local difficultiesOut = {}

    for i, songFolder in songsDir do
        local success, err = pcall(function()
            local METADATA_FILE = "metadata.yml"
            local HIT_OBJECTS_FILE = "objects.yml"

            local metadata = serde.decode("yaml", fs.readFile(BASE_DIR .. "/" .. songFolder .. "/" .. METADATA_FILE))
            local hitObjects = serde.decode("yaml", fs.readFile(BASE_DIR .. "/" .. songFolder .. "/" .. HIT_OBJECTS_FILE))

            local hitObjectsInstance = Instance.new("Folder")
            hitObjectsInstance.Name = songFolder

            local jsonString = serde.encode("json", hitObjects)

            for i, chunk in splitStringIntoChunks(jsonString, 200000) do
                local chunkInstance = Instance.new("StringValue")

                chunkInstance.Name = i
                chunkInstance.Value = chunk
                chunkInstance.Parent = hitObjectsInstance
            end

            hitObjectsInstance.Parent = hitObjectsFolder

            metadata.HitObjectsDirectory = songFolder

            difficultiesOut[metadata.MD5Hash] = metadata.Difficulty
            metadata.Difficulty = nil
            
            table.insert(metadataOut, metadata)
        end)

        if success then
            print("Song " .. i .. " of " .. #songsDir .. " built")
        else
            print("Building \"" .. songFolder .. "\" failed: " .. tostring(err))
        end
    end

    local metadataFile = Instance.new("ModuleScript")
    metadataFile.Name = "Metadata"
    metadataFile.Source = "return " .. serpent.block(metadataOut)
    metadataFile.Parent = songs

    local difficultyFile = Instance.new("ModuleScript")
    difficultyFile.Name = "Difficulties"
    difficultyFile.Source = "return " .. serpent.block(difficultiesOut)
    difficultyFile.Parent = songs

    local model = roblox.serializeModel({ songs })

    fs.writeFile(OUT_FILE, model)

    return model
end

local function uploadModelFile(model)
    if not env.SONGS_MODEL_ID then
        error("You have not provided a SONGS_MODEL_ID variable in your .env!")
    end

    remodel.uploadAssetId(env.SONGS_MODEL_ID, model)
end

local genModel = stdio.prompt("confirm", "Would you like to generate a new model file?")

if genModel then
    local model = generateModelFile()
    print("Done!")

    local uploadModel = stdio.prompt("confirm", "Would you like to upload it?")

    if uploadModel then
        uploadModelFile(model)
    end
end