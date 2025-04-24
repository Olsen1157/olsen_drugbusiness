
local Tunnel = module("vrp", "lib/Tunnel")
local Proxy = module("vrp", "lib/Proxy")

vRP = Proxy.getInterface("vRP")
vRPclient = Tunnel.getInterface("vRP", "olsen_drugbusiness")
-------------------------------------------------------------
--                         HT_BASE                         --
-------------------------------------------------------------
HT = nil

TriggerEvent('HT_base:getBaseObjects', function(obj) HT = obj end)

local time = os.date("%d/%m/%Y - %X")

-- Get Purchased Labs:
HT.RegisterServerCallback('olsen_drugbusiness:getTakenLabs',function(source, cb)
    local source = source
	local user_id = vRP.getUserId({source})
    local takenLabs = {}
    MySQL.Async.fetchAll("SELECT labID FROM druglabs",{}, function(data)
        for k,v in pairs(data) do
            table.insert(takenLabs,{id = v.labID})
        end
        cb(takenLabs)
    end)
end)

-- Purchase Drug Lab:
HT.RegisterServerCallback('olsen_drugbusiness:buyDrugLab',function(source, cb, id, val)
    local source = source
	local user_id = vRP.getUserId({source})
    if vRP.tryFullPayment({user_id,val.price}) then
        MySQL.Async.execute("INSERT INTO druglabs (user_id, labID) VALUES (@user_id, @labID)", {['user_id'] = user_id, ['labID'] = id})
        sendToDiscordLogsEmbed(5793946, 'Druglab | Logs',' Event: Køb af Lab\nID: ' ..user_id.. '\nLab ID: '..id..'\nSolgt for: ' ..val.price.. ' DKK\nTid: ' ..time, 'Avation - 2021©️')
        cb(true)
    else
        cb(false)
    end
end)

-- Sell Drug Lab:
HT.RegisterServerCallback('olsen_drugbusiness:sellDrugLab',function(source, cb, id, val, sellPrice)
    local source = source
	local user_id = vRP.getUserId({source})
    MySQL.Async.fetchAll("SELECT labID FROM druglabs WHERE user_id = @user_id", {['@user_id'] = user_id}, function(data)
        if data[1].labID ~= nil then 
            if data[1].labID == id then
                --MySQL.Async.execute("UPDATE users SET labID=@labID WHERE identifier=@identifier", {['@identifier'] = xPlayer.identifier, ['@labID'] = 0}) 
                MySQL.Async.execute("DELETE FROM druglabs WHERE labID=@labID", {['@labID'] = id}) 
                if Config.RecieveSoldLabCash then
                    vRP.giveMoney({user_id,sellPrice})
                    sendToDiscordLogsEmbed(5793946, 'Druglab | Logs',' Event: Salg af Lab\nID: ' ..user_id.. '\nLab ID: '..id..'\nSolgt for: ' ..sellPrice.. ' DKK\nTid: ' ..time, 'Avation - 2021©️')
                else
                    vRP.giveBankMoney({user_id,sellPrice})
                    sendToDiscordLogsEmbed(5793946, 'Druglab | Logs',' Event: Salg af Lab\nID: ' ..user_id.. '\nLab ID: '..id..'\nSolgt for: ' ..sellPrice.. ' DKK\nTid: ' ..time, 'Avation - 2021©️')
                end
                cb(true)
            else
                cb(false)
            end
        end
    end)
end)

-- Get Supplies:
HT.RegisterServerCallback('olsen_drugbusiness:getSupplies',function(source, cb, plyLabID)
    local source = source
	local user_id = vRP.getUserId({source})
    MySQL.Async.fetchAll("SELECT supplies FROM druglabs WHERE labID = @labID", {['@labID'] = plyLabID}, function(data)
        if data[1].supplies ~= nil then
            local supplies = data[1].supplies
            cb(supplies)
        else
            cb(nil)
        end
    end)
end)

-- Get Stock:
HT.RegisterServerCallback('olsen_drugbusiness:getStock',function(source, cb, plyLabID)
    local source = source
	local user_id = vRP.getUserId({source})
    MySQL.Async.fetchAll("SELECT stock FROM druglabs WHERE labID = @labID", {['@labID'] = plyLabID}, function(data)
        if data[1].stock ~= nil then
            local stock = data[1].stock
            cb(stock)
        end
    end)
end)

-- Buy Supplies:
HT.RegisterServerCallback('olsen_drugbusiness:buySupplies',function(source, cb, plyLabID)
    local source = source
	local user_id = vRP.getUserId({source})
    MySQL.Async.fetchAll("SELECT supplies FROM druglabs WHERE labID = @labID", {['@labID'] = plyLabID}, function(data)
        if data[1].supplies ~= nil then
            local supplies = data[1].supplies
            if supplies < 5 then
                local maxSupplies = (5 - supplies) 
                local priceSupplyLevel = (maxSupplies * Config.SupplyLevelPrice)
                    if vRP.tryFullPayment({user_id,priceSupplyLevel}) then
                    TriggerClientEvent('mythic_notify:client:SendAlert', source, { type = 'success', text = (Lang['supplies_purchased']:format(maxSupplies,priceSupplyLevel)), length = '5000', style = {}})
                    -- UPDATE DATABASE:
                    MySQL.Sync.execute("UPDATE druglabs SET supplies = @supplies WHERE labID = @labID", {
                        ['@supplies'] = 5,
                        ['@labID'] = plyLabID
                    })
                    sendToDiscordLogsEmbed(5793946, 'Druglab | Logs',' Event: Køb Forsyninger\nID: ' ..user_id.. '\nLab ID: '..plyLabID..'\nBetalte : ' ..priceSupplyLevel.. '\nLab Status: Købte ' ..maxSupplies.. ' Forsyninger\nTid: ' ..time, 'Avation - 2021©️')
                    cb(true)
                else
                    cb(false)
                end
            else
                cb(nil)
            end
        end
    end)
end)

-- Alert on raid/robbery
RegisterServerEvent('olsen_drugbusiness:alertLabOwner')
AddEventHandler('olsen_drugbusiness:alertLabOwner', function(plyLabID)
    MySQL.Async.fetchAll("SELECT user_id FROM druglabs WHERE labID = @labID",{['@labID'] = plyLabID}, function(data)
        if data[1].user_id ~= nil then
            targetIdentifier = data[1].user_id
            target = vRP.getUserSource({tonumber(targetIdentifier)})
            if target ~= nil then 
                TriggerClientEvent('mythic_notify:client:SendAlert', target, { type = 'error', text = (Lang['lab_robbery_in_progress']), length = '5000', style = {}})
            end
        else
            print("error [olsen_drugbusiness:alertLabOwner]")
        end
    end)
end)

-- Seize Supplies and Stock
RegisterServerEvent('olsen_drugbusiness:seizeStockSupplies')
AddEventHandler('olsen_drugbusiness:seizeStockSupplies', function(plyLabID)
    local source = source
	local user_id = vRP.getUserId({source})
    -- GET TARGET PLAYER:
    local target = nil
    MySQL.Async.fetchAll("SELECT user_id FROM druglabs WHERE labID = @labID",{['@labID'] = plyLabID}, function(user)
        if user[1].user_id ~= nil then
            targetIdentifier = user[1].user_id
            Wait(200)
            target = vRP.getUserSource({tonumber(targetIdentifier)})
            if target ~= nil then
                MySQL.Async.fetchAll("SELECT * FROM druglabs WHERE labID = @labID",{['@labID'] = plyLabID}, function(data)
                    if data[1] ~= nil then
                        stock = data[1].stock
                        supplies = data[1].supplies
                        MySQL.Sync.execute("UPDATE druglabs SET supplies = @supplies, stock = @stock WHERE labID = @labID", {
                            ['@supplies'] = 0,
                            ['@stock'] = 0,
                            ['@labID'] = plyLabID
                        })
                        sendToDiscordLogsEmbed(5793946, 'Druglab | Logs',' Event: Konfisker Lab\nID: ' ..user_id.. '\nLab ID: '..plyLabID..'\nLab Status: ' ..stock.. ' Produkter og ' ..supplies.. ' Forsyninger\nTid: ' ..time, 'Avation - 2021©️')
                    end
                end)
            else
                if Config.RaidLabWhenPlayerOffline then
                    MySQL.Async.fetchAll("SELECT * FROM druglabs WHERE labID = @labID",{['@labID'] = plyLabID}, function(data)
                        if data[1] ~= nil then
                            stock = data[1].stock
                            supplies = data[1].supplies
                            MySQL.Sync.execute("UPDATE druglabs SET supplies = @supplies, stock = @stock WHERE labID = @labID", {
                                ['@supplies'] = 0,
                                ['@stock'] = 0,
                                ['@labID'] = plyLabID
                            })
                            sendToDiscordLogsEmbed(5793946, 'Druglab | Logs',' Event: Konfisker Lab (Offline)\nID: ' ..user_id.. '\nLab ID: '..plyLabID..'\nLab Status: ' ..stock.. ' Produkter og ' ..supplies.. ' Forsyninger\nTid: ' ..time, 'Avation - 2021©️')
                        end
                    end)
                else
                    print("player offline [olsen_drugbusiness:seizeStockSupplies]")
                end
            end
        else
            print("error [olsen_drugbusiness:seizeStockSupplies]")
        end
    end)
end)

-- Rob Supplies and Stock
RegisterServerEvent('olsen_drugbusiness:robStockSupplies')
AddEventHandler('olsen_drugbusiness:robStockSupplies', function(targetID, plyLabID)
    local source = source
	local user_id = vRP.getUserId({source})
    -- GET TARGET PLAYER:
    local target = nil
    MySQL.Async.fetchAll("SELECT user_id FROM druglabs WHERE labID = @labID",{['@labID'] = targetID}, function(user)
        local  targetIdentifier = user[1].user_id
        Wait(200)
        target = vRP.getUserSource({tonumber(targetIdentifier)})
        if target ~= nil then
            local stock = 0
            local supplies = 0
            MySQL.Async.fetchAll("SELECT * FROM druglabs WHERE labID = @labID",{['@labID'] = targetID}, function(data)
                if data[1] ~= nil then
                    stock = data[1].stock
                    supplies = data[1].supplies
                    MySQL.Sync.execute("UPDATE druglabs SET supplies = @supplies, stock = @stock WHERE labID = @labID", {
                        ['@supplies'] = 0,
                        ['@stock'] = 0,
                        ['@labID'] = targetID
                    })
                    sendToDiscordLogsEmbed(5793946, 'Druglab | Logs',' Event: Røvede Lab\nID: ' ..user_id.. '\nLab ID: '..targetID..'\nLab Status: ' ..stock.. ' Produkter og ' ..supplies.. ' Forsyninger\nTid: ' ..time, 'Avation - 2021©️')
                end
                MySQL.Async.fetchAll("SELECT * FROM druglabs WHERE labID = @labID",{['@labID'] = plyLabID}, function(newData)
                    if newData[1] ~= nil then
                        local newStock = 0
                        local newSupplies = 0
                        if (newData[1].stock + stock) >= 5 then
                            newStock = 5
                        else
                            newStock = newData[1].stock + stock
                        end
                        if (newData[1].supplies + supplies) >= 5 then
                            newSupplies = 5
                        else
                            newSupplies = newData[1].supplies + supplies
                        end
                        MySQL.Sync.execute("UPDATE druglabs SET supplies = @supplies, stock = @stock WHERE labID = @labID", {
                            ['@supplies'] = newSupplies,
                            ['@stock'] = newStock,
                            ['@labID'] = plyLabID
                        })
                        sendToDiscordLogsEmbed(5793946, 'Druglab | Logs',' Event: Efter Røveri\nID: ' ..user_id.. '\nLab ID: '..plyLabID..'\nLab Status: ' ..newSupplies.. ' Produkter og ' ..newStock.. ' Forsyninger\nTid: ' ..time, 'Avation - 2021©️')
                    end
                end)
            end)
        else
            if Config.RobLabWhenPlayerOffline then 
                local stock = 0
                local supplies = 0
                MySQL.Async.fetchAll("SELECT * FROM druglabs WHERE labID = @labID",{['@labID'] = targetID}, function(data)
                    if data[1] ~= nil then
                        stock = data[1].stock
                        supplies = data[1].supplies
                        MySQL.Sync.execute("UPDATE druglabs SET supplies = @supplies, stock = @stock WHERE labID = @labID", {
                            ['@supplies'] = 0,
                            ['@stock'] = 0,
                            ['@labID'] = targetID
                        })
                        sendToDiscordLogsEmbed(5793946, 'Druglab | Logs',' Event: Røvede Lab (Offline)\nID: ' ..user_id.. '\nLab ID: '..targetID..'\nLab Status: ' ..stock.. ' Produkter og ' ..supplies.. ' Forsyninger\nTid: ' ..time, 'Avation - 2021©️')
                    end
                    MySQL.Async.fetchAll("SELECT * FROM druglabs WHERE labID = @labID",{['@labID'] = plyLabID}, function(newData)
                        if newData[1] ~= nil then
                            local newStock = 0
                            local newSupplies = 0
                            if (newData[1].stock + stock) >= 5 then
                                newStock = 5
                            else
                                newStock = newData[1].stock + stock
                            end
                            if (newData[1].supplies + supplies) >= 5 then
                                newSupplies = 5
                            else
                                newSupplies = newData[1].supplies + supplies
                            end
                            MySQL.Sync.execute("UPDATE druglabs SET supplies = @supplies, stock = @stock WHERE labID = @labID", {
                                ['@supplies'] = newSupplies,
                                ['@stock'] = newStock,
                                ['@labID'] = plyLabID
                            })
                            sendToDiscordLogsEmbed(5793946, 'Druglab | Logs',' Event: Efter Røveri\nID: ' ..user_id.. '\nLab ID: '..plyLabID..'\nLab Status: ' ..newSupplies.. ' Produkter og ' ..newStock.. ' Forsyninger\nTid: ' ..time, 'Avation - 2021©️')
                        end
                    end)
                end)
            else
                print("player not online [olsen_drugbusiness:robStockSupplies]")
            end
        end
    end)
end)

-- Convert Supplies to Stock
RegisterServerEvent('olsen_drugbusiness:suppliesToStock')
AddEventHandler('olsen_drugbusiness:suppliesToStock', function(plyLabID)
    local source = source
	local user_id = vRP.getUserId({source})
    MySQL.Async.fetchAll("SELECT * FROM druglabs WHERE labID = @labID",{['@labID'] = plyLabID}, function(data)
        if data[1] ~= nil then
            local supplies = data[1].supplies
            local stock = data[1].stock
            if supplies > 0 and stock < 5 then
                supplies = supplies - 1
                stock = stock + 1
                MySQL.Sync.execute("UPDATE druglabs SET supplies = @supplies, stock = @stock WHERE labID = @labID", {
                    ['@supplies'] = supplies,
                    ['@stock'] = stock,
                    ['@labID'] = plyLabID
                })
                sendToDiscordLogsEmbed(5793946, 'Druglab | Logs',' Event: Forsyninger til Produkter\nID: ' ..user_id.. '\nLab ID: '..plyLabID..'\nLab Status: ' ..supplies.. ' Produkter og ' ..stock.. ' Forsyninger\nTid: ' ..time, 'Avation - 2021©️')
            else
                if stock >= 5 then
                elseif supplies <= 0 then
                end
            end
        end
    end)
end)

-- Job Reward:
RegisterServerEvent('olsen_drugbusiness:jobReward')
AddEventHandler('olsen_drugbusiness:jobReward',function(plyLabID)
    local source = source
	local user_id = vRP.getUserId({source})
    MySQL.Async.fetchAll("SELECT supplies FROM druglabs WHERE labID = @labID",{['@labID'] = plyLabID}, function(data)
        if data[1] ~= nil then
            -- Get Current Supplies:
            local supplies = data[1].supplies
            -- Check Supplies
            if supplies < 5 then
                -- Add Supplies Level:
                supplies = supplies + 1
                -- UPDATE DATABASE:
                sendToDiscordLogsEmbed(5793946, 'Druglab | Logs',' Event: Stjæl Forsyninger\nID: ' ..user_id.. '\nNuværende: '..supplies..'\nTid: ' ..time, 'Avation - 2021©️')
                MySQL.Sync.execute("UPDATE druglabs SET supplies = @supplies WHERE labID = @labID", {
                    ['@supplies'] = supplies,
                    ['@labID'] = plyLabID
                })
            end
        end
    end)
end)

-- Stock Sale:
RegisterServerEvent('olsen_drugbusiness:stockSaleSV')
AddEventHandler('olsen_drugbusiness:stockSaleSV',function(plyLabID, stockLevel, stockValue)
    local source = source
	local user_id = vRP.getUserId({source})
    vRP.giveInventoryItem({user_id,"dirty_money",stockValue,true})
    sendToDiscordLogsEmbed(5793946, 'Druglab | Logs',' Event: Produkt Salg\nID: ' ..user_id.. '\nModtog: '..stockValue..'\nProdukt level: ' ..stockLevel.. '\nTid: ' ..time, 'Avation - 2021©️')
    TriggerClientEvent('mythic_notify:client:SendAlert', source, { type = 'success', text = (Lang['stock_sold_success']:format(stockValue)), length = '5000', style = {}})
end)

function sendToDiscordLogsEmbed(color, name, message, footer)
	local embed = {
		  {
			  ["color"] = color,
			  ["title"] = "**".. name .."**",
			  ["description"] = message,
			  ["footer"] = {
				  ["text"] = footer,
			  },
		  }
	  }
  
	PerformHttpRequest("https://discord.com/api/webhooks/867759982304165888/V_nRZzUGg9kj_mtedWPrFSZna2BTRhp7gOdiuERU0ee0J2MpAwy8f5skVdGzCNRLDBbw", function(err, text, headers) end, 'POST', json.encode({username = 'Logs', embeds = embed}), { ['Content-Type'] = 'application/json' })
  end