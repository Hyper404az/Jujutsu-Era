local HttpService = game:GetService("HttpService")

local Serialization = {}

function Serialization.Encode(value)
    local ok, result = pcall(HttpService.JSONEncode, HttpService, value)
    if ok then
        return result
    end

    return "{}"
end

function Serialization.Decode(value)
    if type(value) ~= "string" or value == "" then
        return {}
    end

    local ok, result = pcall(HttpService.JSONDecode, HttpService, value)
    if ok and type(result) == "table" then
        return result
    end

    return {}
end

return Serialization
