vRP = Proxy.getInterface("vRP")
vRPclient = Tunnel.getInterface("vRP", "olsen_drugbusiness")

HT = nil

Citizen.CreateThread(function()
    while HT == nil do
        TriggerEvent('HT_base:getBaseObjects', function(obj) HT = obj end)
        Citizen.Wait(0)
    end
	HT.TriggerServerCallback("policegarage:permission", function(cb)
		if cb then
			isCop = true
		else
			isCop = false
		end
	end)
	TriggerServerEvent('olsen_drugbusiness:getPlyLabs')
end)

insideShell = false
plyLabID = 0
emptyLabs = {}

RegisterNetEvent('olsen_drugbusiness:applyPlyLabID')
AddEventHandler('olsen_drugbusiness:applyPlyLabID', function(labID)
    -- get player lab id:
    plyLabID = labID
    
    -- remove blips:
	for k,v in pairs(labBlips) do
		RemoveBlip(v)
    end
    
    -- get lab blips on map:
	HT.TriggerServerCallback('olsen_drugbusiness:getTakenLabs', function(takenLabs)
		for k,v in pairs(takenLabs) do
			if v.id ~= plyLabID then
				emptyLabs[v.id] = v.id
			end
		end
		for k,v in pairs(Config.DrugLabs) do
			if plyLabID == k then
				if Config.OwnedLabBlip  then
					CreateLabBlips(k,v,"Laboratorie")
				end
			end
		end
	end)
	Wait(1000)
	TriggerEvent('olsen_drugbusiness:productionTime')
end)

hacking = false
labMenu = nil
Citizen.CreateThread(function()
	while true do
		Citizen.Wait(1)
		local player = GetPlayerPed(-1)
		local coords =  GetEntityCoords(player)
		for k,v in pairs(Config.DrugLabs) do
			local distance = GetDistanceBetweenCoords(coords.x, coords.y, coords.z, v.pos[1], v.pos[2], v.pos[3], false)
			if labMenu ~= nil then
				distance = GetDistanceBetweenCoords(coords.x, coords.y, coords.z, labMenu.pos[1], labMenu.pos[2], labMenu.pos[3], false)
				while labMenu ~= nil and distance > 2.0 do
					labMenu = nil
					Citizen.Wait(1)
				end
				if labMenu == nil then
					HT.UI.Menu.CloseAll()
				end
			else
				if distance <= 10.0 and distance >= 2.0 then
						DrawMarker(21, v.pos[1], v.pos[2], v.pos[3]-0.35, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.5, 0.5, 0.5, 88, 104, 154, 200, false, true, 2, true, false, false, false)
                elseif distance <= 2.0 then

                    if plyLabID == k then
                        DrawText3Ds(v.pos[1], v.pos[2], v.pos[3], Lang['drug_lab_interact'])
                        if IsControlJustPressed(0, Config.KeyToManageLab) then
							labMenu = v
                            DrugLabManageMenu(k,v)
                        end
                    else
                        if emptyLabs[k] == k then
							if isCop then
								DrawText3Ds(v.pos[1], v.pos[2], v.pos[3], Lang['police_raid_lab'])
								if IsControlJustPressed(0, Config.KeyToRaidLab) then
									TriggerServerEvent('olsen_drugbusiness:alertLabOwner', k)
									RequestAnimDict("timetable@jimmy@doorknock@")
									while not HasAnimDictLoaded("timetable@jimmy@doorknock@") do
										Citizen.Wait(10)
									end
									TaskPlayAnim(player, "timetable@jimmy@doorknock@", "knockdoor_idle", 8.0, 8.0, -1, 4, 0, 0, 0, 0 )    
									exports['av_progressbar']:startUI(((Config.WaitTimeUntilRaid * 1000)), Lang['prog_bar_raid_door'])
									Citizen.Wait((Config.WaitTimeUntilRaid * 1000))
									Wait(150)
									ClearPedTasks(player)
									SpawnDrugLab(k,v)
                                end
							else
								if plyLabID ~= 0 then
									DrawText3Ds(v.pos[1], v.pos[2], v.pos[3], Lang['drug_lab_rob'])
									if IsControlJustPressed(0, Config.KeyToRobLab) and not hacking then
										hacking = true
										GainAccessToLab(k,v)
									end
								else
									DrawText3Ds(v.pos[1], v.pos[2], v.pos[3], Lang['lab_owned_player'])
								end
							end
                        else
                            if plyLabID == 0 then
                                DrawText3Ds(v.pos[1], v.pos[2], v.pos[3], (Lang['press_to_buy_lab']:format(math.floor(v.price))))
                                if IsControlJustPressed(0, Config.KeyToPurchaseLab) then
                                    labMenu = v
                                    OpenDrugLabBuyMenu(k,v)
                                end
                            else
                                DrawText3Ds(v.pos[1], v.pos[2], v.pos[3], Lang['only_own_one_lab'])
                            end
                        end
                    end
				end
			end
		end
	end
end)

robId = nil
robVal = nil 
function GainAccessToLab(id,val)
	local player = GetPlayerPed(-1)
	robId = id
	robVal = val 
	SetCurrentPedWeapon(player, GetHashKey("WEAPON_UNARMED"),true)
	Citizen.Wait(200)
	FreezeEntityPosition(player, true)
	TaskStartScenarioInPlace(player, 'WORLD_HUMAN_STAND_MOBILE', -1, true)
	TriggerServerEvent('olsen_drugbusiness:alertLabOwner', id)
	exports['av_progressbar']:startUI(((Config.WaitTimeUntilHack * 1000)), Lang['prog_bar_pre_hack'])
	Citizen.Wait((Config.WaitTimeUntilHack * 1000))
	TriggerEvent("mhacking:show")
	TriggerEvent("mhacking:start",Config.mHackingBlocks,Config.mHackingSeconds,hackingCallback)
end

function hackingCallback(success)
	local player = GetPlayerPed(-1)
	local coords = GetEntityCoords(player)
	TriggerEvent('mhacking:hide')
	if success then
		hacking = false
		ClearPedTasks(player)
		FreezeEntityPosition(player, false)
		SpawnDrugLab(robId,robVal)	
	else
		exports['mythic_notify']:SendAlert('success', Lang['lab_robbery_hack_fail'])
		--ShowNotifyHT(Lang['lab_robbery_hack_fail'])
		hacking = false
		ClearPedTasks(player)
		FreezeEntityPosition(player, false)
	end
end

-- Purchase Drug Lab:
function OpenDrugLabBuyMenu(id,val)
	local playerPed  = GetPlayerPed(-1)
	local elements = {
		{ label = Lang['button_yes'], value = "confirm_purchase" },
		{ label = Lang['button_no'], value = "decline_purchase" },
	}
	HT.UI.Menu.Open('default', GetCurrentResourceName(), "drug_lab_purchase",
		{
			title    = "Pris: "..math.floor(val.price).." DKK",
			align    = "center",
			elements = elements
		},
	function(data, menu)
		if(data.current.value == 'confirm_purchase') then
			HT.TriggerServerCallback('olsen_drugbusiness:buyDrugLab', function(purchased)
				if purchased then
					exports['mythic_notify']:SendAlert('success', (Lang['drug_lab_purchased']):format(math.floor(val.price)))
					--ShowNotifyHT((Lang['drug_lab_purchased']):format(math.floor(val.price)))
					TriggerServerEvent('olsen_drugbusiness:getPlyLabs')
				else
					exports['mythic_notify']:SendAlert('success', (Lang['not_enough_money']))
					--ShowNotifyHT(Lang['not_enough_money'])
				end
			end, id, val)
			menu.close()
			labMenu = nil
		end
		if(data.current.value == 'decline_purchase') then
			menu.close()
			labMenu = nil
		end
		menu.close()
	end, function(data, menu)
		menu.close()
		labMenu = nil
	end)
end

-- Manage Drug Lab Menu:
function DrugLabManageMenu(id,val)
	local playerPed  = GetPlayerPed(-1)
	local elements = {
		{ label = Lang['enter_drug_lab'], value = "enter_drug_lab" },
		{ label = Lang['sell_drug_lab'], value = "sell_drug_lab" },
	}
	HT.UI.Menu.Open('default', GetCurrentResourceName(), "drug_lab_main_menu",
		{
			title    = "Laboratorie ["..tostring(id).."]",
			align    = "center",
			elements = elements
		},
	function(data, menu)
		if(data.current.value == 'enter_drug_lab') then
			menu.close()
            labMenu = nil
            SpawnDrugLab(id,val)
		end
        if(data.current.value == 'sell_drug_lab') then
			SellDrugLabMenu(id,val)
			menu.close()
			labMenu = nil
		end
		menu.close()
	end, function(data, menu)
		menu.close()
		labMenu = nil
	end)
end

-- Sell Drug Lab:
function SellDrugLabMenu(id,val)
	local playerPed  = GetPlayerPed(-1)
	local sellPrice = (val.price * Config.SellPercent)
	local elements = {
		{ label = Lang['button_yes'], value = "confirm_sale" },
		{ label = Lang['button_no'], value = "decline_sale" },
	}
	HT.UI.Menu.Open('default', GetCurrentResourceName(), "drug_lab_sell_menu",
		{
			title    = "Pris: "..math.floor(sellPrice).." DKK",
			align    = "center",
			elements = elements
		},
	function(data, menu)
		if(data.current.value == 'confirm_sale') then
			HT.TriggerServerCallback('olsen_drugbusiness:sellDrugLab', function(sold)
				if sold then
					TriggerServerEvent('olsen_drugbusiness:getPlyLabs')
					exports['mythic_notify']:SendAlert('success', (Lang['drug_lab_sold']):format(math.floor(sellPrice)))
					--ShowNotifyHT((Lang['drug_lab_sold']):format(math.floor(sellPrice)))
				else
					exports['mythic_notify']:SendAlert('success', (Lang['not_your_drug_lab']))
					--ShowNotifyHT(Lang['not_your_drug_lab'])
				end
			end, id, val, math.floor(sellPrice))
			menu.close()
			labMenu = nil
		end
		if(data.current.value == 'decline_sale') then
			menu.close()
			labMenu = nil
		end
		menu.close()
	end, function(data, menu)
		menu.close()
		labMenu = nil
	end)
end

inLaptop = false
inDruglab = nil
spawnedShell = nil
function SpawnDrugLab(id,val)
    local player = GetPlayerPed(-1)
    local coords = GetEntityCoords(player)
    exports['av_progressbar']:startUI((2000), "Tilgår Laboratoriet...")
    Citizen.Wait(2000)
    local prop = Config.DrugLabs[id].prop
    -- Enter Shell:
    insideShell = true
    -- Screen Fade Out:
	DoScreenFadeOut(1000)
	while not IsScreenFadedOut() do
		Wait(0)
	end
    Citizen.Wait(500)
    -- Teleport Player:
    local offset = Config.Offsets[prop]
	local entry = offset.entry
	local laptop = offset.laptop
	local laptopAnimPos = offset.animPos
	local laptopAnimHead = offset.animHead
	
    SetEntityCoords(player, offset.entry[1], offset.entry[2], offset.entry[3])
    SetEntityHeading(player, offset.h)

    -- Screen Fade In:
    Citizen.Wait(500)
    DoScreenFadeIn(1000)
    
    -- Loop Inside Drug Lab:
	while insideShell do
		Citizen.Wait(1)
		local player = GetPlayerPed(-1)
		local coords =  GetEntityCoords(player)

		-- laptop:
		if offset.laptop ~= nil then
			if GetDistanceBetweenCoords(coords.x, coords.y, coords.z, laptop[1], laptop[2], laptop[3], false) <= 2.0 and not inLaptop then
				DrawText3Ds(laptop[1], laptop[2], laptop[3], Lang['press_to_use_laptop'])
				if IsControlJustPressed(0, Config.KeyToLaptop) and not inLaptop then
					inLaptop = true
					OpenLaptopFunction(laptopAnimPos, laptopAnimHead, id, val)
				end
			end
		end

		-- exit:
		local distance = GetDistanceBetweenCoords(coords.x, coords.y, coords.z, entry[1], entry[2], entry[3], false)
		if inDruglab ~= nil then
			distance = GetDistanceBetweenCoords(coords.x, coords.y, coords.z, inDruglab[1], inDruglab[2], inDruglab[3], false)
			while inDruglab ~= nil and distance > 2.0 do
				inDruglab = nil
				Citizen.Wait(1)
			end
			if inDruglab == nil then
				HT.UI.Menu.CloseAll()
			end
		else
			if distance <= 10.0 and distance >= 2.0 then
				DrawMarker(21, entry[1], entry[2], entry[3]-0.35, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.5, 0.5, 0.5, 88, 104, 154, 200, false, true, 2, true, false, false, false)
			elseif distance <= 2.0 then
				DrawText3Ds(entry[1], entry[2], entry[3], Lang['press_to_leave_lab'])
				if IsControlJustPressed(0, Config.KeyToLeaveLab) then
                    inDruglab = entry
                    local exit = Config.DrugLabs[id].pos
                    exports['av_progressbar']:startUI((2000), "Forlader Laboratoriet...")
                    Citizen.Wait(2000)
                    DoScreenFadeOut(800)
                    while not IsScreenFadedOut() do
                        Wait(0)
                    end
                    Wait(500)
                    --DeleteObject(spawnedShell)
                    SetEntityCoords(player, exit[1], exit[2], exit[3]-0.975)
                    insideShell = false
                    spawnedShell = nil
                    inDruglab = nil
                    Wait(500)
					DoScreenFadeIn(1250)
				end
			end
		end
	end
end

function OpenLaptopFunction(pos, heading, id, val)
	local player = GetPlayerPed(-1)
	local animDict = "mp_fbi_heist"
	local animName = "loop"
	RequestAnimDict(animDict)
	while not HasAnimDictLoaded(animDict) do
		Citizen.Wait(10)
	end
	TaskPlayAnimAdvanced(player, animDict, animName, pos[1], pos[2], pos[3], 0.0, 0.0, heading, 3.0, 1.0, -1, 30, 1.0, 0, 0 )
	exports['av_progressbar']:startUI((2000), Lang['prog_bar_using_laptop'])
	Citizen.Wait(2000)
	if isCop then 
		OpenPoliceSeizeMenu(id, val)
	else
		if plyLabID ~= id then
			RobDrugLabMenu(id, val)
		else
			OpenLaptopMainMenu()
		end
	end
end

function RobDrugLabMenu(id, val) 
	local player = GetPlayerPed(-1)
	HT.TriggerServerCallback('olsen_drugbusiness:getStock', function(stock)
		if stock ~= nil then
			Wait(100)
			HT.TriggerServerCallback('olsen_drugbusiness:getSupplies', function(supplies)
				if supplies ~= nil then
					Wait(100)
					local elements = {
						{ label = (Lang['laptop_cur_supplies']:format(supplies)), value = "show_cur_supplies" },
						{ label = (Lang['laptop_cur_stock']:format(stock)), value = "show_cur_stock" },
						{ label = Lang['laptop_rob_lab'], value = "ply_seize_stuff" },
					}
					HT.UI.Menu.Open('default', GetCurrentResourceName(), "drug_lab_robbery_menu",
						{
							title    = "Bærbar",
							align    = "center",
							elements = elements
						},
					function(data, menu)
						if(data.current.value == 'ply_seize_stuff') then
							menu.close()
							exports['av_progressbar']:startUI(3000, Lang['prog_bar_transfer'])
							TriggerServerEvent('olsen_drugbusiness:robStockSupplies', id, plyLabID)
							Wait(3000)
							exports['mythic_notify']:SendAlert('success', (Lang['lab_robbery_done']))
							--ShowNotifyHT(Lang['lab_robbery_done'])
							inLaptop = false
							ClearPedTasks(player)
						end
					end, function(data, menu)
						menu.close()
						inLaptop = false
						ClearPedTasks(player)
					end)
				end
			end, id)
		end
	end, id)
end

function OpenPoliceSeizeMenu(id, val)
	local player = GetPlayerPed(-1)

	HT.TriggerServerCallback('olsen_drugbusiness:getStock', function(stock)
		if stock ~= nil then
			Wait(100)
			HT.TriggerServerCallback('olsen_drugbusiness:getSupplies', function(supplies)
				if supplies ~= nil then
					Wait(100)
					local elements = {
						{ label = (Lang['laptop_cur_supplies']:format(supplies)), value = "show_cur_supplies" },
						{ label = (Lang['laptop_cur_stock']:format(stock)), value = "show_cur_stock" },
						{ label = Lang['laptop_pol_seize'], value = "police_seize_stuff" },
					}
					HT.UI.Menu.Open('default', GetCurrentResourceName(), "drug_lab_police_menu",
						{
							title    = "Bærbar",
							align    = "center",
							elements = elements
						},
					function(data, menu)
						if(data.current.value == 'police_seize_stuff') then
							menu.close()
							exports['av_progressbar']:startUI(1500, Lang['prog_bar_transfer2'])
							Wait(1500)
							TriggerServerEvent('olsen_drugbusiness:seizeStockSupplies', id)
							inLaptop = false
							ClearPedTasks(player)
						end
					end, function(data, menu)
						menu.close()
						inLaptop = false
						ClearPedTasks(player)
					end)
				end
			end, id)
		end
	end, id)
end

function OpenLaptopMainMenu()
	local player = GetPlayerPed(-1)

	local elements = {
		{ label = Lang['laptop_supplies'], value = "supplies_menu" },
		{ label = Lang['laptop_stock'], value = "stock_menu" },
	}
	HT.UI.Menu.Open('default', GetCurrentResourceName(), "drug_lab_main_menu",
		{
			title    = "Bærbar",
			align    = "center",
			elements = elements
		},
	function(data, menu)
		if(data.current.value == 'supplies_menu') then
			menu.close()
			OpenLaptopSuppliesMenu()
		end
        if(data.current.value == 'stock_menu') then
			menu.close()
			OpenLaptopStockMenu()
		end
	end, function(data, menu)
		menu.close()
		inLaptop = false
		ClearPedTasks(player)
	end)
end

stealingSupplies = false
function OpenLaptopSuppliesMenu()
	local player = GetPlayerPed(-1)
	local elements = {
		{ label = Lang['laptop_check_supplies'], value = "check_supplies" },
		{ label = Lang['laptop_buy_supplies'], value = "buy_supplies" },
		{ label = Lang['laptop_steal_supplies'], value = "steal_supplies" },
	}
	HT.UI.Menu.Open('default', GetCurrentResourceName(), "supplies_main_menu",
		{
			title    = "Laboratorie Forsyninger",
			align    = "center",
			elements = elements
		},
	function(data, menu)
		if(data.current.value == 'check_supplies') then
			HT.TriggerServerCallback('olsen_drugbusiness:getSupplies', function(supplies)
				if supplies ~= nil then
					exports['mythic_notify']:SendAlert('inform', (Lang['supplies_level_msg']:format(supplies)))
					--ShowNotifyHT((Lang['supplies_level_msg']:format(supplies)))
				else
					print("error [OpenLaptopSuppliesMenu() in check_supplies]")
				end
			end, plyLabID)
		end
		if(data.current.value == 'buy_supplies') then
			HT.TriggerServerCallback('olsen_drugbusiness:buySupplies', function(payment)
				if payment ~= nil then
					if not payment then
						exports['mythic_notify']:SendAlert('error', (Lang['not_enough_money']))
						--ShowNotifyHT(Lang['not_enough_money'])
					end
				else
					exports['mythic_notify']:SendAlert('error', (Lang['supplies_are_full']))
					--ShowNotifyHT(Lang['supplies_are_full'])
				end
			end, plyLabID)
			menu.close()
			OpenLaptopMainMenu()
		end
		if(data.current.value == 'steal_supplies') then
			if not stealingSupplies then
				HT.TriggerServerCallback('olsen_drugbusiness:getSupplies', function(supplies)
					if supplies ~= nil then
						if supplies < 5 then
							local id = math.random(1,#Config.StealSupplies)
							local curID = 0
							while Config.StealSupplies[id].started and curID < 100 do
								curID = curID + 1
								id = math.random(1,#Config.StealSupplies)
							end
							if curID == 100 then
								exports['mythic_notify']:SendAlert('error', (Lang['no_jobs_available']))
								--ShowNotifyHT(Lang['no_jobs_available'])
							else
								stealingSupplies = true
								Config.StealSupplies[id].started = true
								Wait(200)
								TriggerServerEvent('olsen_drugbusiness:JobDataSV',Config.StealSupplies)
								TriggerEvent('olsen_drugbusiness:SuppliesJob', id)
								menu.close()
								inLaptop = false
								ClearPedTasks(player)
							end
						else
							exports['mythic_notify']:SendAlert('error', (Lang['supplies_are_full']))
							--ShowNotifyHT(Lang['supplies_are_full'])
						end
					else
						print("error [OpenLaptopSuppliesMenu() in steal_supplies]")
					end
				end, plyLabID)
			else
				exports['mythic_notify']:SendAlert('error', (Lang['already_in_job']))
				--ShowNotifyHT(Lang['already_in_job'])
			end
		end
	end, function(data, menu)
		menu.close()
		OpenLaptopMainMenu()
	end)
end

function OpenLaptopStockMenu()
	local player = GetPlayerPed(-1)
	local elements = {
		{ label = Lang['laptop_check_stock'], value = "check_stock" },
		{ label = Lang['laptop_sell_stock'], value = "sell_stock" },
	}
	HT.UI.Menu.Open('default', GetCurrentResourceName(), "stock_main_menu",
		{
			title    = "Lagerinfo",
			align    = "center",
			elements = elements
		},
	function(data, menu)
		if(data.current.value == 'check_stock') then
			HT.TriggerServerCallback('olsen_drugbusiness:getStock', function(stock)
				if stock ~= nil then
					exports['mythic_notify']:SendAlert('inform', (Lang['stock_level_msg']:format(stock)))
					--ShowNotifyHT((Lang['stock_level_msg']:format(stock)))
				else
					print("error [OpenLaptopStockMenu() in check_stock]")
				end
			end, plyLabID)
		end
		if(data.current.value == 'sell_stock') then
			menu.close()
			StockSellData()
		end
	end, function(data, menu)
		menu.close()
		OpenLaptopMainMenu()
	end)
end

function StockSellData() 
	local player = GetPlayerPed(-1)
	local stockLevel = 0
	local multiplier = 0
	local gotStock = false
	local gotMultiplier = false
	-- Get Stock:
	HT.TriggerServerCallback('olsen_drugbusiness:getStock', function(stock)
		if stock ~= nil then
			stockLevel = stock
			gotStock = true
		end
	end, plyLabID)
	-- Get Stock Value:
	while not gotStock do
		Wait(10)
		if gotStock and not gotMultiplier then
			for k,v in pairs(Config.SellMultiplier) do
				if stockLevel == k then
					multiplier = v
					multiplierData = true
					break
				end
			end
		end
	end

	local stockPrice = (Config.StockLevelPrice * stockLevel)
	local stockValue = math.floor(stockPrice * multiplier)
	
	exports['av_progressbar']:startUI(1000, "Henter data...")
	Wait(1000)
	OpenLaptopSellMenu(stockLevel, stockValue)
end

sellingStock = false
function OpenLaptopSellMenu(stockLevel, stockValue)
	local player = GetPlayerPed(-1)
	local elements = {
		{ label = (Lang['laptop_stock_level']:format(stockLevel)), value = "info_stock_level" },
		{ label = (Lang['laptop_sell_price']:format(math.floor(stockValue))), value = "info_stock_sell_price" },
		{ label = Lang['laptop_find_buyer'], value = "sell_stock_job" },
		{ label = Lang['button_return'], value = "return_to_stock_menu" },
	}
	HT.UI.Menu.Open('default', GetCurrentResourceName(), "stock_sell_main_menu",
		{
			title    = "Lagerinfo",
			align    = "center",
			elements = elements
		},
	function(data, menu)
		if(data.current.value == 'return_to_stock_menu') then
			menu.close()
			OpenLaptopStockMenu()
		end
		if(data.current.value == 'sell_stock_job') then
			if not sellingStock then 
				if stockLevel > 0 then 
					local id = math.random(1,#Config.SellStock)
					local curID = 0
					while Config.SellStock[id].started and curID < 100 do
						curID = curID + 1
						id = math.random(1,#Config.SellStock)
					end
					if curID == 100 then
						exports['mythic_notify']:SendAlert('error', (Lang['no_available_buyers']))
						--ShowNotifyHT(Lang['no_available_buyers'])
					else
						sellingStock = true
						Config.SellStock[id].started = true
						Wait(200)
						TriggerServerEvent('olsen_drugbusiness:SellJobDataSV',Config.SellStock)
						TriggerEvent('olsen_drugbusiness:StockDelivery', id, stockLevel, stockValue)
						menu.close()
						inLaptop = false
						ClearPedTasks(player)
					end
				else
					exports['mythic_notify']:SendAlert('error', (Lang['stock_is_empty']))
					--ShowNotifyHT(Lang['stock_is_empty'])
				end
			else
				exports['mythic_notify']:SendAlert('error', (Lang['already_selling_stock']))
				--ShowNotifyHT(Lang['already_selling_stock'])
			end
		end
	end, function(data, menu)
		menu.close()
		OpenLaptopStockMenu()
	end)
end

endStockJob 		= false
stockVeh			= nil
stockVehModel		= nil
stockVehSpawned 	= false
stockVehDelivered 	= false

RegisterNetEvent('olsen_drugbusiness:StockDelivery')
AddEventHandler('olsen_drugbusiness:StockDelivery', function(id, stockLevel, stockValue)
	local player = GetPlayerPed(-1)
	local soldStock = false
	local num = Config.SellStock[id]
	local blip = CreateStockBlip(num.location)
	local vehBlip = nil
	local stockTaken = false
	local notifySound1, notifySound2, notifySound3, notifySound4 = false, false, false, false

	while not soldStock and not endStockJob do
		Citizen.Wait(1)
		
		if num.started then
			local insideVeh = false 

			local coords = GetEntityCoords(player)
			local distance = GetDistanceBetweenCoords(coords, num.location[1], num.location[2], num.location[3], true)
			
			local startPos = Config.DrugLabs[plyLabID].delivery

			-- Remove Stock:
			if not stockTaken then
				TriggerServerEvent('olsen_drugbusiness:removeStock', plyLabID, stockLevel)
				stockTaken = true
			end

			-- Spawn Vehicle:
			if not stockVehSpawned then
				ClearAreaOfVehicles(startPos[1], startPos[2], startPos[3], 15.0, false, false, false, false, false)
				stockVehSpawned = true
				Citizen.Wait(200)
				stockVehModel = Config.StockSellVeh
				HT.Game.SpawnVehicle(stockVehModel, {x = startPos[1], y = startPos[2], z = startPos[3]}, startPos[4], function(veh)
					SetEntityCoordsNoOffset(veh, startPos[1], startPos[2], startPos[3])
					SetEntityHeading(veh,startPos[4])
					FreezeEntityPosition(veh, true)
					SetVehicleOnGroundProperly(veh)
					FreezeEntityPosition(veh, false)
					SetEntityAsMissionEntity(stockVeh, true, true)
					stockVeh = veh
					SetVehicleDoorsLockedForAllPlayers(stockVeh, false)
				end)
			end

			-- Check if player is in job vehicle:
			if not insideShell and stockVehSpawned and not stockVehDelivered then
				local vehicle = GetVehiclePedIsIn(GetPlayerPed(-1), false)
				if GetEntityModel(vehicle) == GetHashKey(stockVehModel) then
					insideVeh = true
				else 
					insideVeh = false
				end
			end

			-- Stock Vehicle Blip:
			if stockVehSpawned then
				if DoesEntityExist(stockVeh) then 
					if not DoesBlipExist(vehBlip) and not insideVeh then
						vehBlip = AddBlipForEntity(stockVeh)
					end
					SetBlipSprite(vehBlip, 477)
					SetBlipColour(vehBlip, 3)
					SetBlipDisplay(vehBlip, 2)
					SetBlipScale(vehBlip, 0.65)
					BeginTextCommandSetBlipName("STRING")
					AddTextComponentString("Leverings Køretøj")
					EndTextCommandSetBlipName(vehBlip)
				elseif DoesBlipExist(vehBlip) or insideVeh then
					RemoveBlip(vehBlip)
				end
			end

			-- Check if Ply inside shell/drug-lab:
			if insideShell then
				DrawMissionText(Lang['leave_drug_lab'])
				if not notifySound1 then
					PlaySoundFrontend(-1, "Mission_Pass_Notify", "DLC_HEISTS_GENERAL_FRONTEND_SOUNDS", 0)
					notifySound1 = true
				end
			end

			-- Mission Text:
			if not insideShell and stockVehSpawned and not insideVeh and not stockVehDelivered then
				DrawMissionText(Lang['get_in_vehicle'])
				if not notifySound2 then
					PlaySoundFrontend(-1, "Mission_Pass_Notify", "DLC_HEISTS_GENERAL_FRONTEND_SOUNDS", 0)
					notifySound2 = true
				end
			end

			-- Mission Text:
			if not insideShell and insideVeh and not stockVehDelivered then
				DrawMissionText(Lang['deliver_stock_drop_off'])
				if not notifySound3 then
					PlaySoundFrontend(-1, "Mission_Pass_Notify", "DLC_HEISTS_GENERAL_FRONTEND_SOUNDS", 0)
					notifySound3 = true
				end
			end

			if not stockVehDelivered then
				local coords = GetEntityCoords(GetPlayerPed(-1))
				local vehicle = GetVehiclePedIsIn(GetPlayerPed(-1), false)
				local distToDelivery = GetDistanceBetweenCoords(coords, num.location[1], num.location[2], num.location[3], true)
					if distToDelivery <= 10.0 then
						DrawMarker(21, num.location[1], num.location[2], num.location[3]-0.35, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.5, 0.5, 0.5, 88, 104, 154, 200, false, true, 2, true, false, false, false)
					end
				if distToDelivery <= 2.0 and not stockVehDelivered then
					DrawText3Ds(num.location[1], num.location[2], num.location[3], Lang['deliver_stock'])
					if IsControlJustPressed(0, Config.KeyToDeliverStockVeh) then 
						if GetEntityModel(vehicle) == GetHashKey(stockVehModel) then
							stockVehDelivered = true
							RemoveBlip(blip)
							RemoveBlip(vehBlip)
							SetVehicleForwardSpeed(stockVeh, 0)
							SetVehicleEngineOn(stockVeh, false, false, true)
							if IsPedInAnyVehicle(GetPlayerPed(-1), true) then
								TaskLeaveVehicle(GetPlayerPed(-1), stockVeh, 4160)
								SetVehicleDoorsLockedForAllPlayers(stockVeh, true)
							end
							Citizen.Wait(1000)
							FreezeEntityPosition(stockVeh, true)
							exports['mythic_notify']:SendAlert('success', 'Du leverede produkterne.')
							--ShowNotifyHT("You ~g~successfully~s~ delivered the ~b~stock~s~")
							PlaySoundFrontend(-1, "Mission_Pass_Notify", "DLC_HEISTS_GENERAL_FRONTEND_SOUNDS", 0)
							TriggerServerEvent('olsen_drugbusiness:stockSaleSV', plyLabID, stockLevel, stockValue)
							endStockJob = true
						else
							exports['mythic_notify']:SendAlert('success', Lang['veh_not_matching'])
							--ShowNotifyHT(Lang['veh_not_matching'])
						end
					end
				end
			end

			if endStockJob then
				-- delete & reset vehicle:
				DeleteVehicle(stockVeh)
				stockVehModel	= nil
				stockVeh 		= nil
				stockVehSpawned = false
				Wait(100)
				-- delete and reset blip:
				if DoesBlipExist(blip) then
					RemoveBlip(blip)
					blip = nil
				elseif DoesBlipExist(vehBlip) then
					RemoveBlip(vehBlip)
					vehBlip = nil
				end
				Wait(100)
				Config.SellStock[id].started = false
				Wait(200)
				TriggerServerEvent('olsen_drugbusiness:SellJobDataSV',Config.SellStock)
				stockVehDelivered 	= false
				startPos			= nil
				endStockJob 		= false
				sellingStock 		= false
				Wait(100)
				break
			end
		end
	end
end)

endSupplyJob 	= false
deliveryStage 	= false
vehModel		= nil
jobVehSpawned 	= false
jobVeh 			= nil
goonSpawn 		= false
jobVehStolen 	= false
curStealing		= false
jobVehDelivered	= false
endPos			= nil
endBlip			= false

RegisterNetEvent('olsen_drugbusiness:SuppliesJob')
AddEventHandler('olsen_drugbusiness:SuppliesJob', function(id)
	local player = GetPlayerPed(-1)
	local goons = {}
	local gotSupplies = false
	local job = Config.StealSupplies[id]
	local blip = CreateJobBlip(job.location)
	local notifySound1, notifySound2, notifySound3, notifySound4 = false, false, false, false

	while not gotSupplies and not endSupplyJob do
		Citizen.Wait(0)
		
		if job.started then
			local coords = GetEntityCoords(player)
			local distance = GetDistanceBetweenCoords(coords, job.location[1], job.location[2], job.location[3], true)

			local streetNameHash = GetStreetNameAtCoord(job.location[1], job.location[2], job.location[3])
			local nameStreet = GetStreetNameFromHashKey(streetNameHash)

			if distance > 60 and not deliveryStage then
				DrawMissionText((Lang['job_go_to_location']:format(nameStreet)))
				if not notifySound1 then
					PlaySoundFrontend(-1, "Mission_Pass_Notify", "DLC_HEISTS_GENERAL_FRONTEND_SOUNDS", 0)
					notifySound1 = true
				end
			end

			if distance < 150 and not jobVehSpawned then
				ClearAreaOfVehicles(job.location[1], job.location[2], job.location[3], 15.0, false, false, false, false, false)
				jobVehSpawned = true
				Citizen.Wait(200)
				local num = math.random(1,#Config.JobVehicles)
				vehModel = Config.JobVehicles[num]
				HT.Game.SpawnVehicle(vehModel, {x = job.location[1], y = job.location[2], z = job.location[3]}, job.heading, function(veh)
					SetEntityCoordsNoOffset(veh, job.location[1], job.location[2], job.location[3])
					SetEntityHeading(veh,job.heading)
					FreezeEntityPosition(veh, true)
					SetVehicleOnGroundProperly(veh)
					FreezeEntityPosition(veh, false)
					SetEntityAsMissionEntity(jobVeh, true, true)
					jobVeh = veh
					SetVehicleDoorsLockedForAllPlayers(jobVeh, true)
				end)
			end	

			if distance < 150 and not goonSpawn then
				ClearAreaOfPeds(job.location[1], job.location[2], job.location[3], 50, 1)
				goonSpawn = true
				Citizen.Wait(200)
				SetPedRelationshipGroupHash(GetPlayerPed(-1), GetHashKey("PLAYER"))
				AddRelationshipGroup('JobNPCs')
				local i = 0
				for k,v in pairs(job.goons) do
					RequestModel(GetHashKey(v.ped))
					while not HasModelLoaded(GetHashKey(v.ped)) do
						Wait(1)
					end
					goons[i] = CreatePed(4, GetHashKey(v.ped), v.pos[1], v.pos[2], v.pos[3], v.h, false, true)
					NetworkRegisterEntityAsNetworked(goons[i])
					SetNetworkIdCanMigrate(NetworkGetNetworkIdFromEntity(goons[i]), true)
					SetNetworkIdExistsOnAllMachines(NetworkGetNetworkIdFromEntity(goons[i]), true)
					SetPedCanSwitchWeapon(goons[i], true)
					SetPedArmour(goons[i], 100)
					SetPedAccuracy(goons[i], 60)
					SetEntityInvincible(goons[i], false)
					SetEntityVisible(goons[i], true)
					SetEntityAsMissionEntity(goons[i])
					RequestAnimDict(v.animDict) 
					while not HasAnimDictLoaded(v.animDict) do
						Citizen.Wait(0) 
					end 
					TaskPlayAnim(goons[i], v.animDict, v.anim, 8.0, -8, -1, 49, 0, 0, 0, 0)
					GiveWeaponToPed(goons[i], GetHashKey(v.weapon), 255, false, false)
					SetPedDropsWeaponsWhenDead(goons[i], false)
					SetPedFleeAttributes(goons[i], 0, false)	
					SetPedRelationshipGroupHash(goons[i], GetHashKey("JobNPCs"))	
					TaskGuardCurrentPosition(goons[i], 5.0, 5.0, 1)
					i = i + 1
				end
			end
			
			if distance < 60 and distance > 10 and not deliveryStage then
				DrawMissionText(Lang['take_out_the_goons'])
				if not notifySound2 then
					PlaySoundFrontend(-1, "Mission_Pass_Notify", "DLC_HEISTS_GENERAL_FRONTEND_SOUNDS", 0)
					notifySound2 = true
				end
			end

			if distance < 60 and not job.JobPlayer then
				job.JobPlayer = true
				Wait(200)
				TriggerServerEvent('t1ger_drugs:JobDataSV',Config.Jobs)
				Citizen.Wait(200)
				SetPedRelationshipGroupHash(GetPlayerPed(-1), GetHashKey("PLAYER"))
				AddRelationshipGroup('JobNPCs')
				local i = 0
				for k,v in pairs(goons) do
                    ClearPedTasksImmediately(goons[i])
					SetRelationshipBetweenGroups(0, GetHashKey("JobNPCs"), GetHashKey("JobNPCs"))
					SetRelationshipBetweenGroups(5, GetHashKey("JobNPCs"), GetHashKey("PLAYER"))
					SetRelationshipBetweenGroups(5, GetHashKey("PLAYER"), GetHashKey("JobNPCs"))
                    i = i + 1
                end
			end
			
			if not jobVehStolen and distance < 10 then
				DrawMissionText(Lang['steal_the_supplies'])
				if not notifySound3 then
					PlaySoundFrontend(-1, "Mission_Pass_Notify", "DLC_HEISTS_GENERAL_FRONTEND_SOUNDS", 0)
					notifySound3 = true
				end
			end

			local jovVehPos = GetEntityCoords(jobVeh) 
			local distToVeh = GetDistanceBetweenCoords(coords, jovVehPos.x, jovVehPos.y, jovVehPos.z, true)
			
			if distToVeh <= 2 and not jobVehStolen then
				DrawText3Ds(jovVehPos.x, jovVehPos.y, jovVehPos.z, Lang['press_to_steal'])
				if IsControlJustPressed(0, Config.KeyToLockpickJobVeh) and not curStealing then 
					StealJobVehicle(job)
				end
			end

			
			if jobVehStolen and not jobVehDelivered then
				RemoveBlip(blip)
				if not endBlip then
					endBlip = true 
					endPos = Config.DrugLabs[plyLabID].delivery
					DeliveryBlip = AddBlipForCoord(endPos[1], endPos[2], endPos[3])
					SetBlipColour(DeliveryBlip,5)
					BeginTextCommandSetBlipName("STRING")
					AddTextComponentString("Levering")
					EndTextCommandSetBlipName(DeliveryBlip)
					SetBlipRoute(DeliveryBlip, true)
					SetBlipRouteColour(DeliveryBlip, 5) 
				end
				deliveryStage = true
			end

			if deliveryStage and not jobVehDelivered then
				DrawMissionText(Lang['deliver_supplies_back'])
				if not notifySound4 then
					PlaySoundFrontend(-1, "Mission_Pass_Notify", "DLC_HEISTS_GENERAL_FRONTEND_SOUNDS", 0)
					notifySound4 = true
				end
			end

			if deliveryStage then
                local coords = GetEntityCoords(GetPlayerPed(-1))
				local vehicle = GetVehiclePedIsIn(GetPlayerPed(-1), false)
				local distToDelivery = GetDistanceBetweenCoords(coords, endPos[1], endPos[2], endPos[3], true)
					if distToDelivery <= 10.0 then
						DrawMarker(21, endPos[1], endPos[2], endPos[3]-0.35, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.5, 0.5, 0.5, 88, 104, 154, 200, false, true, 2, true, false, false, false)
				end
				if distToDelivery <= 2.0 and not jobVehDelivered then
					DrawText3Ds(endPos[1], endPos[2], endPos[3], Lang['press_to_deliver'])
					if IsControlJustPressed(0, Config.KeyToDeliverJobVeh) then 
						if GetEntityModel(vehicle) == GetHashKey(vehModel) then
							jobVehDelivered = true
							RemoveBlip(DeliveryBlip)
							SetVehicleForwardSpeed(jobVeh, 0)
							SetVehicleEngineOn(jobVeh, false, false, true)
							if IsPedInAnyVehicle(GetPlayerPed(-1), true) then
								TaskLeaveVehicle(GetPlayerPed(-1), jobVeh, 4160)
								SetVehicleDoorsLockedForAllPlayers(jobVeh, true)
							end
							Citizen.Wait(1000)
							FreezeEntityPosition(jobVeh, true)
							deliveryStage = false
							exports['mythic_notify']:SendAlert('success', 'Du leverede et læs af forsyninger')
							--ShowNotifyHT("You ~g~successfully~s~ delivered one level of ~b~supplies~s~")
							PlaySoundFrontend(-1, "Mission_Pass_Notify", "DLC_HEISTS_GENERAL_FRONTEND_SOUNDS", 0)
							TriggerServerEvent('olsen_drugbusiness:jobReward',plyLabID)
							endSupplyJob = true
						else
							exports['mythic_notify']:SendAlert('success', Lang['veh_not_matching'])
							--ShowNotifyHT(Lang['veh_not_matching'])
						end
					end
				end
			end

			if endSupplyJob then
				-- delete & reset vehicle:
				DeleteVehicle(jobVeh)
				vehModel		= nil
				jobVeh 			= nil
				jobVehSpawned 	= false
				jobVehStolen 	= false
				Wait(100)
				-- delete and reset blip:
				if deliveryStage then
					if DeliveryBlip ~= nil then
						RemoveBlip(DeliveryBlip)
					end
				else
					if blip ~= nil then
						RemoveBlip(blip)
					end
				end
				Wait(100)
				-- delete and reset goons:
				local i = 0
                for k,v in pairs(job.goons) do
                    if DoesEntityExist(goons[i]) then
                        DeleteEntity(goons[i])
                    end
                    i = i + 1
				end
				Wait(100)
				Config.StealSupplies[id].started = false
				Wait(200)
				TriggerServerEvent('olsen_drugbusiness:JobDataSV',Config.StealSupplies)
				goons 				= {}
				goonSpawn 			= false
				deliveryStage 		= false
				curStealing			= false
				jobVehDelivered		= false
				endBlip				= false
				endPos				= nil
				endSupplyJob 		= false
				stealingSupplies 	= false
				Wait(100)
				break
			end
		end		
	end	
end)

function GetStreetName(playerPos)
    local s1, s2 = Citizen.InvokeNative( 0x2EB41072B4C1E4C0, playerPos.x, playerPos.y, playerPos.z, Citizen.PointerValueInt(), Citizen.PointerValueInt() )
    local street1 = GetStreetNameFromHashKey(s1)
    local street2 = GetStreetNameFromHashKey(s2)

    if s2 == 0 then
        return street1
    elseif s2 ~= 0 then
        return street1 .. " - " .. street2
    end
end

-- Steal Job Vehicle:
function StealJobVehicle(val)	
	local player = GetPlayerPed(-1)
	local animDict = "anim@amb@clubhouse@tutorial@bkr_tut_ig3@"
	local animName = "machinic_loop_mechandplayer"
	RequestAnimDict(animDict)
	while not HasAnimDictLoaded(animDict) do
		Citizen.Wait(10)
	end

	if Config.NotifyCops then
		--NotifyPoliceFunction()
		local player = GetPlayerPed(-1)
        local playerCoords = GetEntityCoords(player)
        local street = GetStreetName(playerCoords) 
        dabs = "Biltyveri"
        TriggerServerEvent('dispatch', dabs, street, playerCoords)    
	end

	SetCurrentPedWeapon(player, GetHashKey("WEAPON_UNARMED"),true)
	Citizen.Wait(500)
	FreezeEntityPosition(player, true)
	TaskPlayAnimAdvanced(player, animDict, animName, val.anim.pos[1], val.anim.pos[2], val.anim.pos[3], 0.0, 0.0, val.anim.h, 3.0, 1.0, -1, 31, 0, 0, 0 )

	exports['av_progressbar']:startUI(5000, Lang['progbar_stealing'])
	Citizen.Wait(5000)
	
	ClearPedTasks(player)
	FreezeEntityPosition(player, false)
	jobVehStolen = true
	curStealing = false
	SetVehicleDoorsLockedForAllPlayers(jobVeh, false)
end

-- Function for job blip in progress:
function CreateJobBlip(pos)
	local blip = AddBlipForCoord(pos[1],pos[2],pos[3])
	SetBlipSprite(blip, 1)
	SetBlipColour(blip, 5)
	AddTextEntry('MYBLIP', "Stjæl Forsyninger")
	BeginTextCommandSetBlipName('MYBLIP')
	AddTextComponentSubstringPlayerName(name)
	EndTextCommandSetBlipName(blip)
	SetBlipScale(blip, 0.75) -- set scale
	SetBlipAsShortRange(blip, true)
	SetBlipRoute(blip, true)
	SetBlipRouteColour(blip, 5)
	return blip
end

-- Function for job blip in progress:
function CreateStockBlip(pos)
	local blip = AddBlipForCoord(pos[1],pos[2],pos[3])
	SetBlipSprite(blip, 1)
	SetBlipColour(blip, 5)
	AddTextEntry('MYBLIP', "Narkohandel")
	BeginTextCommandSetBlipName('MYBLIP')
	AddTextComponentSubstringPlayerName(name)
	EndTextCommandSetBlipName(blip)
	SetBlipDisplay(blip, 2)
	SetBlipScale(blip, 0.75) -- set scale
	SetBlipAsShortRange(blip, true)
	SetBlipRoute(blip, true)
	SetBlipRouteColour(blip, 5)
	return blip
end
