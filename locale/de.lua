local Translations = {
    error = {
        not_online = 'Spieler ist nicht online',
        wrong_format = 'Falsches Format',
        missing_args = 'Nicht alle Argumente wurden eingegeben (x, y, z)',
        missing_args2 = 'Alle Argumente müssen ausgefüllt sein!',
        no_access = 'Kein Zugriff auf diesen Befehl',
        company_too_poor = 'Dein Arbeitgeber ist pleite',
        item_not_exist = 'Gegenstand existiert nicht',
        too_heavy = 'Inventar zu voll',
        location_not_exist = 'Ort existiert nicht',
        duplicate_license = 'Doppelte Rockstar-Lizenz gefunden',
        no_valid_license  = 'Keine gültige Rockstar-Lizenz gefunden',
        not_whitelisted = 'Du bist nicht für diesen Server freigeschaltet',
        server_already_open = 'Der Server ist bereits geöffnet',
        server_already_closed = 'Der Server ist bereits geschlossen',
        no_permission = 'Du hast keine Berechtigungen dafür..',
        no_waypoint = 'Kein Wegpunkt gesetzt.',
        tp_error = 'Fehler beim Teleportieren.',
    },
    success = {
        server_opened = 'Der Server wurde geöffnet',
        server_closed = 'Der Server wurde geschlossen',
        teleported_waypoint = 'Zum Wegpunkt teleportiert.',
    },
    info = {
        received_paycheck = 'Du hast deinen Gehalt von $%{value} erhalten',
        job_info = 'Beruf: %{value} | Grad: %{value2} | Dienst: %{value3}',
        gang_info = 'Gang: %{value} | Grad: %{value2}',
        on_duty = 'Du bist jetzt im Dienst!',
        off_duty = 'Du bist jetzt nicht im Dienst!',
        checking_ban = 'Hallo %s. Wir überprüfen, ob du gebannt bist.',
        join_server = 'Willkommen %s auf {Server Name}.',
        checking_whitelisted = 'Hallo %s. Wir überprüfen deine Freischaltung.',
        exploit_banned = 'Du wurdest wegen Cheating gebannt. Schau auf unserem Discord für weitere Informationen nach: %{discord}',
        exploit_dropped = 'Du wurdest für Ausnutzung gekickt',
        pvp_on = 'PVP : AN',
        pvp_off = 'PVP : AUS',
    },
    command = {
        tp = {
            help = 'TP zu Spieler oder Koordinaten (nur Admin)',
            params = {
                x = { name = 'id/x', help = 'ID des Spielers oder X-Position'},
                y = { name = 'y', help = 'Y-Position'},
                z = { name = 'z', help = 'Z-Position'},
            },
        },
        pvp = {
            help = 'PvP AN/AUS)',
        },
        tpm = { help = 'TP zum Marker (nur Admin)' },
        noclip = { help = 'No Clip (nur Admin)' },
        addpermission = {
            help = 'Gib einem Spieler Berechtigungen (nur Gott)',
            params = {
                id = { name = 'id', help = 'ID des Spielers' },
                permission = { name = 'permission', help = 'Berechtigungsstufe' },
            },
        },
        removepermission = {
            help = 'Entferne einem Spieler Berechtigungen (nur Gott)',
            params = {
                id = { name = 'id', help = 'ID des Spielers' },
                permission = { name = 'permission', help = 'Berechtigungsstufe' },
            },
        },
        openserver = { help = 'Öffne den Server für alle (nur Admin)' },
        closeserver = {
            help = 'Schließe den Server für Personen ohne Berechtigungen (nur Admin)',
            params = {
                reason = { name = 'reason', help = 'Grund für die Schließung (optional)' },
            },
        },
        car = {
            help = 'Fahrzeug spawnen (nur Admin)',
            params = {
                model = { name = 'model', help = 'Modellname des Fahrzeugs' },
            },
        },
        dv = { help = 'Fahrzeug löschen (nur Admin)' },
        spawnwagon = { help = 'Eine Kutsche spawnen (nur Admin)' },
        spawnhorse = { help = 'Ein Pferd spawnen (nur Admin)' },
        givemoney = {
            help = 'Gib einem Spieler Geld (nur Admin)',
            params = {
                id = { name = 'id', help = 'Spieler-ID' },
                moneytype = { name = 'moneytype', help = 'Art des Geldes (Bargeld, Bank, Blutgeld)' },
                amount = { name = 'amount', help = 'Betrag des Geldes' },
            },
        },
        setmoney = {
            help = 'Setze den Geldbetrag eines Spielers (nur Admin)',
            params = {
                id = { name = 'id', help = 'Spieler-ID' },
                moneytype = { name = 'moneytype', help = 'Art des Geldes (Bargeld, Bank, Blutgeld)' },
                amount = { name = 'amount', help = 'Betrag des Geldes' },
            },
        },
        job = { help = 'Überprüfe deinen Beruf' },
        setjob = {
            help = 'Setze den Beruf eines Spielers (nur Admin)',
            params = {
                id = { name = 'id', help = 'Spieler-ID' },
                job = { name = 'job', help = 'Berufsname' },
                grade = { name = 'grade', help = 'Berufsgrad' },
            },
        },
        gang = { help = 'Überprüfe deine Gang' },
        setgang = {
            help = 'Setze die Gang eines Spielers (nur Admin)',
            params = {
                id = { name = 'id', help = 'Spieler-ID' },
                gang = { name = 'gang', help = 'Gangname' },
                grade = { name = 'grade', help = 'Ganggrad' },
            },
        },
        ooc = { help = 'OOC Chat Nachricht' },
        me = {
            help = 'Zeige lokale Nachricht',
            params = {
                message = { name = 'message', help = 'Zu sendende Nachricht' }
            },
        },
    },
}

if GetConvar('rsg_locale', 'en') == 'de' then
    Lang = Locale:new({
        phrases = Translations,
        warnOnMissing = true,
        fallbackLang = Lang,
    })
end
