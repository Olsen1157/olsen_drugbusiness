-- Get & Apply Player Lab ID:
RegisterServerEvent('olsen_drugbusiness:getPlyLabs')
AddEventHandler('olsen_drugbusiness:getPlyLabs', function()
    local source = source
	local user_id = vRP.getUserId({source})
    MySQL.Async.fetchAll("SELECT labID FROM druglabs WHERE user_id = @user_id",{['@user_id'] = user_id}, function(data)
        local labID = 0
        if data[1] ~= nil then
            labID = data[1].labID
        end
        TriggerClientEvent('olsen_drugbusiness:applyPlyLabID', source, labID)
    end)
end)

-- STEAL SUPPLIES:
RegisterServerEvent('olsen_drugbusiness:JobDataSV')
AddEventHandler('olsen_drugbusiness:JobDataSV',function(data)
    TriggerClientEvent('olsen_drugbusiness:JobDataCL',-1,data)
end)

-- SELL STOCK:
RegisterServerEvent('olsen_drugbusiness:SellJobDataSV')
AddEventHandler('olsen_drugbusiness:SellJobDataSV',function(data)
    TriggerClientEvent('olsen_drugbusiness:SellJobDataCL',-1,data)
end)

-- Remove Stock:
RegisterServerEvent('olsen_drugbusiness:removeStock')
AddEventHandler('olsen_drugbusiness:removeStock',function(plyLabID, stockLevel)
    MySQL.Async.fetchAll("SELECT stock FROM druglabs WHERE labID = @labID",{['@labID'] = plyLabID}, function(data)
        if data[1].stock ~= nil then
            local stock = data[1].stock
            MySQL.Sync.execute("UPDATE druglabs SET stock = @stock WHERE labID = @labID", {
                ['@stock'] = 0,
                ['@labID'] = plyLabID
            })
        end
    end)
end)