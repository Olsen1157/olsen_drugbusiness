RegisterNetEvent('olsen_drugbusiness:JobDataCL')
AddEventHandler('olsen_drugbusiness:JobDataCL',function(data)
    Config.StealSupplies = data
end)

RegisterNetEvent('olsen_drugbusiness:SellJobDataCL')
AddEventHandler('olsen_drugbusiness:SellJobDataCL',function(data)
    Config.SellStock = data
end)

RegisterNetEvent('olsen_drugbusiness:productionTime')
AddEventHandler('olsen_drugbusiness:productionTime', function()
    local ownsLab = false
    if plyLabID ~= 0 then
        ownsLab = true
    else
        ownsLab = false
    end
    while ownsLab do
        Citizen.Wait((Config.ProductionMinutes * 1000 * 60))
        TriggerServerEvent('olsen_drugbusiness:suppliesToStock',plyLabID)
    end
end)