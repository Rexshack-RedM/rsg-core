local Translations = {
    error = {
        not_online = 'Player not online',
        wrong_format = 'Incorrect format',
        missing_args = 'Not every argument has been entered (x, y, z)',
        missing_args2 = 'All arguments must be filled out!',
        no_access = 'No access to this command',
        company_too_poor = 'Your employer is broke',
        item_not_exist = 'Item does not exist',
        too_heavy = 'Inventory too full',
        location_not_exist = 'Location does not exist',
        duplicate_license = 'Duplicate Rockstar License Found',
        no_valid_license  = 'No Valid Rockstar License Found',
        not_whitelisted = 'You\'re not whitelisted for this server',
        server_already_open = 'The server is already open',
        server_already_closed = 'The server is already closed',
        no_permission = 'You don\'t have permissions for this..',
        no_waypoint = 'No Waypoint Set.',
        tp_error = 'Error While Teleporting.',
    },
    success = {
        server_opened = 'The server has been opened',
        server_closed = 'The server has been closed',
        teleported_waypoint = 'Teleported To Waypoint.',
    },
    info = {
        received_paycheck = 'You received your paycheck of $%{value}',
        job_info = 'Job: %{value} | Grade: %{value2} | Duty: %{value3}',
        gang_info = 'Gang: %{value} | Grade: %{value2}',
        on_duty = 'You are now on duty!',
        off_duty = 'You are now off duty!',
        checking_ban = 'Hello %s. We are checking if you are banned.',
        join_server = 'Welcome %s to {Server Name}.',
        checking_whitelisted = 'Hello %s. We are checking your allowance.',
        exploit_banned = 'You have been banned for cheating. Check our Discord for more information: %{discord}',
        exploit_dropped = 'You Have Been Kicked For Exploitation',
    },
    command = {
        tp = {
            help = 'TP To Player or Coords (Admin Only)',
            params = {
                x = { name = 'id/x', help = 'ID of player or X position'},
                y = { name = 'y', help = 'Y position'},
                z = { name = 'z', help = 'Z position'},
            },
        },
        tpm = { help = 'TP To Marker (Admin Only)' },
        addpermission = {
            help = 'Give Player Permissions (God Only)',
            params = {
                id = { name = 'id', help = 'ID of player' },
                permission = { name = 'permission', help = 'Permission level' },
            },
        },
        removepermission = {
            help = 'Remove Player Permissions (God Only)',
            params = {
                id = { name = 'id', help = 'ID of player' },
                permission = { name = 'permission', help = 'Permission level' },
            },
        },
        openserver = { help = 'Open the server for everyone (Admin Only)' },
        closeserver = {
            help = 'Close the server for people without permissions (Admin Only)',
            params = {
                reason = { name = 'reason', help = 'Reason for closing (optional)' },
            },
        },
        car = {
            help = 'Spawn Vehicle (Admin Only)',
            params = {
                model = { name = 'model', help = 'Model name of the vehicle' },
            },
        },
        dv = { help = 'Delete Vehicle (Admin Only)' },
        spawnwagon = { help = 'Spawn a Wagon (Admin Only)' },
        spawnhorse = { help = 'Spawn a Horse (Admin Only)' },
        givemoney = {
            help = 'Give A Player Money (Admin Only)',
            params = {
                id = { name = 'id', help = 'Player ID' },
                moneytype = { name = 'moneytype', help = 'Type of money (cash, bank, bloodmoney)' },
                amount = { name = 'amount', help = 'Amount of money' },
            },
        },
        setmoney = {
            help = 'Set Players Money Amount (Admin Only)',
            params = {
                id = { name = 'id', help = 'Player ID' },
                moneytype = { name = 'moneytype', help = 'Type of money (cash, bank, bloodmoney)' },
                amount = { name = 'amount', help = 'Amount of money' },
            },
        },
        job = { help = 'Check Your Job' },
        setjob = {
            help = 'Set A Players Job (Admin Only)',
            params = {
                id = { name = 'id', help = 'Player ID' },
                job = { name = 'job', help = 'Job name' },
                grade = { name = 'grade', help = 'Job grade' },
            },
        },
        gang = { help = 'Check Your Gang' },
        setgang = {
            help = 'Set A Players Gang (Admin Only)',
            params = {
                id = { name = 'id', help = 'Player ID' },
                gang = { name = 'gang', help = 'Gang name' },
                grade = { name = 'grade', help = 'Gang grade' },
            },
        },
        ooc = { help = 'OOC Chat Message' },
        me = {
            help = 'Show local message',
            params = {
                message = { name = 'message', help = 'Message to send' }
            },
        },
    },

                                            --------------------------------------------------------------------
                                            --------------If you want to have the items translated--------------
                                            --------------------------------------------------------------------
    items = {

        label = {       water = 'Water', bread = 'Bread Roll', horsebrush = 'Horse Brush', boatticket = 'Boat Ticket', canoe = 'Canoe', moonshine = 'Moonshine',
                        beer = 'Beer', whiskey = 'Whiskey', coffee = 'Coffee', bandage = 'Bandage', firstaid = 'First Aid', sugarcube = 'Sugar Cube', 
                        horselantern = 'Horse Lantern', horseholster = 'Horse Holster', stew = 'Hot Stew', treasure1 = 'Treasure Map'},
        
        description = { water = 'Drinking Water', bread = 'Bread Roll', horsebrush = 'Brush used to clean your horse', boatticket = 'Used for boat travel', canoe = 'Deployable canoe', moonshine = 'Best moonshine in town',
                        beer = 'Bottle of beer', whiskey = 'Bottle of whiskey', coffee = 'Cup of coffee', bandage = 'Used to improve your health', firstaid = 'Used by medics to improve your health', sugarcube = 'Your horse may like these', 
                        horselantern = 'Horses need headlights!', horseholster = 'Horse Holster', stew = 'Hot homemade stew', treasure1 = 'Map for finding treasure'}
        
    },

    horseT = {

        label = {       horsetrainingbrush = 'Horse training brush', horsetrainingcarrot = 'Brush used by a horse trainer'},

        description = { horsetrainingbrush = 'Horse training carrot', horsetrainingcarrot = 'Carrot used by a horse trainer'}
    
    },

    farming = {

        label = {       cornseed = 'Corn Seed', corn = 'Corn', sugarseed = 'Sugar Seed', sugar = 'Sugar', tobaccoseed = 'Tobacco Seed', tobacco = 'Tobacco',
                        carrotseed = 'Carrot Seed', carrot = 'Carrot', tomatoseed = 'Tomato Seed', tomato = 'Tomato', broccoliseed = 'Broccoli Seed', broccoli = 'Broccoli',
                        potatoseed = 'Potato Seed', potato = 'Potato', wateringcan = 'Watering Can', bucket = 'Farm Bucket'},

        description = { cornseed = 'Used in farming', corn = 'Product from farming', sugarseed = 'Used in farming', sugar = 'Product from farming', tobaccoseed = 'Used in farming', tobacco = 'Product from farming',
                        carrotseed = 'Used in farming', carrot = 'Product from farming', tomatoseed = 'Used in farming', tomato = 'Product from farming', broccoliseed = 'Used in farming', broccoli = 'Product from farming',
                        potatoseed = 'Used in farming', potato = 'Product from farming', wateringcan = 'Equipment for watering stuff', bucket = 'Farm equipment'}
                    
    },

    cooking = {

        label = {       raw_meat = 'Raw Meat', cooked_meat = 'Cooked Meat', raw_fish  = 'Fish Meat', cooked_fish = 'Cooked Fish', campfire = 'Camp Fire'},

        description = { raw_meat = 'Ready for cooking', cooked_meat = 'Ready for cooking', raw_fish  = 'Ready for cooking', cooked_fish = 'Ready for cooking', campfire = 'Used for cooking'}

    },

    goldP = {

        label = {       goldpan = 'Gold Pan', smallnugget = 'Small Nugget', mediumnugget = 'Medium Nugget', largenugget = 'Large Nugget', goldsmelt  = 'Gold Smelt'},

        description = { goldpan = 'Equipment for gold panning', smallnugget = 'Small gold nugget', mediumnugget = 'Medium gold nugget', largenugget = 'Large gold nugget', goldsmelt  = 'Equipment for gold smelting'}

    },

    tobaccoF = {

        label = {       drytobacco = 'Dry Tobacco', cigar  = 'Cigar', cigarbox = 'Cigar Box'},

        description = { drytobacco = 'Factory product', cigar  = 'Factory product', cigarbox = 'Factory product'}

    },

    a_c_bear_01 = {

        label = {       perfect_bear_pelt = 'Bear Pelt', good_bear_pelt = 'Bear Pelt', poor_bear_pelt = 'Bear Pelt'},

        description = { perfect_bear_pelt = 'Perfect (* * *)', good_bear_pelt = 'Good (* *)', poor_bear_pelt = 'Poor (*)'}

    },

    a_c_bearblack_01 = {
    
        label = {       perfect_black_bear_pelt = 'Black Bear Pelt', good_black_bear_pelt = 'Black Bear Pelt', poor_black_bear_pelt = 'Black Bear Pelt'},
        
        description = { perfect_black_bear_pelt = 'Perfect (* * *)', good_black_bear_pelt = 'Good (* *)', poor_black_bear_pelt = 'Poor (*)'}
        
    },

    a_c_boar_01 = {

        label = {       perfect_boar_pelt = 'Boar Pelt', good_boar_pelt = 'Boar Pelt', poor_boar_pelt = 'Boar Pelt'},
    
        description = { perfect_boar_pelt = 'Perfect (* * *)', good_boar_pelt = 'Good (* *)', poor_boar_pelt = 'Poor (*)'}
    
    },

    a_c_buck_01 = {

        label = {       perfect_buck_pelt = 'Buck Pelt', good_buck_pelt = 'Buck Pelt', poor_buck_pelt = 'Buck Pelt'},
    
        description = { perfect_buck_pelt = 'Perfect (* * *)', good_buck_pelt = 'Good (* *)', poor_buck_pelt = 'Poor (*)'}
    
    },

    a_c_buffalo_01 = {

        label = {       perfect_buffalo_pelt = 'Buffalo Pelt', good_buffalo_pelt = 'Buffalo Pelt', poor_buffalo_pelt = 'Buffalo Pelt'},
    
        description = { perfect_buffalo_pelt = 'Perfect (* * *)', good_buffalo_pelt = 'Good (* *)', poor_buffalo_pelt = 'Poor (*)'}
    
    },

    a_c_bull_01 = {

        label = {       perfect_bull_pelt = 'Bull Pelt', good_bull_pelt = 'Bull Pelt', poor_bull_pelt = 'Bull Pelt'},

        description = { perfect_bull_pelt = 'Perfect (* * *)', good_bull_pelt = 'Good (* *)', poor_bull_pelt = 'Poor (*)'}

    },

    a_c_cougar_01 = {

        label = {       perfect_cougar_pelt = 'Cougar Pelt', good_cougar_pelt = 'Cougar Pelt', poor_cougar_pelt = 'Cougar Pelt'},

        description = { perfect_cougar_pelt = 'Perfect (* * *)', good_cougar_pelt = 'Good (* *)', poor_cougar_pelt = 'Poor (*)'}

    },

    a_c_cow = {

        label = {       perfect_cow_pelt = 'Cow Pelt', good_cow_pelt = 'Cow Pelt', poor_cow_pelt = 'Cow Pelt'},

        description = { perfect_cow_pelt = 'Perfect (* * *)', good_cow_pelt = 'Good (* *)', poor_cow_pelt = 'Poor (*)'}

    },

    a_c_coyote_01 = {

        label = {       perfect_coyote_pelt = 'Coyote Pelt', good_coyote_pelt = 'Coyote Pelt', poor_coyote_pelt = 'Coyote Pelt'},

        description = { perfect_coyote_pelt = 'Perfect (* * *)', good_coyote_pelt = 'Good (* *)', poor_coyote_pelt = 'Poor (*)'}

    },
    
    a_c_deer_01 = {

        label = {       perfect_deer_pelt = 'Deer Pelt', good_deer_pelt = 'Deer Pelt', poor_deer_pelt = 'Deer Pelt'},

        description = { perfect_deer_pelt = 'Perfect (* * *)', good_deer_pelt = 'Good (* *)', poor_deer_pelt = 'Poor (*)'}

    },

    a_c_elk_01 = {

        label = {       perfect_elk_pelt = 'Elk Pelt', good_elk_pelt = 'Elk Pelt', poor_elk_pelt = 'Elk Pelt'},

        description = { perfect_elk_pelt = 'Perfect (* * *)', good_elk_pelt = 'Good (* *)', poor_elk_pelt = 'Poor (*)'}

    },

    a_c_fox_01 = {

        label = {       perfect_fox_pelt = 'Redfox Pelt', good_fox_pelt = 'Redfox Pelt', poor_fox_pelt = 'Redfox Pelt'},

        description = { perfect_fox_pelt = 'Perfect (* * *)', good_fox_pelt = 'Good (* *)', poor_fox_pelt = 'Poor (*)'}

    },

    a_c_goat_01 = {

        label = {       perfect_goat_pelt = 'Goat Pelt', good_goat_pelt = 'Goat Pelt', poor_goat_pelt = 'Goat Pelt'},

        description = { perfect_goat_pelt = 'Perfect (* * *)', good_goat_pelt = 'Good (* *)', poor_goat_pelt = 'Poor (*)'}

    },

    a_c_javelina_01 = {

        label = {       perfect_javelina_pelt = 'Javelina Pelt', good_javelina_pelt = 'Javelina Pelt', poor_javelina_pelt = 'Javelina Pelt'},

        description = { perfect_javelina_pelt = 'Perfect (* * *)', good_javelina_pelt = 'Good (* *)', poor_javelina_pelt = 'Poor (*)'}

    },
        
    a_c_moose_01 = {

        label = {       perfect_moose_pelt = 'Moose Pelt', good_moose_pelt = 'Moose Pelt', poor_moose_pelt = 'Moose Pelt'},

        description = { perfect_moose_pelt = 'Perfect (* * *)', good_moose_pelt = 'Good (* *)', poor_moose_pelt = 'Poor (*)'}

    },
        
    a_c_ox_01 = {

        label = {       perfect_ox_pelt = 'Ox Pelt', good_ox_pelt = 'Ox Pelt', poor_ox_pelt = 'Ox Pelt'},

        description = { perfect_ox_pelt = 'Perfect (* * *)', good_ox_pelt = 'Good (* *)', poor_ox_pelt = 'Poor (*)'}

    },
        
    a_c_panther_01 = {

        label = {       perfect_panther_pelt = 'Panther Pelt', good_panther_pelt = 'Panther Pelt', poor_panther_pelt = 'Panther Pelt'},

        description = { perfect_panther_pelt = 'Perfect (* * *)', good_panther_pelt = 'Good (* *)', poor_panther_pelt = 'Poor (*)'}

    },

    a_c_pig_01 = {

        label = {       perfect_pig_pelt = 'Pig Pelt', good_pig_pelt = 'Pig Pelt', poor_pig_pelt = 'Pig Pelt'},

        description = { perfect_pig_pelt = 'Perfect (* * *)', good_pig_pelt = 'Good (* *)', poor_pig_pelt = 'Poor (*)'}

    },
            
    a_c_pronghorn_01 = {

        label = {       perfect_pronghorn_pelt = 'Pronghorn Pelt', good_pronghorn_pelt = 'Pronghorn Pelt', poor_pronghorn_pelt = 'Pronghorn Pelt'},

        description = { perfect_pronghorn_pelt = 'Perfect (* * *)', good_pronghorn_pelt = 'Good (* *)', poor_pronghorn_pelt = 'Poor (*)'}

    },
  
    a_c_bighornram_01 = {

        label = {       perfect_bighornram_pelt = 'Bighornram Pelt', good_bighornram_pelt = 'Bighornram Pelt', poor_bighornram_pelt = 'Bighornram Pelt'},

        description = { perfect_bighornram_pelt = 'Perfect (* * *)', good_bighornram_pelt = 'Good (* *)', poor_bighornram_pelt = 'Poor (*)'}

    },

    a_c_sheep_01 = {

        label = {       perfect_sheep_pelt = 'Sheep Pelt', good_sheep_pelt = 'Sheep Pelt', poor_sheep_pelt = 'Sheep Pelt'},

        description = { perfect_sheep_pelt = 'Perfect (* * *)', good_sheep_pelt = 'Good (* *)', poor_sheep_pelt = 'Poor (*)'}

    },
    
    a_c_wolf = {

        label = {       perfect_wolf_pelt = 'Wolf Pelt', good_wolf_pelt = 'Wolf Pelt', poor_wolf_pelt = 'Wolf Pelt'},

        description = { perfect_wolf_pelt = 'Perfect (* * *)', good_wolf_pelt = 'Good (* *)', poor_wolf_pelt = 'Poor (*)'}

    },
    
    a_c_alligator_03 = {

        label = {       perfect_alligator_pelt = 'Alligator Pelt', good_alligator_pelt = 'Alligator Pelt', poor_alligator_pelt = 'Alligator Pelt'},

        description = { perfect_alligator_pelt = 'Perfect (* * *)', good_alligator_pelt = 'Good (* *)', poor_alligator_pelt = 'Poor (*)'}

    },

    mp_a_c_alligator_01 = {

        label = {       legendary_alligator_pelt = 'Leg Alligator Pelt'},

        description = { legendary_alligator_pelt = 'Perfect (* * *)'}
    },

    mp_a_c_beaver_01 = {

        label = {       legendary_beaver_pelt = 'Leg Beaver Pelt'},

        description = { legendary_beaver_pelt = 'Perfect (* * *)'}
    },

    mp_a_c_boar_01 = {

        label = {       legendary_boar_pelt = 'Leg Boar Pelt'},

        description = { legendary_boar_pelt = 'Perfect (* * *)'}
    },

    mp_a_c_cougar_01 = {

        label = {       legendary_cougar_pelt = 'Leg Cougar Pelt'},

        description = { legendary_cougar_pelt = 'Perfect (* * *)'}
    },

    mp_a_c_coyote_01 = {

        label = {       legendary_coyote_pelt = 'Leg Coyote Pelt'},

        description = { legendary_coyote_pelt = 'Perfect (* * *)'}
    },

    mp_a_c_panther_01 = {

        label = {       legendary_panther_pelt = 'Leg Panther Pelt'},

        description = { legendary_panther_pelt = 'Perfect (* * *)'}
    },

    mp_a_c_wolf_01 = {

        label = {       legendary_wolf_pelt = 'Leg Wolf Pelt'},

        description = { legendary_wolf_pelt = 'Perfect (* * *)'}
    },

    fish = {

        label = {       a_c_fishbluegil_01_ms = 'Blue Gil (M)', a_c_fishbluegil_01_sm = 'Blue Gil (S)', a_c_fishbullheadcat_01_ms = 'Bullhead Cat (M)', a_c_fishbullheadcat_01_sm = 'Bullhead Cat (S)', a_c_fishchainpickerel_01_ms = 'Chain Pickerel (M)', a_c_fishchainpickerel_01_sm = 'Chain Pickerel (S)',
                        a_c_fishchannelcatfish_01_lg = 'Channel Catfish (L)', a_c_fishchannelcatfish_01_xl = 'Channel Catfish (EL)', a_c_fishlakesturgeon_01_lg = 'Lake Sturgeon (L)', a_c_fishlargemouthbass_01_lg = 'Large Mouth Bass (L)', a_c_fishlargemouthbass_01_ms = 'Large Mouth Bass (M)', a_c_fishlongnosegar_01_lg = 'Long Nose Gar (L)',
                        a_c_fishmuskie_01_lg = 'Muskie (L)', a_c_fishnorthernpike_01_lg = 'Northern Pike (L)', a_c_fishperch_01_ms = 'Perch (M)', a_c_fishperch_01_sm = 'Perch (S)', a_c_fishrainbowtrout_01_lg = 'Rainbow Trout (L)', a_c_fishrainbowtrout_01_ms = 'Rainbow Trout (M)', 
                        a_c_fishredfinpickerel_01_ms = 'Red Fin Pickerel (M)', a_c_fishredfinpickerel_01_sm = 'Red Fin Pickerel (S)', a_c_fishrockbass_01_ms = 'Rock Bass (M)', a_c_fishrockbass_01_sm = 'Rock Bass (S)', a_c_fishsalmonsockeye_01_lg = 'Salmon Sockeye (L)', a_c_fishsalmonsockeye_01_ml = 'Salmon Sockeye (ML)',
                        a_c_fishsalmonsockeye_01_ms = 'Salmon Sockeye (M)', a_c_fishsmallmouthbass_01_lg = 'Small Mouth Bass (L)', a_c_fishsmallmouthbass_01_ms = 'Small Mouth Bass (M)'},

        description = { a_c_fishbluegil_01_ms = 'Used for fishing', a_c_fishbluegil_01_sm = 'Used for fishing', a_c_fishbullheadcat_01_ms = 'Used for fishing', a_c_fishbullheadcat_01_sm = 'Used for fishing', a_c_fishchainpickerel_01_ms = 'Used for fishing', a_c_fishchainpickerel_01_sm = 'Used for fishing',
                        a_c_fishchannelcatfish_01_lg = 'Used for fishing', a_c_fishchannelcatfish_01_xl = 'Used for fishing', a_c_fishlakesturgeon_01_lg = 'Used for fishing', a_c_fishlargemouthbass_01_lg = 'Used for fishing', a_c_fishlargemouthbass_01_ms = 'Used for fishing', a_c_fishlongnosegar_01_lg = 'Used for fishing',
                        a_c_fishmuskie_01_lg = 'Used for fishing', a_c_fishnorthernpike_01_lg = 'Used for fishing', a_c_fishperch_01_ms = 'Used for fishing', a_c_fishperch_01_sm = 'Farm equipment', a_c_fishrainbowtrout_01_lg = 'Used for fishing', a_c_fishrainbowtrout_01_ms = 'Used for fishing',
                        a_c_fishredfinpickerel_01_ms = 'Used for fishing', a_c_fishredfinpickerel_01_sm = 'Used for fishing', a_c_fishrockbass_01_ms = 'Used for fishing', a_c_fishrockbass_01_sm = 'Used for fishing', a_c_fishsalmonsockeye_01_lg = 'Used for fishing', a_c_fishsalmonsockeye_01_ml = 'Used for fishing',
                        a_c_fishsalmonsockeye_01_ms = 'Used for fishing', a_c_fishsmallmouthbass_01_lg = 'Used for fishing', a_c_fishsmallmouthbass_01_ms = 'Used for fishing'}
                    
    },

    fishB = {

        label = {       p_baitbread01x = 'Bread Bait', p_baitcorn01x = 'Corn Bait', p_baitcheese01x  = 'Cheese Bait', p_baitworm01x = 'Worm Bait', p_baitcricket01x = 'Cricket Bait', p_crawdad01x = 'Crawfish Bait'},

        description = { p_baitbread01x = 'Used for fishing', p_baitcorn01x = 'Used for fishing', p_baitcheese01x  = 'Used for fishing', p_baitworm01x = 'Used for fishing', p_baitcricket01x = 'Used for fishing', p_crawdad01x = 'Used for fishing'}

    },

    fishL = {

        label = {       p_finishedragonfly01x = 'Dragonfly Lure', p_finisdfishlure01x = 'Fish Lure', p_finishdcrawd01x  = 'Crawfish Lure', p_finishedragonflylegendary01x = 'Legendary Dragonfly Lure', p_finisdfishlurelegendary01x = 'Legendary Fish Lure', p_finishdcrawdlegendary01x = 'Legendary Crawfish Lure',
                        p_lgoc_spinner_v4 = 'Spinner', p_lgoc_spinner_v6 = 'Improved Spinner'},

        description = { p_finishedragonfly01x = 'Used for fishing', p_finisdfishlure01x = 'Used for fishing', p_finishdcrawd01x  = 'Used for fishing', p_finishedragonflylegendary01x = 'Used for fishing', p_finisdfishlurelegendary01x = 'Used for fishing', p_finishdcrawdlegendary01x = 'Used for fishing',
                        p_lgoc_spinner_v4 = 'Used for fishing', p_lgoc_spinner_v6 = 'Used for fishing'}

    },

    petshop = {

        label = {       foxhound = 'Fox Hound', sheperd = 'Shepherd', coonhound = 'Coon Hound', catahoulacur = 'Catahoula Cur', bayretriever = 'Retriever', collie = 'Collie',
                        hound = 'Hound', husky = 'Husky', lab = 'Lab', poodle = 'Poodle', street = 'Street'},

        description = { foxhound = 'American Foxhound', sheperd = 'Australian Sheperd', coonhound = 'Bluetick Coonhound', catahoulacur = 'Catahoula Cur', bayretriever = 'Ches Bay Retriever', collie = 'Collie',
                        hound = 'Hound', husky = 'Husky', lab = 'Lab', poodle = 'Poodle', street = 'Street'}

    },

    indianT = {

        label = {       indtobaccoseed = 'Indian Seed', indtobacco = 'Indian Tobacco', fertilizer = 'Fertilizer', indiancigar = 'Indian Cigar'},

        description = { indtobaccoseed = 'Indian tobacco seed', indtobacco = 'Indian tobacco', fertilizer = 'Feed for growing plants', indiancigar = 'Indian cigar'}

    },

    supportMoon = {

        label = {       moonshinekit = 'Moonshine Kit'},

        description = { moonshinekit = 'Used to construct a moonshine'}

    },

    supportBH = {

        label = {       dynamite = 'Dynamite', goldbar = 'Gold Bar', goldwatch = 'Gold Watch', lockpick = 'Lockpick'},

        description = { dynamite = 'For blowing stuff up', goldbar = 'Solid gold bar', goldwatch = 'Solid gold watch', lockpick = 'For picking locks'}

    },

    bpos = {

        label = {       bposhovel = 'BPO Shovel', bpoaxe = 'BPO Axe', bpopickaxe = 'BPO PickAxe'},

        description = { bposhovel = 'Blueprint original', bpoaxe = 'Blueprint original', bpopickaxe = 'Blueprint original'}

    },

    bpcs = {

        label = {       bpcshovel = 'BPC Shovel', bpcaxe = 'BPC Axe', bpcpickaxe = 'BPC PickAxe'},

        description = { bpcshovel = 'BPC Shovel', bpcaxe = 'BPC Axe', bpcpickaxe = 'BPC PickAxe'}

    },

    itemTools = {

        label = {       shovel = 'Shovel', axe = 'Axe', pickaxe = 'Pickaxe'},

        description = { shovel = 'Equipment for digging', axe = 'Equipment for chopping', pickaxe = 'Equipment for mining'}

    },

    materials = {

        label = {       copper = 'Copper', aluminum = 'Aluminum', iron = 'Iron', steel = 'Steel',  wood = 'Wood'},

        description = { copper = 'Crafting material', aluminum = 'Crafting material', iron = 'Crafting material', steel = 'Crafting material',  wood = 'Crafting material'}

    },

    WeaponCP = {

        label = {       trigger = 'Trigger', hammer = 'Hammer', barrel = 'Barrel', spring = 'Spring', frame = 'Frame', grip = 'Grip', 
                        cylinder = 'Cylinder', stock = 'Stock', sight = 'Sight', bolt = 'Bolt', sling = 'Sling', action = 'Action'},

        description = { trigger = 'Weapon crafting part', hammer = 'Weapon crafting part', barrel = 'Weapon crafting part', spring = 'Weapon crafting part', frame = 'Weapon crafting part', grip = 'Weapon crafting part', 
                        cylinder = 'Weapon crafting part', stock = 'Weapon crafting part', sight = 'Weapon crafting part', bolt = 'Weapon crafting part', sling = 'Weapon crafting part', action = 'Weapon crafting part'},

    },

    WeaponSmith = {

        label = {       cleankit = 'Cleaning Kit'},

        description = { cleankit = 'For cleaning weapons'}

    },

    ammo = {

        label = {       ammo_revolver = 'Revolver (N)', ammo_rifle = 'Rifle (N)', ammo_pistol = 'Pistol (N)', ammo_shotgun = 'Shotgun (N)', ammo_arrow = 'Arrow (N)', ammo_repeater = 'Repeater (N)'},

        description = { ammo_revolver = 'Revolver Ammo', ammo_rifle = 'Rifle Ammo', ammo_pistol = 'Pistol Ammo', ammo_shotgun = 'Shotgun Ammo', ammo_arrow = 'Arrow', ammo_repeater = 'Repeater Ammo'}

    },

    revolver = {

        label = {       weapon_revolver_cattleman = 'Cattleman', weapon_revolver_cattleman_mexican = 'Cattleman Mexican', weapon_revolver_doubleaction_gambler = 'Gambler', weapon_revolver_schofield = 'Schofield', weapon_revolver_lemat = 'LeMat', weapon_revolver_navy = 'Navy',
                        weapon_revolver_navy_crossover = 'Navy Crossover'},

        description = { weapon_revolver_cattleman = 'Takes Revolver Ammo', weapon_revolver_cattleman_mexican = 'Takes Revolver Ammo', weapon_revolver_doubleaction_gambler = 'Takes Revolver Ammo', weapon_revolver_schofield = 'Takes Revolver Ammo', weapon_revolver_lemat = 'Takes Revolver Ammo', weapon_revolver_navy = 'Takes Revolver Ammo',
                        weapon_revolver_navy_crossover = 'Takes Revolver Ammo'}

    },

    pistol = {

        label = {       weapon_pistol_volcanic = 'Volcanic', weapon_pistol_m1899 = 'M1899', weapon_pistol_mauser = 'Mauser', weapon_pistol_semiauto = 'Semi-Auto'},

        description = { weapon_pistol_volcanic = 'Takes Pistol Ammo', weapon_pistol_m1899 = 'Takes Pistol Ammo', weapon_pistol_mauser = 'Takes Pistol Ammo', weapon_pistol_semiauto = 'Takes Pistol Ammo'}

    },

    repeater = {

        label = {       weapon_repeater_carbine = 'Carbine', weapon_repeater_winchester = 'Winchester', weapon_repeater_henry = 'Henry', weapon_repeater_evans = 'Evans'},

        description = { weapon_repeater_carbine = 'Takes Pistol Ammo', weapon_repeater_winchester = 'Takes Pistol Ammo', weapon_repeater_henry = 'Takes Pistol Ammo', weapon_repeater_evans = 'Takes Pistol Ammo'}

    },

    rifle = {

        label = {       weapon_rifle_varmint = 'Varmint', weapon_rifle_springfield = 'Springfield', weapon_rifle_boltaction = 'Boltaction', weapon_rifle_elephant = 'Elephant'},

        description = { weapon_rifle_varmint = 'Takes Pistol Ammo', weapon_rifle_springfield = 'Takes Pistol Ammo', weapon_rifle_boltaction = 'Takes Pistol Ammo', weapon_rifle_elephant = 'Takes Pistol Ammo'}

    },

    shotgun = {

        label = {       weapon_shotgun_doublebarrel = 'Shotgun', weapon_shotgun_doublebarrel_exotic = 'Exotic Shotgun', weapon_shotgun_sawedoff = 'Sawedoff Shotgun', weapon_shotgun_semiauto = 'SA Shotgun'},

        description = { weapon_shotgun_doublebarrel = 'Takes Pistol Ammo', weapon_shotgun_doublebarrel_exotic = 'Takes Pistol Ammo', weapon_shotgun_sawedoff = 'Takes Pistol Ammo', weapon_shotgun_semiauto = 'Takes Pistol Ammo'}

    },

    sniperrifle = {

        label = {       weapon_sniperrifle_rollingblock = 'Rollingblock', weapon_sniperrifle_rollingblock_exotic = 'Exotic Rrollingblock', weapon_sniperrifle_carcano = 'Carcano'},

        description = { weapon_sniperrifle_rollingblock = 'Takes Pistol Ammo', weapon_sniperrifle_rollingblock_exotic = 'Takes Pistol Ammo', weapon_sniperrifle_carcano = 'Takes Pistol Ammo'}

    },

    bow = {

        label = {       weapon_bow = 'Bow', weapon_bow_improved = 'Improved Bow'},

        description = { weapon_bow = 'Takes Pistol Ammo', weapon_bow_improved = 'Takes Pistol Ammo'}
    
    },

    lasso = {

        label = {       weapon_lasso = 'Lasso', weapon_lasso_reinforced = 'Improved Lasso'},

        description = { weapon_lasso = 'Placeholder', weapon_lasso_reinforced = 'Placeholder'}

    },

    melee = {

        label = {       weapon_melee_knife = 'Knife', weapon_melee_knife_jawbone = 'Jawbone Knife', weapon_melee_hammer = 'Hammer', weapon_melee_cleaver = 'Cleaver', weapon_melee_lantern = 'Lantern', weapon_melee_davy_lantern = 'Davy Lantern',
                        weapon_melee_lantern_halloween = 'Halloween Lantern', weapon_melee_torch = 'Wooden Torch', weapon_melee_hatchet = 'Hatchet', weapon_melee_machete = 'Machete'},

        description = { weapon_melee_knife = 'Placeholder', weapon_melee_knife_jawbone = 'Placeholder', weapon_melee_hammer = 'Placeholder', weapon_melee_cleaver = 'Placeholder', weapon_melee_lantern = 'Placeholder', weapon_melee_davy_lantern = 'Placeholder',
                        weapon_melee_lantern_halloween = 'Placeholder', weapon_melee_torch = 'Placeholder', weapon_melee_hatchet = 'Placeholder', weapon_melee_machete = 'Placeholder'}

    },

    thrown = {

        label = {       weapon_thrown_throwing_knives = 'Throwing Knives', weapon_thrown_tomahawk = 'Throwable Axe', weapon_thrown_tomahawk_ancient = 'Throwable Old Axe', weapon_thrown_bolas = 'Standard Bolas', weapon_thrown_bolas_hawkmoth = 'Hawkmoth Bolas', weapon_thrown_bolas_ironspiked = 'Ironspiked Bolas',
                        weapon_thrown_bolas_intertwined = 'Intertwined Bolas', weapon_thrown_dynamite = 'Dynamite', weapon_thrown_molotov = 'Molotov', weapon_thrown_poisonbottle = 'Poison Bottle'},

        description = { weapon_thrown_throwing_knives = 'Placeholder', weapon_thrown_tomahawk = 'Placeholder', weapon_thrown_tomahawk_ancient = 'Placeholder', weapon_thrown_bolas = 'Placeholder', weapon_thrown_bolas_hawkmoth = 'Placeholder', weapon_thrown_bolas_ironspiked = 'Placeholder',
                        weapon_thrown_bolas_intertwined = 'Placeholder', weapon_thrown_dynamite = 'Placeholder', weapon_thrown_molotov = 'Placeholder', weapon_thrown_poisonbottle = 'Placeholder'}

    },

    kit = {

        label = {       weapon_kit_metal_detector = 'Metal Detector', weapon_fishingrod = 'Fishingrod', weapon_kit_binoculars = 'Binoculars', weapon_kit_binoculars_improved = 'Binoculars Improved'},

        description = { weapon_kit_metal_detector = 'Placeholder', weapon_fishingrod = 'Placeholder', weapon_kit_binoculars = 'Placeholder', weapon_kit_binoculars_improved = 'Placeholder'}

    },

}

Lang = Lang or Locale:new({
    phrases = Translations,
    warnOnMissing = true
})
