local Translations = {
    error = {
        not_online = 'Speler niet online',
        wrong_format = 'Verkeerd formaat',
        missing_args = 'Niet alle argumenten zijn ingevoerd (x, y, z)',
        missing_args2 = 'Alle argumenten moeten worden ingevuld!',
        no_access = 'Geen toegang tot deze opdracht',
        company_too_poor = 'Je werkgever is blut',
        item_not_exist = 'Het item bestaat niet',
        too_heavy = 'Inventaris te vol',
        location_not_exist = 'De locatie bestaat niet',
        duplicate_license = 'Dubbele Rockstar licentie gevonden',
        no_valid_license = 'Geen geldige Rockstar licentie gevonden',
        not_whitelisted = 'Je staat niet op de whitelist van deze server',
        server_already_open = 'De server is al geopend',
        server_already_closed = 'De server is al gesloten',
        no_permission = 'Je hebt geen rechten hiervoor..',
        no_waypoint = 'Geen waypoint ingesteld.',
        tp_error = 'Fout tijdens teleporteren.',
    },
    success = {
        server_opened = 'De server is geopend',
        server_closed = 'De server is gesloten',
        teleported_waypoint = 'Geteleporteerd naar waypoint.',
    },
    info = {
        received_paycheck = 'Je hebt een salaris van $%{value} ontvangen',
        job_info = 'Werk: %{value} | Rang: %{value2} | Dienst: %{value3}',
        gang_info = 'Gang: %{value} | Rang: %{value2}',
        on_duty = 'Je bent nu in dienst!',
        off_duty = 'Je bent nu uit dienst!',
        checking_ban = 'Hallo %s. We controleren of je verbannen bent.',
        join_server = 'Welkom %s op {Server Name}.',
        checking_whitelisted = 'Hallo %s. We controleren je toelating.',
        exploit_banned = 'Je bent verbannen wegens vals spelen. Check onze Discord voor meer informatie: %{discord}',
        exploit_dropped = 'Je bent gekickt wegens misbruik',
        pvp_on = 'PVP : Aan',
        pvp_off = 'PVP : Uit',
    },
    command = {
        tp = {
            help = 'TP naar speler of coördinaten (alleen Admin)',
            params = {
                x = { name = 'id/x', help = 'Speler ID of X-coördinaat'},
                y = { name = 'y', help = 'Y-coördinaat'},
                z = { name = 'z', help = 'Z-coördinaat'},
            },
        },
        pvp = {
            help = 'PvP Aan/Uit)',
        },
        tpm = { help = 'TP naar Marker (alleen Admin)' },
        noclip = { help = 'No Clip (alleen Admin)' },
        addpermission = {
            help = 'Geef speler toestemmingen (alleen God)',
            params = {
                id = { name = 'id', help = 'Speler ID' },
                permission = { name = 'permission', help = 'Toestemmingsniveau' },
            },
        },
        removepermission = {
            help = 'Verwijder toestemmingen van speler (alleen God)',
            params = {
                id = { name = 'id', help = 'Speler ID' },
                permission = { name = 'permission', help = 'Toestemmingsniveau' },
            },
        },
        openserver = { help = 'Open de server voor iedereen (alleen Admin)' },
        closeserver = {
            help = 'Sluit de server voor mensen zonder toestemming (alleen Admin)',
            params = {
                reason = { name = 'reason', help = 'Reden voor sluiting (optioneel)' },
            },
        },
        car = {
            help = 'Spawn Voertuig (alleen Admin)',
            params = {
                model = { name = 'model', help = 'Naam van voertuigmodel' },
            },
        },
        dv = { help = 'Verwijder Voertuig (alleen Admin)' },
        spawnwagon = { help = 'Spawn een Wagen (alleen Admin)' },
        spawnhorse = { help = 'Spawn een Paard (alleen Admin)' },
        givemoney = {
            help = 'Geef speler geld (alleen Admin)',
            params = {
                id = { name = 'id', help = 'Speler ID' },
                moneytype = { name = 'moneytype', help = 'Soort geld (contant, bank, bloedgeld)' },
                amount = { name = 'amount', help = 'Hoeveelheid geld' },
            },
        },
        setmoney = {
            help = 'Stel geldbedrag van speler in (alleen Admin)',
            params = {
                id = { name = 'id', help = 'Speler ID' },
                moneytype = { name = 'moneytype', help = 'Soort geld (contant, bank, bloedgeld)' },
                amount = { name = 'amount', help = 'Hoeveelheid geld' },
            },
        },
        job = { help = 'Controleer je huidige baan' },
        setjob = {
            help = 'Stel een baan in voor speler (alleen Admin)',
            params = {
                id = { name = 'id', help = 'Speler ID' },
                job = { name = 'job', help = 'Naam van de baan' },
                grade = { name = 'grade', help = 'Baan Rang' },
            },
        },
        gang = { help = 'Controleer je huidige gang' },
        setgang = {
            help = 'Stel een gang in voor speler (alleen Admin)',
            params = {
                id = { name = 'id', help = 'Speler ID' },
                gang = { name = 'gang', help = 'Gang Naam' },
                grade = { name = 'grade', help = 'Gang Rang' },
            },
        },
        ooc = { help = 'OOC Chat Bericht' },
        me = {
            help = 'Toon lokaal bericht',
            params = {
                message = { name = 'message', help = 'Bericht om te sturen' }
            },
        },
    },
}

if GetConvar('rsg_locale', 'en') == 'nl' then
    Lang = Locale:new({
        phrases = Translations,
        warnOnMissing = true,
        fallbackLang = Lang,
    })
end
