local Translations = {
    error = {
     not_online = 'Pelaaja ei ole online-tilassa',
     wrong_format = 'Väärä muoto',
     missing_args = 'Kaikkia argumentteja ei ole syötetty (x, y, z)',
     missing_args2 = 'Kaikki argumentit on täytettävä!',
     no_access = 'Ei pääsyä tähän komentoon',
     company_too_poor = 'Työantajasi on konkurssissa',
     item_not_exist = 'Tuotetta ei ole olemassa',
     too_heavy = 'Varasto liian täynnä',
     location_not_exist = 'Sijaintia ei ole olemassa',
     duplicate_license = '[RSGCORE] - Rockstar-lisenssin kaksoiskappale löydetty',
     no_valid_license = '[RSGCORE] - Kelvollista Rockstar-lisenssiä ei löytynyt',
     not_whitelisted = '[RSGCORE] - Et ole sallittujen luettelossa tälle palvelimelle',
     server_already_open = 'Palvelin on jo auki',
     server_already_closed = 'Palvelin on jo suljettu',
     no_permission = 'Sinulla ei ole oikeuksia tähän..',
     no_waypoint = 'Ei reittipistettä asetettu.',
     tp_error = 'Virhe teleportoinnissa.',
     ban_table_not_found = '[RSGCORE] - Kieltotaulukkoa ei löydy tietokannasta. Varmista, että olet tuonut SQL-tiedoston oikein.',
     connecting_database_error = '[RSGCORE] - Virhe muodostettaessa yhteyttä tietokantaan. Varmista, että SQL-palvelin on käynnissä ja että server.cfg-tiedoston tiedot ovat oikein.',
     connecting_database_timeout = '[RSGCORE] - Tietokantayhteys aikakatkaistiin. Varmista, että SQL-palvelin on käynnissä ja että server.cfg-tiedoston tiedot ovat oikein.',
    },
    success = {
        server_opened = 'Palvelin on avattu',
        server_closed = 'Palvelin on suljettu',
        teleported_waypoint = 'Teleporttaa Waypointille',
    },
    info = {
     Received_paycheck = 'Sait palkkasi $%{value}',
     job_info = 'Työ: %{value} | Arvosana: %{value2} | Tulli: %{value3}',
     gang_info = 'Joukku: %{value} | Arvosana: %{value2}',
     on_duty = 'Olet nyt päivystyksessä!',
     off_duty = 'Olet nyt vapaana!',
     checking_ban = 'Hei %s. Tarkistamme, oletko bannattu.',
     join_server = 'Tervetuloa %s palveluun {Palvelimen nimi}.',
     checking_whitelisted = 'Hei %s. Tarkistamme etusi.',
     exploit_banned = 'Sinulle on annettu porttikielto huijaamisen vuoksi. Katso lisätietoja Discordistamme: %{discord}',
     exploit_dropped = 'Sinua on potkittu hyväksikäytön vuoksi',
    },
    command = {
        tp = {
            help = 'TP pelaajalle tai koordinaateille (Vain Admineille)',
            params = {
                x = { name = 'id/x', help = 'Pelaajan ID tai X-paikka'},
                y = { name = 'y', help = 'Y position'},
                z = { name = 'z', help = 'Z position'},
            },
        },
        tpm = { help = 'TP Markerille (Vain Admineille)' },
        togglepvp = { help = 'Vaihda PVP palvelimelle (Vain Admineille)' },
        noclip = { help = 'Ei klippiä (vain järjestelmänvalvoja)' },
        addpermission = {
            help = 'Anna pelaajalle admin oikeudet (God Only)',
            params = {
                id = { name = 'id', help = 'Pelaajan ID' },
                permission = { name = 'permission', help = 'Permission level' },
            },
        },
        removepermission = {
            help = 'Poista pelaajatlta admin oikeudet (God Only)',
            params = {
                id = { name = 'id', help = 'Pelaajan ID' },
                permission = { name = 'permission', help = 'Permission level' },
            },
        },
        openserver = { help = 'Avaa palvelin kaikille (Vain Admineille)' },
        closeserver = {
            help = 'Sulje palvelin ihmisiltä, ​​joilla ei ole oikeuksia (Vain Admineille)',
            params = {
                reason = { name = 'reason', help = 'Sulkemisen syy (valinnainen)' },
            },
        },
        car = {
            help = 'Spawnaa ajoneuvo (Vain Admineille)',
            params = {
                model = { name = 'model', help = 'Ajoneuvon nimi' },
            },
        },
         dv = { help = 'Poista ajoneuvo (vain järjestelmänvalvoja)' },
         dvall = { help = 'Poista kaikki ajoneuvot (vain järjestelmänvalvoja)' },
         dvp = { help = 'Poista kaikki Peds (vain järjestelmänvalvoja)' },
         dvo = { help = 'Poista kaikki objektit (vain järjestelmänvalvoja)' },
        givemoney = {
            help = 'Anna Pelaajalle rahaa (Vain Admineille)',
            params = {
                id = { name = 'id', help = 'Pelaajan ID' },
                moneytype = { name = 'moneytype', help = 'Rahan tyyppi (cash, bank, crypto)' },
                amount = { name = 'amount', help = 'Rahan määrä' },
            },
        },
        setmoney = {
            help = 'Aseta pelaajien rahasumma (Vain Admineille)',
            params = {
                id = { name = 'id', help = 'Pelaajan ID' },
                moneytype = { name = 'moneytype', help = 'Rahan tyyppi (cash, bank, crypto)' },
                amount = { name = 'amount', help = 'Rahan määrä' },
            },
        },
        job = { help = 'katso työsi' },
        setjob = {
            help = 'Aseta pelaajalle työ (Vain Admineille)',
            params = {
                id = { name = 'id', help = 'Pelaajan ID' },
                job = { name = 'job', help = 'Työn nimi' },
                grade = { name = 'grade', help = 'Arvo' },
            },
        },
        gang = { help = 'Katso jengisi' },
        setgang = {
            help = 'Aseta pelaajalle jengi (Vain Admineille)',
            params = {
                id = { name = 'id', help = 'Pelaajan ID' },
                gang = { name = 'gang', help = 'Jengin Nimi' },
                grade = { name = 'grade', help = 'Arvo' },
            },
        },
        ooc = { help = 'OOC Viesti lähipelaajille' },
        me = {
            help = 'Näytä paikallinen viesti',
            params = {
                message = { name = 'message', help = 'Mitä haluat kertoa?' }
            },
        },
    },
}

Lang = Lang or Locale:new({
    phrases = Translations,
    warnOnMissing = true
})
