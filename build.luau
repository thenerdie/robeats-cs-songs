-- Build script that compiles and publishes songs in the song folder to Roblox

local remodel = require("remodel.luau")

local fs = require("@lune/fs")
local serde = require("@lune/serde")
local roblox = require("@lune/roblox")
local stdio = require("@lune/stdio")

local env = {}

for _, line in fs.readFile(".env"):split("\n") do
    local k, v = string.match(line, "([^=]+)=([^=]+)")

    env[k] = if tonumber(v) then tonumber(v) else v
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

    for i, songFolder in songsDir do
        local success = pcall(function()
            local METADATA_FILE = "metadata.yml"
            local HIT_OBJECTS_FILE = "objects.yml"

            local metadata = serde.decode("yaml", fs.readFile(BASE_DIR .. "/" .. songFolder .. "/" .. METADATA_FILE))
            local hitObjects = serde.decode("yaml", fs.readFile(BASE_DIR .. "/" .. songFolder .. "/" .. HIT_OBJECTS_FILE))

            local songInstance = Instance.new("Folder")
            songInstance.Name = songFolder

            local metadataValue = Instance.new("StringValue")
            metadataValue.Name = "Metadata"
            metadataValue.Value = serde.encode("json", metadata)

            local hitObjectsInstance = Instance.new("Folder")
            hitObjectsInstance.Name = "HitObjects"

            local jsonString = serde.encode("json", hitObjects)

            for i, chunk in splitStringIntoChunks(jsonString, 200000) do
                local chunkInstance = Instance.new("StringValue")
                chunkInstance.Name = i
                chunkInstance.Value = chunk
                chunkInstance.Parent = hitObjectsInstance
            end

            hitObjectsInstance.Parent = songInstance
            metadataValue.Parent = songInstance

            songInstance.Parent = songs
        end)

        if success then
            print("Song " .. i .. " of " .. #songsDir .. " built")
        else
            print("Building \"" .. songFolder .. "\" failed")
        end
    end

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