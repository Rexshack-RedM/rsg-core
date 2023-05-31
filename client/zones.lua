local EnteredZone = false

-- Zone Data --
local function ZoneData(hash)
	local data = nil
	if hash ~= nil then
		local zoneInfo = Zones[hash]
		if zoneInfo then data = zoneInfo.texture end
	end
	return data
end

-- Zone Alerts --
local function ZoneAlert()
	local zone = ZoneData(EnteredZone)
	local time = RSGCore.Functions.GetCurrentTime()
	local temp = RSGCore.Functions.GetTemperature()
	if zone then
		RSGCore.Functions.NativeNotify(6, '~COLOR_YELLOWLIGHT~ '..time..' ~COLOR_REDDARK~   |   ~COLOR_ORANGE~ '..temp, 4000, zone, 'generic_textures', 'tick', "COLOR_YELLOW")
	end
end

-- Check Zones --
CreateThread(function()
	while true do
		Wait(3000)
		if LocalPlayer.state.isLoggedIn then
			local coords = GetEntityCoords(PlayerPedId())
			local zone = nil

			local tempstate = Citizen.InvokeNative(0x43AD8FC02B429D33, coords, 0) -- State
			if tempstate then zone = tempstate end

			local tempwritten = Citizen.InvokeNative(0x43AD8FC02B429D33, coords, 13)
			if tempwritten then zone = tempwritten end

			local tempprint = Citizen.InvokeNative(0x43AD8FC02B429D33, coords, 12)
			if tempprint then zone = tempprint end

			local tempdistrict = Citizen.InvokeNative(0x43AD8FC02B429D33, coords, 10) -- District
			if tempdistrict then zone = tempdistrict end

			local temptown = Citizen.InvokeNative(0x43AD8FC02B429D33, coords, 1) -- Town
			if temptown then zone = temptown end

			if EnteredZone ~= zone then
				EnteredZone = zone
				ZoneAlert()
			end
		end
	end
end)

-- Zones Data --
-- Credits:
-- https://github.com/femga/rdr3_discoveries/tree/master/zones (Zones Data)
-- https://github.com/VORPCORE/vorp_zonenotify (Compiled Zones into Config)

Zones = {
    [2025841068] = {
      texture = "water_kamassa_river_bayou_nwa",
      zoneHash = 2025841068,
      ZoneTypeId = 10
    },
    [178647645] = {
      texture = "district_roanoake_ridge",
      zoneHash = 178647645,
      ZoneTypeId = 10
    },
    [-1851305682] = {
      texture = "settlement_cornwall_kerosene_tar",
      zoneHash = -1851305682,
      ZoneTypeId = 1
    },
    [-765540529] = {
      texture = "town_saintdenis",
      zoneHash = -765540529,
      ZoneTypeId = 1,
    },
    [6184171] = {
       zoneHash = 6184171,
       ZoneTypeId = 12,
       texture = "landmark_scratching_post"
    },
    [7359335] = {
       zoneHash = 7359335,
       ZoneTypeId = 1,
       texture = "town_annesburg"
    },
    [10837344] = {
       zoneHash = 10837344,
       ZoneTypeId = 0,
       texture = "state_lemoyne"
    },
    [14408272] = {
       zoneHash = 14408272,
       ZoneTypeId = 11,
       texture = "water_flat_iron_lake"
    },
    [30800579] = {
       zoneHash = 30800579,
       ZoneTypeId = 12,
       texture = "landmark_hagen_orchards"
    },
    [31314838] = {
       zoneHash = 31314838,
       ZoneTypeId = 12,
       texture = "landmark_the_hanging_rock"
    },
    [39999178] = {
       zoneHash = 39999178,
       ZoneTypeId = 12,
       texture = "hideout_gaptooth_breach"
    },
    [126047903] = {
       zoneHash = 126047903,
       ZoneTypeId = 12,
       texture = "landmark_venters_place"
    },
    [131399519] = {
       zoneHash = 131399519,
       ZoneTypeId = 10,
       texture = "district_heartlands"
    },
    [201158410] = {
       zoneHash = 201158410,
       ZoneTypeId = 1,
       texture = "settlement_aguasdulces"
    },
    [206751400] = {
       zoneHash = 206751400,
       ZoneTypeId = 11,
       texture = "landmark_bacchus_bridge"
    },
    [219097977] = {
       zoneHash = 219097977,
       ZoneTypeId = 12,
       texture = "homestead_aberdeen_pig_farm"
    },
    [229479634] = {
       zoneHash = 229479634,
       ZoneTypeId = 12,
       texture = "landmark_luckys_cabin"
    },
    [278622988] = {
       zoneHash = 278622988,
       ZoneTypeId = 11,
       texture = "settlement_plainview"
    },
    [350117545] = {
       zoneHash = 350117545,
       ZoneTypeId = 11,
       texture = "settlement_emerald_ranch"
    },
    [370072007] = {
       zoneHash = 370072007,
       ZoneTypeId = 3,
       texture = "water_dakota_river"
    },
    [375900073] = {
       zoneHash = 375900073,
       ZoneTypeId = 12,
       texture = "landmark_nekoti_rock"
    },
    [406627834] = {
       zoneHash = 406627834,
       ZoneTypeId = 1,
       texture = "settlement_lagras"
    },
    [417930523] = {
       zoneHash = 417930523,
       ZoneTypeId = 12,
       texture = "settlement_el_nido"
    },
    [422513214] = {
       zoneHash = 422513214,
       ZoneTypeId = 11,
       texture = "landmark_calumet_ravine"
    },
    [427683330] = {
       zoneHash = 427683330,
       ZoneTypeId = 1,
       texture = "town_strawberry"
    },
    [459833523] = {
       zoneHash = 459833523,
       ZoneTypeId = 1,
       texture = "town_valentine"
    },
    [466986025] = {
       zoneHash = 466986025,
       ZoneTypeId = 11,
       texture = "hideout_lakay"
    },
    [469159176] = {
       zoneHash = 469159176,
       ZoneTypeId = 7,
       texture = "landmark_dewberry_creek"
    },
    [476637847] = {
       zoneHash = 476637847,
       ZoneTypeId = 10,
       texture = "district_great_plains"
    },
    [492552869] = {
       zoneHash = 492552869,
       ZoneTypeId = 12,
       texture = "settlement_cornwall_kerosene_tar"
    },
    [522499758] = {
       zoneHash = 522499758,
       ZoneTypeId = 12,
       texture = "homestead_compsons_stead"
    },
    [548590694] = {
       zoneHash = 548590694,
       ZoneTypeId = 11,
       texture = "water_mount_shann"
    },
    [573463789] = {
       zoneHash = 573463789,
       ZoneTypeId = 11,
       texture = "landmark_calibans_seat"
    },
    [578416223] = {
       zoneHash = 578416223,
       ZoneTypeId = 11,
       texture = "settlement_manzanita_post"
    },
    [580715948] = {
       zoneHash = 580715948,
       ZoneTypeId = 12,
       texture = "landmark_canebreak_manor"
    },
    [591254234] = {
       zoneHash = 591254234,
       ZoneTypeId = 11,
       texture = "water_cairn_lake"
    },
    [592454541] = {
       zoneHash = 592454541,
       ZoneTypeId = 2,
       texture = "water_lake_isabella"
    },
    [690770514] = {
       zoneHash = 690770514,
       ZoneTypeId = 12,
       texture = "landmark_valley_view"
    },
    [721024961] = {
       zoneHash = 721024961,
       ZoneTypeId = 11,
       texture = "landmark_quakers_cove"
    },
    [735229158] = {
       zoneHash = 735229158,
       ZoneTypeId = 11,
       texture = "water_ocreaghs_run"
    },
    [738939338] = {
       zoneHash = 738939338,
       ZoneTypeId = 12,
       texture = "landmark_rileys_charge"
    },
    [769580703] = {
       zoneHash = 769580703,
       ZoneTypeId = 11,
       texture = "landmark_riggs_station"
    },
    [770707682] = {
       zoneHash = 770707682,
       ZoneTypeId = 12,
       texture = "homestead_lonnies_shack"
    },
    [795414694] = {
       zoneHash = 795414694,
       ZoneTypeId = 2,
       texture = "water_barrow_lagoon"
    },
    [822658194] = {
       zoneHash = 822658194,
       ZoneTypeId = 10,
       texture = "district_big_valley"
    },
    [831787576] = {
       zoneHash = 831787576,
       ZoneTypeId = 11,
       texture = "water_lake_isabella"
    },
    [866178028] = {
       zoneHash = 866178028,
       ZoneTypeId = 12,
       texture = "hideout_shady_belle"
    },
    [878474860] = {
       zoneHash = 878474860,
       ZoneTypeId = 12,
       texture = "hideout_solomons_folly"
    },
    [892930832] = {
       zoneHash = 892930832,
       ZoneTypeId = 10,
       texture = "district_hennigans_stead"
    },
    [893044669] = {
       zoneHash = 893044669,
       ZoneTypeId = 12,
       texture = "settlement_pleasance"
    },
    [894611678] = {
       zoneHash = 894611678,
       ZoneTypeId = 11,
       texture = "settlement_lagras"
    },
    [903669278] = {
       zoneHash = 903669278,
       ZoneTypeId = 11,
       texture = "settlement_thieves_landing"
    },
    [930788089] = {
       zoneHash = 930788089,
       ZoneTypeId = 12,
       texture = "landmark_siltwater_strand"
    },
    [1016304714] = {
       zoneHash = 1016304714,
       ZoneTypeId = 12,
       texture = "landmark_mossy_flats"
    },
    [1035413795] = {
       zoneHash = 1035413795,
       ZoneTypeId = 11,
       texture = "landmark_diablo_ridge"
    },
    [1053078005] = {
       zoneHash = 1053078005,
       ZoneTypeId = 1,
       texture = "town_blackwater"
    },
    [1062452343] = {
       zoneHash = 1062452343,
       ZoneTypeId = 12,
       texture = "landmark_macombs_end"
    },
    [1073515151] = {
       zoneHash = 1073515151,
       ZoneTypeId = 11,
       texture = "landmark_la_capilla"
    },
    [1082216465] = {
       zoneHash = 1082216465,
       ZoneTypeId = 12,
       texture = "landmark_copperhead_landing"
    },
    [1085851378] = {
       zoneHash = 1085851378,
       ZoneTypeId = 11,
       texture = "landmark_brandywine_drop"
    },
    [1106871234] = {
       zoneHash = 1106871234,
       ZoneTypeId = 11,
       texture = "settlement_sisika_penitentiary"
    },
    [1136441188] = {
       zoneHash = 1136441188,
       ZoneTypeId = 12,
       texture = "landmark_repentance"
    },
    [1192830049] = {
       zoneHash = 1192830049,
       ZoneTypeId = 11,
       texture = "water_aurora_basin"
    },
    [1194268234] = {
       zoneHash = 1194268234,
       ZoneTypeId = 11,
       texture = "water_lake_don_julio"
    },
    [1200586933] = {
       zoneHash = 1200586933,
       ZoneTypeId = 11,
       texture = "landmark_eris_field"
    },
    [1212679502] = {
       zoneHash = 1212679502,
       ZoneTypeId = 12,
       texture = "landmark_beryls_dream"
    },
    [1245451421] = {
       zoneHash = 1245451421,
       ZoneTypeId = 7,
       texture = "water_deadboot_creek"
    },
    [1246494439] = {
       zoneHash = 1246494439,
       ZoneTypeId = 0,
       texture = "state_west_elizabeth"
    },
    [1246510947] = {
       zoneHash = 1246510947,
       ZoneTypeId = 11,
       texture = "landmark_window_rock"
    },
    [1247830528] = {
       zoneHash = 1247830528,
       ZoneTypeId = 12,
       texture = "landmark_cueva_seca"
    },
    [1299204683] = {
       zoneHash = 1299204683,
       ZoneTypeId = 1,
       texture = "town_manicato"
    },
    [1305807350] = {
       zoneHash = 1305807350,
       ZoneTypeId = 11,
       texture = "town_rhodes"
    },
    [1318629609] = {
       zoneHash = 1318629609,
       ZoneTypeId = 11,
       texture = "water_upper_montana_river"
    },
    [1350749955] = {
       zoneHash = 1350749955,
       ZoneTypeId = 12,
       texture = "landmark_merkins_waller"
    },
    [1418297928] = {
       zoneHash = 1418297928,
       ZoneTypeId = 11,
       texture = "water_deadboot_creek"
    },
    [1453682244] = {
       zoneHash = 1453682244,
       ZoneTypeId = 11,
       texture = "landmark_wallace_station"
    },
    [1474025912] = {
       zoneHash = 1474025912,
       ZoneTypeId = 11,
       texture = "landmark_benedict_pass"
    },
    [1477464408] = {
       zoneHash = 1477464408,
       ZoneTypeId = 12,
       texture = "landmark_rattlesnake_hollow"
    },
    [1490773376] = {
       zoneHash = 1490773376,
       ZoneTypeId = 11,
       texture = "landmark_roanoke_valley"
    },
    [1498241388] = {
       zoneHash = 1498241388,
       ZoneTypeId = 11,
       texture = "water_barrow_lagoon"
    },
    [1544029611] = {
       zoneHash = 1544029611,
       ZoneTypeId = 12,
       texture = "settlement_ridgewood_farm"
    },
    [1558584712] = {
       zoneHash = 1558584712,
       ZoneTypeId = 11,
       texture = "water_lannahechee_river"
    },
    [1560871107] = {
       zoneHash = 1560871107,
       ZoneTypeId = 11,
       texture = "water_mattock_pond"
    },
    [1573733873] = {
       zoneHash = 1573733873,
       ZoneTypeId = 11,
       texture = "water_owanjila"
    },
    [1595262844] = {
       zoneHash = 1595262844,
       ZoneTypeId = 11,
       texture = "water_kamassa_river"
    },
    [1613985721] = {
       zoneHash = 1613985721,
       ZoneTypeId = 12,
       texture = "settlement_grand_korrigan"
    },
    [1645618177] = {
       zoneHash = 1645618177,
       ZoneTypeId = 10,
       texture = "district_grizzlies"
    },
    [1654810713] = {
       zoneHash = 1654810713,
       ZoneTypeId = 1,
       texture = "settlement_aguasdulces"
    },
    [1663398575] = {
       zoneHash = 1663398575,
       ZoneTypeId = 1,
       texture = "settlement_wapiti"
    },
    [1677110452] = {
       zoneHash = 1677110452,
       ZoneTypeId = 11,
       texture = "water_moonstone_pond"
    },
    [1677148641] = {
       zoneHash = 1677148641,
       ZoneTypeId = 12,
       texture = "settlement_beechers_hope"
    },
    [1684533001] = {
       zoneHash = 1684533001,
       ZoneTypeId = 10,
       texture = "district_tall_trees"
    },
    [1688095983] = {
       zoneHash = 1688095983,
       ZoneTypeId = 11,
       texture = "water_spider_gorge"
    },
    [1701820039] = {
       zoneHash = 1701820039,
       ZoneTypeId = 12,
       texture = "homestead_catfish_jacksons"
    },
    [1747109213] = {
       zoneHash = 1747109213,
       ZoneTypeId = 11,
       texture = "water_elysian_pool"
    },
    [1755369577] = {
       zoneHash = 1755369577,
       ZoneTypeId = 2,
       texture = "district_heartlands"
    },
    [1767462106] = {
       zoneHash = 1767462106,
       ZoneTypeId = 12,
       texture = "homestead_larned_sod"
    },
    [1767717886] = {
       zoneHash = 1767717886,
       ZoneTypeId = 11,
       texture = "water_ringneck_creek"
    },
    [1806114556] = {
       zoneHash = 1806114556,
       ZoneTypeId = 11,
       texture = "landmark_mount_hagen"
    },
    [1830267951] = {
       zoneHash = 1830267951,
       ZoneTypeId = 12,
       texture = "hideout_clemens_point"
    },
    [1860483486] = {
       zoneHash = 1860483486,
       ZoneTypeId = 11,
       texture = "landmark_rio_del_lobo_rock"
    },
    [1922831023] = {
       zoneHash = 1922831023,
       ZoneTypeId = 12,
       texture = "landmark_greenhollow"
    },
    [1935063277] = {
       zoneHash = 1935063277,
       ZoneTypeId = 0,
       texture = "state_guarma"
    },
    [1962976783] = {
       zoneHash = 1962976783,
       ZoneTypeId = 11,
       texture = "landmark_donner_falls"
    },
    [1987954784] = {
       zoneHash = 1987954784,
       ZoneTypeId = 12,
       texture = "homestead_clingman"
    },
    [2005774838] = {
       zoneHash = 2005774838,
       ZoneTypeId = 7,
       texture = "water_ringneck_creek"
    },
    [2014257401] = {
       zoneHash = 2014257401,
       ZoneTypeId = 11,
       texture = "water_little_creek_river"
    },
    [2018850994] = {
       zoneHash = 2018850994,
       ZoneTypeId = 11,
       texture = "landmark_jorges_gap"
    },
    [2045157995] = {
       zoneHash = 2045157995,
       ZoneTypeId = 0,
       texture = "state_new_austin"
    },
    [2046780049] = {
       zoneHash = 2046780049,
       ZoneTypeId = 1,
       texture = "town_rhodes"
    },
    [2056953687] = {
       zoneHash = 2056953687,
       ZoneTypeId = 12,
       texture = "hideout_six_point_cabin"
    },
    [2084778330] = {
       zoneHash = 2084778330,
       ZoneTypeId = 11,
       texture = "settlement_caliga_hall"
    },
    [2110038470] = {
       zoneHash = 2110038470,
       ZoneTypeId = 11,
       texture = "landmark_heartland_overflow"
    },
    [2126321341] = {
       zoneHash = 2126321341,
       ZoneTypeId = 1,
       texture = "town_vanhorn"
    },
    [2132554759] = {
       zoneHash = 2132554759,
       ZoneTypeId = 12,
       texture = "landmark_millesani_claim"
    },
    [-557290573] = {
       zoneHash = -557290573,
       ZoneTypeId = 5,
       texture = "district_bayou_nwa"
    },
    [-1825355772] = {
       zoneHash = -1825355772,
       ZoneTypeId = 11,
       texture = "district_bluewater_marsh"
    },
    [-120156735] = {
       zoneHash = -120156735,
       ZoneTypeId = 10,
       texture = "district_grizzlies"
    },
    [-512529193] = {
       zoneHash = -512529193,
       ZoneTypeId = 10,
       texture = "state_guarma"
    },
    [-139400310] = {
       zoneHash = -139400310,
       ZoneTypeId = 12,
       texture = "hideout_beaver_hollow"
    },
    [-1496551068] = {
       zoneHash = -1496551068,
       ZoneTypeId = 12,
       texture = "hideout_colter"
    },
    [-1037423548] = {
       zoneHash = -1037423548,
       ZoneTypeId = 11,
       texture = "hideout_fort_mercer"
    },
    [-103399754] = {
       zoneHash = -103399754,
       ZoneTypeId = 12,
       texture = "hideout_hanging_dog_ranch"
    },
    [-1359523911] = {
       zoneHash = -1359523911,
       ZoneTypeId = 12,
       texture = "hideout_horseshoe_overlook"
    },
    [-336631570] = {
       zoneHash = -336631570,
       ZoneTypeId = 12,
       texture = "hideout_pikes_basin"
    },
    [-1988735197] = {
       zoneHash = -1988735197,
       ZoneTypeId = 11,
       texture = "hideout_twin_rocks"
    },
    [-1043500161] = {
       zoneHash = -1043500161,
       ZoneTypeId = 12,
       texture = "homestead_adler_ranch"
    },
    [-1902025470] = {
       zoneHash = -1902025470,
       ZoneTypeId = 12,
       texture = "homestead_carmody_dell"
    },
    [-814535426] = {
       zoneHash = -814535426,
       ZoneTypeId = 12,
       texture = "homestead_chadwick_farm"
    },
    [-2034338067] = {
       zoneHash = -2034338067,
       ZoneTypeId = 12,
       texture = "homestead_chez_porter"
    },
    [-645154787] = {
       zoneHash = -645154787,
       ZoneTypeId = 12,
       texture = "homestead_doverhill"
    },
    [-657053325] = {
       zoneHash = -657053325,
       ZoneTypeId = 12,
       texture = "homestead_downes_ranch"
    },
    [-146460093] = {
       zoneHash = -146460093,
       ZoneTypeId = 12,
       texture = "homestead_firwood_rise"
    },
    [-1472363892] = {
       zoneHash = -1472363892,
       ZoneTypeId = 12,
       texture = "homestead_guthrie_farm"
    },
    [-1769528472] = {
       zoneHash = -1769528472,
       ZoneTypeId = 12,
       texture = "homestead_hill_haven_ranch"
    },
    [-576782619] = {
       zoneHash = -576782619,
       ZoneTypeId = 12,
       texture = "homestead_lone_mule_stead"
    },
    [-1592070727] = {
       zoneHash = -1592070727,
       ZoneTypeId = 12,
       texture = "homestead_macleans_house"
    },
    [-1521776363] = {
       zoneHash = -1521776363,
       ZoneTypeId = 12,
       texture = "homestead_painted_sky"
    },
    [-504005310] = {
       zoneHash = -504005310,
       ZoneTypeId = 12,
       texture = "homestead_shepherds_rise"
    },
    [-1161186391] = {
       zoneHash = -1161186391,
       ZoneTypeId = 12,
       texture = "homestead_watsons_cabin"
    },
    [-154855189] = {
       zoneHash = -154855189,
       ZoneTypeId = 12,
       texture = "homestead_willards_rest"
    },
    [-1660988219] = {
       zoneHash = -1660988219,
       ZoneTypeId = 11,
       texture = "landmark_bards_crossing"
    },
    [-264897431] = {
       zoneHash = -264897431,
       ZoneTypeId = 12,
       texture = "landmark_bear_claw"
    },
    [-969933882] = {
       zoneHash = -969933882,
       ZoneTypeId = 12,
       texture = "landmark_black_balsam_rise"
    },
    [-1539536559] = {
       zoneHash = -1539536559,
       ZoneTypeId = 12,
       texture = "landmark_black_bone_forest"
    },
    [-67181220] = {
       zoneHash = -67181220,
       ZoneTypeId = 11,
       texture = "landmark_bolger_glade"
    },
    [-2126414432] = {
       zoneHash = -2126414432,
       ZoneTypeId = 12,
       texture = "landmark_broken_tree"
    },
    [-2028095666] = {
       zoneHash = -2028095666,
       ZoneTypeId = 11,
       texture = "settlement_cinco_torres"
    },
    [-1349514245] = {
       zoneHash = -1349514245,
       ZoneTypeId = 11,
       texture = "landmark_citadel_rock"
    },
    [-484064781] = {
       zoneHash = -484064781,
       ZoneTypeId = 11,
       texture = "landmark_cumberland_falls"
    },
    [-209915926] = {
       zoneHash = -209915926,
       ZoneTypeId = 11,
       texture = "landmark_dewberry_creek"
    },
    [-545967610] = {
       zoneHash = -545967610,
       ZoneTypeId = 12,
       texture = "landmark_ewing_basin"
    },
    [-1821194396] = {
       zoneHash = -1821194396,
       ZoneTypeId = 12,
       texture = "landmark_face_rock"
    },
    [-847222477] = {
       zoneHash = -847222477,
       ZoneTypeId = 11,
       texture = "settlement_flatneck_station"
    },
    [-1753216046] = {
       zoneHash = -1753216046,
       ZoneTypeId = 12,
       texture = "landmark_fort_brennand"
    },
    [-870780939] = {
       zoneHash = -870780939,
       ZoneTypeId = 12,
       texture = "landmark_grangers_hoggery"
    },
    [-1114958242] = {
       zoneHash = -1114958242,
       ZoneTypeId = 11,
       texture = "landmark_granite_pass"
    },
    [-1203685470] = {
       zoneHash = -1203685470,
       ZoneTypeId = 11,
       texture = "water_manteca_falls"
    },
    [-156397252] = {
       zoneHash = -156397252,
       ZoneTypeId = 11,
       texture = "landmark_mercer_station"
    },
    [-1225359404] = {
       zoneHash = -1225359404,
       ZoneTypeId = 11,
       texture = "landmark_montos_rest"
    },
    [-631265576] = {
       zoneHash = -631265576,
       ZoneTypeId = 12,
       texture = "landmark_oddfellows_rest"
    },
    [-291091669] = {
       zoneHash = -291091669,
       ZoneTypeId = 12,
       texture = "landmark_old_greenbank_mill"
    },
    [-1420336129] = {
       zoneHash = -1420336129,
       ZoneTypeId = 11,
       texture = "water_owanjila"
    },
    [-2035208924] = {
       zoneHash = -2035208924,
       ZoneTypeId = 12,
       texture = "settlement_pleasance"
    },
    [-259784188] = {
       zoneHash = -259784188,
       ZoneTypeId = 12,
       texture = "landmark_radleys_pasture"
    },
    [-1247294802] = {
       zoneHash = -1247294802,
       ZoneTypeId = 12,
       texture = "landmark_rio_del_lobo_house"
    },
    [-868607615] = {
       zoneHash = -868607615,
       ZoneTypeId = 12,
       texture = "landmark_silent_stead"
    },
    [-1419869345] = {
       zoneHash = -1419869345,
       ZoneTypeId = 12,
       texture = "landmark_tanners_reach"
    },
    [-2038495927] = {
       zoneHash = -2038495927,
       ZoneTypeId = 11,
       texture = "landmark_tempest_rim"
    },
    [-438809735] = {
       zoneHash = -438809735,
       ZoneTypeId = 12,
       texture = "landmark_the_loft"
    },
    [-1173672830] = {
       zoneHash = -1173672830,
       ZoneTypeId = 12,
       texture = "landmark_the_old_bacchus_place"
    },
    [-1926488450] = {
       zoneHash = -1926488450,
       ZoneTypeId = 11,
       texture = "landmark_three_sisters"
    },
    [-2133063188] = {
       zoneHash = -2133063188,
       ZoneTypeId = 12,
       texture = "landmark_two_crows"
    },
    [-1207133769] = {
       zoneHash = -1207133769,
       ZoneTypeId = 1,
       texture = "settlement_aguasdulces"
    },
    [-1288973891] = {
       zoneHash = -1288973891,
       ZoneTypeId = 11,
       texture = "settlement_aguasdulces"
    },
    [-419963911] = {
       zoneHash = -419963911,
       ZoneTypeId = 12,
       texture = "settlement_appleseed_timber_co"
    },
    [-745404624] = {
       zoneHash = -745404624,
       ZoneTypeId = 11,
       texture = "settlement_benedict_point"
    },
    [-166839571] = {
       zoneHash = -166839571,
       ZoneTypeId = 11,
       texture = "settlement_braithwaite_manor"
    },
    [-425430549] = {
       zoneHash = -425430549,
       ZoneTypeId = 12,
       texture = "settlement_butcher_creek"
    },
    [-619014970] = {
       zoneHash = -619014970,
       ZoneTypeId = 12,
       texture = "settlement_castors_ridge"
    },
    [-61172588] = {
       zoneHash = -61172588,
       ZoneTypeId = 12,
       texture = "settlement_coots_chapel"
    },
    [-828659305] = {
       zoneHash = -828659305,
       ZoneTypeId = 12,
       texture = "settlement_fort_riggs_holding_camp"
    },
    [-99881305] = {
       zoneHash = -99881305,
       ZoneTypeId = 11,
       texture = "settlement_fort_wallace"
    },
    [-1999797981] = {
       zoneHash = -1999797981,
       ZoneTypeId = 12,
       texture = "settlement_grand_korrigan"
    },
    [-832065774] = {
       zoneHash = -832065774,
       ZoneTypeId = 12,
       texture = "settlement_limpany"
    },
    [-120578354] = {
       zoneHash = -120578354,
       ZoneTypeId = 12,
       texture = "settlement_pronghorn_ranch"
    },
    [-864457539] = {
       zoneHash = -864457539,
       ZoneTypeId = 11,
       texture = "settlement_rathskeller_fork"
    },
    [-735849380] = {
       zoneHash = -735849380,
       ZoneTypeId = 11,
       texture = "settlement_wapiti"
    },
    [-221059932] = {
       zoneHash = -221059932,
       ZoneTypeId = 0,
       texture = "state_ambarino"
    },
    [-2001518509] = {
       zoneHash = -2001518509,
       ZoneTypeId = 11,
       texture = "town_annesburg"
    },
    [-420810761] = {
       zoneHash = -420810761,
       ZoneTypeId = 11,
       texture = "town_armadillo"
    },
    [-744494798] = {
       zoneHash = -744494798,
       ZoneTypeId = 1,
       texture = "town_armadillo"
    },
    [-931296374] = {
       zoneHash = -931296374,
       ZoneTypeId = 11,
       texture = "town_blackwater"
    },
    [-1532919875] = {
       zoneHash = -1532919875,
       ZoneTypeId = 11,
       texture = "town_macfarlanes_ranch"
    },
    [-346622837] = {
       zoneHash = -346622837,
       ZoneTypeId = 11,
       texture = "town_strawberry"
    },
    [-1524959147] = {
       zoneHash = -1524959147,
       ZoneTypeId = 1,
       texture = "town_tumbleweed"
    },
    [-2049654576] = {
       zoneHash = -2049654576,
       ZoneTypeId = 11,
       texture = "town_tumbleweed"
    },
    [-1777630136] = {
       zoneHash = -1777630136,
       ZoneTypeId = 11,
       texture = "town_valentine"
    },
    [-49694339] = {
       zoneHash = -49694339,
       ZoneTypeId = 3,
       texture = "water_arroyo_de_la_vibora"
    },
    [-849548894] = {
       zoneHash = -849548894,
       ZoneTypeId = 11,
       texture = "water_arroyo_de_la_vibora"
    },
    [-196675805] = {
       zoneHash = -196675805,
       ZoneTypeId = 2,
       texture = "water_aurora_basin"
    },
    [-1168459546] = {
       zoneHash = -1168459546,
       ZoneTypeId = 6,
       texture = "water_bahia_de_la_paz"
    },
    [-1657629123] = {
       zoneHash = -1657629123,
       ZoneTypeId = 11,
       texture = "water_bahia_de_la_paz"
    },
    [-1073312073] = {
       zoneHash = -1073312073,
       ZoneTypeId = 8,
       texture = "water_cairn_lake"
    },
    [-1860484356] = {
       zoneHash = -1860484356,
       ZoneTypeId = 11,
       texture = "water_cattail_pond"
    },
    [-962704492] = {
       zoneHash = -962704492,
       ZoneTypeId = 11,
       texture = "water_cotorra_springs"
    },
    [-138648964] = {
       zoneHash = -138648964,
       ZoneTypeId = 11,
       texture = "water_dakota_river"
    },
    [-105598602] = {
       zoneHash = -105598602,
       ZoneTypeId = 2,
       texture = "water_elysian_pool"
    },
    [-1356490953] = {
       zoneHash = -1356490953,
       ZoneTypeId = 2,
       texture = "water_flat_iron_lake"
    },
    [-1276586360] = {
       zoneHash = -1276586360,
       ZoneTypeId = 7,
       texture = "water_hawks_eye_creek"
    },
    [-716869579] = {
       zoneHash = -716869579,
       ZoneTypeId = 11,
       texture = "water_hawks_eye_creek"
    },
    [-1229593481] = {
       zoneHash = -1229593481,
       ZoneTypeId = 3,
       texture = "water_kamassa_river"
    },
    [-1369817450] = {
       zoneHash = -1369817450,
       ZoneTypeId = 2,
       texture = "water_lake_don_julio"
    },
    [-1692509313] = {
       zoneHash = -1692509313,
       ZoneTypeId = 12,
       texture = "water_lake_don_julio"
    },
    [-2040708515] = {
       zoneHash = -2040708515,
       ZoneTypeId = 3,
       texture = "water_lannahechee_river"
    },
    [-1410384421] = {
       zoneHash = -1410384421,
       ZoneTypeId = 3,
       texture = "water_little_creek_river"
    },
    [-1004072985] = {
       zoneHash = -1004072985,
       ZoneTypeId = 11,
       texture = "water_lower_montana_river"
    },
    [-1308233316] = {
       zoneHash = -1308233316,
       ZoneTypeId = 3,
       texture = "water_lower_montana_river"
    },
    [-811730579] = {
       zoneHash = -811730579,
       ZoneTypeId = 8,
       texture = "water_moonstone_pond"
    },
    [-1300497193] = {
       zoneHash = -1300497193,
       ZoneTypeId = 2,
       texture = "water_owanjila"
    },
    [-247856387] = {
       zoneHash = -247856387,
       ZoneTypeId = 2,
       texture = "water_sea_of_coronado"
    },
    [-493344856] = {
       zoneHash = -493344856,
       ZoneTypeId = 11,
       texture = "water_sea_of_coronado"
    },
    [-410208673] = {
       zoneHash = -410208673,
       ZoneTypeId = 11,
       texture = "water_southfield_flats"
    },
    [-823661292] = {
       zoneHash = -823661292,
       ZoneTypeId = 8,
       texture = "water_southfield_flats"
    },
    [-218679770] = {
       zoneHash = -218679770,
       ZoneTypeId = 7,
       texture = "water_spider_gorge"
    },
    [-1118608187] = {
       zoneHash = -1118608187,
       ZoneTypeId = 11,
       texture = "water_stillwater_creek"
    },
    [-1287619521] = {
       zoneHash = -1287619521,
       ZoneTypeId = 7,
       texture = "water_stillwater_creek"
    },
    [-1781130443] = {
       zoneHash = -1781130443,
       ZoneTypeId = 3,
       texture = "water_upper_montana_river"
    },
    [-1774142845] = {
       zoneHash = -1774142845,
       ZoneTypeId = 11,
       texture = "water_whinyard_strait"
    },
    [-261541730] = {
       zoneHash = -261541730,
       ZoneTypeId = 7,
       texture = "water_whinyard_strait"
    },
    [-108848014] = {
       zoneHash = -108848014,
       ZoneTypeId = 10,
       texture = "district_cholla_springs"
    },
    [-2066240242] = {
       zoneHash = -2066240242,
       ZoneTypeId = 10,
       texture = "district_gaptooth_ridge"
    },
    [-2145992129] = {
       zoneHash = -2145992129,
       ZoneTypeId = 10,
       texture = "district_rio_bravo"
    },
    [-864275692] = {
       zoneHash = -864275692,
       ZoneTypeId = 10,
       texture = "district_scarlett_meadows"
    },
    [-1289136221] = {
       zoneHash = -1289136221,
       ZoneTypeId = 0,
       texture = "state_new_hanover"
    },
    [-1247148211] = {
       zoneHash = -1247148211,
       ZoneTypeId = 0,
       texture = "state_west_elizabeth"
    },
    [-1973391500] = {
       zoneHash = -1973391500,
       ZoneTypeId = 0,
       texture = "state_west_elizabeth"
    }
}