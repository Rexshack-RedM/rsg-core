local Translations = {
    error = {
        not_online = 'Player non online',
        wrong_format = 'Formato non corretto',
        missing_args = 'Non tutti gli argomenti sono stati inseriti (x, y, z)',
        missing_args2 = 'Tutti gli argomenti devono essere compilati!',
        no_access = 'Nessun accesso a questo comando',
        company_too_poor = 'Il tuo datore di lavoro è al verde',
        item_not_exist = 'L\'oggetto non esiste',
        too_heavy = 'Inventario troppo pieno',
        location_not_exist = 'La posizione non esiste',
        duplicate_license = 'Trovata una licenza Rockstar duplicata',
        no_valid_license  = 'Nessuna licenza Rockstar valida trovata',
        not_whitelisted = 'Non sei nella whitelist di questo server',
        server_already_open = 'Il server è già aperto',
        server_already_closed = 'Il server è già chiuso',
        no_permission = 'Non hai le autorizzazioni per questo..',
        no_waypoint = 'Nessun waypoint impostato.',
        tp_error = 'Errore durante il teletrasporto.',
    },
    success = {
        server_opened = 'Il server è stato aperto',
        server_closed = 'Il server è stato chiuso',
        teleported_waypoint = 'Teletrasportato al waypoint.',
    },
    info = {
        received_paycheck = 'Hai ricevuto lo stipendio di $%{value}',
        job_info = 'Lavoro: %{value} | Grado: %{value2} | Servizio: %{value3}',
        gang_info = 'Gang: %{value} | Grado: %{value2}',
        on_duty = 'Ora sei in servizio!',
        off_duty = 'Ora sei fuori servizio!',
        checking_ban = 'Ciao %s. Stiamo controllando se sei bannato.',
        join_server = 'Benvenuto %s su {Server Name}.',
        checking_whitelisted = 'Ciao %s. We are checking your allowance.',
        exploit_banned = 'Sei stato bannato per cheating. Controlla la nostra Discord per ulteriori informazioni: %{discord}',
        exploit_dropped = 'Sei stato cacciato per Exploitation',
    },
    command = {
        tp = {
            help = 'TP al giocatore o coordinate (solo Admin)',
            params = {
                x = { name = 'id/x', help = 'ID del player o coordinata X'},
                y = { name = 'y', help = 'coordinata Y'},
                z = { name = 'z', help = 'coordinata Z'},
            },
        },
        tpm = { help = 'TP al Marker (solo Admin)' },
        noclip = { help = 'No Clip (solo Admin)' },
        addpermission = {
            help = 'Concedi i permessi al giocatore (solo God)',
            params = {
                id = { name = 'id', help = 'ID del player' },
                permission = { name = 'permission', help = 'Livello di permesso' },
            },
        },
        removepermission = {
            help = 'Rimuovi i permessi al giocatore(solo God)',
            params = {
                id = { name = 'id', help = 'ID of player' },
                permission = { name = 'permission', help = 'Livello di permesso' },
            },
        },
        openserver = { help = 'Apri il server per tutti (solo Admin)' },
        closeserver = {
            help = 'Chiudi il server per le persone senza autorizzazioni (solo Admin)',
            params = {
                reason = { name = 'reason', help = 'Motivo della chiusura (opzionale)' },
            },
        },
        car = {
            help = 'Spawna Veicolo (solo Admin)',
            params = {
                model = { name = 'model', help = 'Nome del modello del veicolo' },
            },
        },
        dv = { help = 'Elimina Veicolo (solo Admin)' },
        spawnwagon = { help = 'Spawna un Carro (solo Admin)' },
        spawnhorse = { help = 'Spawna un Cavallo (solo Admin)' },
        givemoney = {
            help = 'Dai soldi a un giocatore (solo Admin)',
            params = {
                id = { name = 'id', help = 'Player ID' },
                moneytype = { name = 'moneytype', help = 'Tipo di denaro (cash, bank, bloodmoney)' },
                amount = { name = 'amount', help = 'Importo denaro' },
            },
        },
        setmoney = {
            help = 'Imposta importo soldi del giocatore (solo Admin)',
            params = {
                id = { name = 'id', help = 'Player ID' },
                moneytype = { name = 'moneytype', help = 'Tipo di denaro (cash, bank, bloodmoney)' },
                amount = { name = 'amount', help = 'Importo denaro' },
            },
        },
        job = { help = 'Verifica il tuo lavoro attuale' },
        setjob = {
            help = 'Imposta un lavoro per il giocatore (solo Admin)',
            params = {
                id = { name = 'id', help = 'Player ID' },
                job = { name = 'job', help = 'Nome del lavoro' },
                grade = { name = 'grade', help = 'Grado Lavoro' },
            },
        },
        gang = { help = 'Verifica la tua Gang attuale' },
        setgang = {
            help = 'Imposta una gang per il giocatore (solo Admin)',
            params = {
                id = { name = 'id', help = 'Player ID' },
                gang = { name = 'gang', help = 'Nome Gang' },
                grade = { name = 'grade', help = 'Grado Gang' },
            },
        },
        ooc = { help = 'Messaggio Chat OOC' },
        me = {
            help = 'Mostra messaggio locale',
            params = {
                message = { name = 'message', help = 'Messaggio da inviare' }
            },
        },
    },
}

if GetConvar('rsg_locale', 'en') == 'it' then
    Lang = Locale:new({
        phrases = Translations,
        warnOnMissing = true,
        fallbackLang = Lang,
    })
end
