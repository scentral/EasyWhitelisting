config = {
    token = "BOT_TOKEN_HERE",
    guild = "GUILD_ID_HERE",
    role = "ROLE_ID_HERE"
}

function DiscordRequest(method, endpoint, jsondata, reason)
    local data = nil
    PerformHttpRequest("https://discord.com/api/"..endpoint, function(errorCode, resultData, resultHeaders)
		data = {data=resultData, code=errorCode, headers=resultHeaders}
    end, method, #jsondata > 0 and jsondata or "", {["Content-Type"] = "application/json", ["Authorization"] = "Bot " .. config.token, ['X-Audit-Log-Reason'] = reason})

    while data == nil do
        Citizen.Wait(0)
    end
	
    return data
end

-- Checking identifiers and verifiying they are whitelisted to put them in the database and allow them to connect to the server
AddEventHandler("playerConnecting", function(name, setKickReason, deferrals)
    deferrals.defer()
    deferrals.update("Hault " .. name .. ", I am checking your information.")

    local player = source
    local identifiers = GetPlayerIdentifiers(player)
    local steam = nil
    local license = nil
    local discord = nil

    for _, identifier in ipairs(identifiers) do
        if string.find(identifier, "steam") then
            steam = identifier
        elseif string.find(identifier, "license") then
            license = identifier
        elseif string.find(identifier, "discord") then
            discord = identifier
        end
    end

    if steam == nil then
        deferrals.done("Sorry" .. name .. ", it seems you are missing your steam card. Try and look for (restart) it and try again")
        return
    elseif license == nil then
        deferrals.done("Sorry" .. name .. ", it seems you are missing your license card. Try and look for it and try again")
        return
    elseif discord == nil then
        deferrals.done("Sorry" .. name .. ", it seems you are missing your discord card. Try and look for (restart) it and try again")
        return
    end

    local endpoint = ("guilds/%s/members/%s"):format(config.guild, discord:sub(9))
    local member = DiscordRequest("GET", endpoint, {})
    if member.code == 200 then
        local data = json.decode(member.data)
        local roles = data.roles
        local found = false
        for _, role in ipairs(roles) do
            if role == config.role then
                found = true
                break
            end
        end

        if found then
            deferrals.done("You are whitelisted!")
        else
            deferrals.done("Sorry" .. name .. ", it seems you are not whitelisted. Please contact a staff member to get whitelisted.")
        end
    else
        print("Error: " .. member.code)
        return false
    end 
end)
