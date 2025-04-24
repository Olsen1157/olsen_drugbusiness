Config = {}

-- Police Settings:
Config.NotifyCops = true				-- Notify police when stealing job vehicle

-- Blip Settings for drug labs:
Config.BlipSettings = {
	enable = true,
	sprite = 492,
	display = 4,
	scale = 0.65,
	color = 0
} 

-- Buttons:
Config.KeyToManageLab			= 38		-- Default: [E]
Config.KeyToPurchaseLab			= 38		-- Default: [E]
Config.KeyToRobLab				= 38		-- Default: [E]
Config.KeyToRaidLab				= 38		-- Default: [E]
Config.KeyToLaptop				= 38 		-- Default: [E]
Config.KeyToLeaveLab			= 38		-- Default: [E]
Config.KeyToDeliverStockVeh		= 38		-- Default: [E]
Config.KeyToLockpickJobVeh		= 38 		-- Default: [E]
Config.KeyToDeliverJobVeh		= 38		-- Default: [E]

-- General Settings:
Config.PayDrugLabWithCash 		= true		-- Set to false to use bank money instead
Config.RecieveSoldLabCash       = true      -- Set to false to receive bank money on sale of drug lab
Config.OwnedLabBlip 			= true		-- Blip for owned lab (source player)
Config.SellPercent              = 0.25      -- Means player gets 75% in return from original paid price
Config.SupplyLevelPrice			= 50000		-- Set price to purchase one level of supplies in drug lab
Config.StockLevelPrice			= 80000		-- Set sell price for each level of stuck in drug lab
Config.ProductionMinutes		= 30		-- Set value in minutes for interval of producing one level of supplies into one level of stock.
Config.SellMultiplier = { 1.0, 1.1, 1.2, 1.3, 1.5 } -- set stovk value multiplier for each level of stock upon sale

-- Robbery Settings:
Config.RobLabWhenPlayerOffline	= true		-- Set to false to disable robbing a drug lab where owner of the lab is offline.
Config.WaitTimeUntilHack 		= 15		-- Set time in seconds, until hacking device is ready. This is time the owner of lab has to react on it an take down possible intruders.
Config.mHackingBlocks			= 3			-- Set amount of hacking blocks in mhacking
Config.mHackingSeconds			= 30		-- Set amount of seconds for mHacking minigame

-- Police Settings:
Config.RaidLabWhenPlayerOffline	= true		-- Set to false to disable police raiding a drug lab where owner of the lab is offline.
Config.WaitTimeUntilRaid		= 10		-- Set time in seconds, until police enter the lab. This is time the owner of lab has to react on it an take down possible police.

-- Labs:
Config.DrugLabs = {
    [1] = { pos = {387.46557617188,3584.8132324219,33.292274475098}, h = 175.028, prop = 'lab_meth', price = 3500000, delivery = {386.50692749023,3592.3774414062,33.292236328125,260.789} },
    [2] = { pos = {-288.5966796875,6299.3291015625,31.492261886597}, h = 226.295, prop = 'lab_coke', price = 2200000, delivery = {-295.8971862793,6302.1997070312,31.492259979248,130.885} },
    [3] = { pos = {2570.7299804688,4667.8935546875,34.076805114746}, h = 319.279, prop = 'lab_weed', price = 3000000, delivery = {2562.2109375,4686.3232421875,34.137702941895,56.201} },
}

-- Offset spots relative to the spawned shell object. Do not mess with this, if you don't know what u are doing.
-- Read more about offsets here: https://runtime.fivem.net/doc/natives/?_0x1899F328B0E12848
Config.Offsets = {
	['lab_coke'] = { entry = {1088.7580566406,-3187.4624023438,-38.993492126465},  h = 180.89, laptop = {1087.1405029297,-3194.2976074219,-38.993473052979}, animPos = {1087.1405029297,-3194.2976074219,-38.993473052979}, animHead = 90.29 },
	['lab_meth'] = { entry = {996.896, -3200.645, -36.393},  h = 263.45, laptop = {1001.9449462891,-3194.8620605469,-38.993125915527}, animPos = {1001.9449462891,-3194.8620605469,-38.993125915527}, animHead = 359.60 },
	['lab_weed'] = { entry = {1066.3610839844, -3183.3369140625, -39.16353225708}, h = 89.85,  laptop = {1044.6020507813,-3194.8908691406,-38.157875061035}, animPos = {1044.6020507813,-3194.8908691406,-38.157875061035}, animHead = 272.33 },
}

-- Job Vehicles:
Config.JobVehicles = { "rumpo2", "rumpo", "speedo", "pony", "burrito4", "burrito3" }
Config.StockSellVeh = 'mule2'

-- Job Delivery Marker Setting:
Config.DeliveryMarker = { enable = true, drawDist = 10.0, type = 27, scale = { x = 5.0, y = 5.0, z = 1.0 }, color = { r = 244, g = 208, b = 63, a = 100 } }

-- Steal Supplies:
Config.StealSupplies = {
	[1] = {
		location = {918.15844726562,-1553.9730224609,30.773410797119},
		heading = 302.055,
		anim = {pos = {917.74365234375,-1552.5068359375,30.774814605713}, h = 201.78},
		started = false,
		goons = {
			[1] = { pos = {916.16497802734,-1551.3813476562,30.767101287842}, h = 146.12, ped = 'g_m_y_mexgoon_01', 		animDict = 'amb@world_human_cop_idles@female@base', 					animName = 'base', 				weapon = 'WEAPON_HEAVYPISTOL', },
			[2] = { pos = {914.56732177734,-1553.9123535156,30.747766494751}, h = 159.6, 	ped = 'g_m_y_mexgoon_02', 	animDict = 'rcmme_amanda1', 											animName = 'stand_loop_cop', 	weapon = 'WEAPON_MICROSMG', },
			[3] = { pos = {914.54107666016,-1555.4217529297,30.742826461792}, 	h = 197.48, ped = 'g_m_y_mexgoon_03', animDict = 'amb@world_human_leaning@male@wall@back@legs_crossed@base', 	animName = 'base', 				weapon = 'WEAPON_MINISMG', },
		},
	},
	[2] = {
		location = {334.50592041016,-2039.1304931641,21.102170944214},
		heading = 223.671,
		anim = {pos = {335.80062866211,-2038.4970703125,21.177841186523}, h = 141.098},
		started = false,
		goons = {
			[1] = { pos = {333.15432739258,-2036.0319824219,21.099889755249}, h = 146.12, ped = 'g_m_y_mexgoon_01', 		animDict = 'amb@world_human_cop_idles@female@base', 					animName = 'base', 				weapon = 'WEAPON_HEAVYPISTOL', },
			[2] = { pos = {331.91751098633,-2036.7020263672,21.03782081604}, h = 159.6, 	ped = 'g_m_y_mexgoon_02', 	animDict = 'rcmme_amanda1', 											animName = 'stand_loop_cop', 	weapon = 'WEAPON_MICROSMG', },
			[3] = { pos = {330.87927246094,-2037.5662841797,20.977735519409}, 	h = 197.48, ped = 'g_m_y_mexgoon_03', animDict = 'amb@world_human_leaning@male@wall@back@legs_crossed@base', 	animName = 'base', 				weapon = 'WEAPON_MINISMG', },
		},
	},
    [3] = {
		location = {85.924629211426,-1970.8991699219,20.74746131897},
		heading = 153.321,
		anim = {pos = {87.09937286377,-1971.8146972656,20.747463226318}, h = 47.304},
		started = false,
		goons = {
			[1] = { pos = {89.273948669434,-1969.1806640625,20.747495651245}, h = 146.12, ped = 'g_m_y_ballaeast_01', 		animDict = 'amb@world_human_cop_idles@female@base', 					animName = 'base', 				weapon = 'WEAPON_HEAVYPISTOL', },
			[2] = { pos = {88.115737915039,-1968.1400146484,20.747451782227}, h = 159.6, 	ped = 'g_m_y_ballaorig_01', 	animDict = 'rcmme_amanda1', 											animName = 'stand_loop_cop', 	weapon = 'WEAPON_MICROSMG', },
			[3] = { pos = {87.188293457031,-1967.3239746094,20.747451782227}, 	h = 197.48, ped = 'g_m_y_ballasout_01', animDict = 'amb@world_human_leaning@male@wall@back@legs_crossed@base', 	animName = 'base', 				weapon = 'WEAPON_MINISMG', },
		},
	},
	[4] = {
		location = {-239.79501342773,-1592.9566650391,33.610298156738},
		heading = 1.566,
		anim = {pos = {-241.23837280273,-1592.4973144531,33.611339569092}, h = 272.262},
		started = false,
		goons = {
			[1] = { pos = {-241.0320892334,-1596.4807128906,33.609649658203}, h = 146.12, ped = 'g_m_y_famca_01', 		animDict = 'amb@world_human_cop_idles@female@base', 					animName = 'base', 				weapon = 'WEAPON_HEAVYPISTOL', },
			[2] = { pos = {-239.70086669922,-1596.71875,33.591957092285}, h = 159.6, 	ped = 'g_m_y_famdnf_01', 	animDict = 'rcmme_amanda1', 											animName = 'stand_loop_cop', 	weapon = 'WEAPON_MICROSMG', },
			[3] = { pos = {-238.36892700195,-1596.7954101562,33.777000427246}, 	h = 197.48, ped = 'g_m_importexport_01', animDict = 'amb@world_human_leaning@male@wall@back@legs_crossed@base', 	animName = 'base', 				weapon = 'WEAPON_MINISMG', },
		},
	},
	[5] = {
		location = {981.80047607422,-112.76662445068,74.137939453125},
		heading = 314.516,
		anim = {pos = {981.24664306641,-111.50637817383,74.31763458252}, h = 222.487},
		started = false,
		goons = {
			[1] = { pos = {978.46008300781,-114.02925872803,74.353141784668}, h = 146.12, ped = 'g_m_y_lost_01', 		animDict = 'amb@world_human_cop_idles@female@base', 					animName = 'base', 				weapon = 'WEAPON_HEAVYPISTOL', },
			[2] = { pos = {979.15423583984,-115.40582275391,74.203552246094}, h = 159.6, 	ped = 'g_m_y_lost_02', 	animDict = 'rcmme_amanda1', 											animName = 'stand_loop_cop', 	weapon = 'WEAPON_MICROSMG', },
			[3] = { pos = {980.20196533203,-116.22283935547,74.056648254395}, h = 197.48, ped = 'g_m_y_lost_03', animDict = 'amb@world_human_leaning@male@wall@back@legs_crossed@base', 	animName = 'base', 				weapon = 'WEAPON_MINISMG', },
		},
	},
}

Config.SellStock = {
	[1] = { 
		started = false,
		location = {951.478515625,-2110.5080566406,30.551561355591},
	},
	[2] = { 
		started = false,
		location = {-115.79835510254,-2691.94140625,6.0225577354431},
	},
	[3] = { 
		started = false,
		location = {-1314.7646484375,-1259.1158447266,4.574360370636},
	},
}