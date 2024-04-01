local Translations = {
    error = {
        not_online = 'Joueur non connecté',
        wrong_format = 'Format incorrect',
        missing_args = 'Tous les arguments n\'ont pas été saisis (x, y, z)',
        missing_args2 = 'Tous les arguments doivent être remplis !',
        no_access = 'Pas d\'accès à cette commande',
        company_too_poor = 'Votre employeur est à court d\'argent',
        item_not_exist = 'L\'objet n\'existe pas',
        too_heavy = 'Inventaire trop plein',
        location_not_exist = 'L\'emplacement n\'existe pas',
        duplicate_license = 'Licence Rockstar en double trouvée',
        no_valid_license = 'Aucune licence Rockstar valide trouvée',
        not_whitelisted = 'Vous n\'êtes pas sur la liste blanche de ce serveur',
        server_already_open = 'Le serveur est déjà ouvert',
        server_already_closed = 'Le serveur est déjà fermé',
        no_permission = 'Vous n\'avez pas les autorisations pour cela..',
        no_waypoint = 'Aucun marqueur défini.',
        tp_error = 'Erreur durant la téléportation.'

    },
    success = {
        server_opened = 'Le serveur a été ouvert',
        server_closed = 'Le serveur a été fermé',
        teleported_waypoint = 'Téléporté sur le marqueur.',
    },
    info = {
        received_paycheck = 'Vous avez reçu votre salaire de $%{value}',
        job_info = 'Emploi : %{value} | Grade : %{value2} | Service : %{value3}',
        gang_info = 'Gang : %{value} | Grade : %{value2}',
        on_duty = 'Vous êtes maintenant en service !',
        off_duty = 'Vous n\'êtes plus en service !',
        checking_ban = 'Bonjour %s. Nous vérifions si vous êtes banni.',
        join_server = 'Bienvenue %s sur {Server Name}.',
        checking_whitelisted = 'Bonjour %s. Nous vérifions si vous êtes sur la liste blanche.',
        exploit_banned = 'Vous avez été banni pour tricherie. Consultez notre Discord pour plus d\'informations : %{discord}',
        exploit_dropped = 'Vous avez été expulsé pour exploitation',
        pvp_on = 'PVP : À',
        pvp_off = 'PVP : Dehors',
    },
    command = {
        tp = {
            help = 'TP vers le joueur ou coords (Admins uniquement)',
            params = {
                x = { name = 'id/x', help = 'ID du joueur ou position X'},
                y = { name = 'y', help = 'position Y'},
                z = { name = 'z', help = 'position Z'},
            },
        },
        pvp = {
            help = 'PvP À/Dehors)',
        },
        tpm = { help = 'TP vers le marqueur (Admins uniquement)' },
        noclip = { help = 'No Clip (Admins uniquement)' },
        addpermission = {
            help = 'Donner des permissions au joueur (Dieu seulement)',
            params = {
                id = { name = 'id', help = 'ID du joueur' },
                permission = { name = 'permission', help = 'Niveau de permission' },
            },
        },
        removepermission = {
            help = 'Retirer les permissions du joueur (Dieu seulement)',
            params = {
                id = { name = 'id', help = 'ID du joueur' },
                permission = { name = 'permission', help = 'Niveau de permission' },
            },
        },
        openserver = { help = 'Ouvrir le serveur à tout le monde (Admins uniquement)' },
        closeserver = {
            help = 'Fermer le serveur aux personnes sans permissions (Admins uniquement)',
            params = {
                reason = { name = 'reason', help = 'Raison de la fermeture (optionnel)' },
            },
        },
        car = {
            help = 'Faire apparaître un véhicule (Admins uniquement)',
            params = {
                model = { name = 'model', help = 'Nom du modèle du véhicule' },
            },
        },
       dv = { help = 'Supprimer un véhicule (Admins uniquement)' },
       spawnwagon = { help = 'Faire apparaître un chariot (Admins uniquement)' },
       spawnhorse = { help = 'Faire apparaître un cheval (Admins uniquement)' },
       givemoney = {
           help = 'Donner de l\'argent à un joueur (Admins uniquement)',
           params = {
               id = { name = 'id', help = 'ID du joueur' },
               moneytype = { name = 'moneytype', help = 'Type d\'argent (espèces, banque, argent sale)' },
               amount = { name = 'amount', help = 'Montant' },
           },
       },
       setmoney = {
           help = 'Définir le montant de l\'argent d\'un joueur (Admins uniquement)',
           params = {
               id = { name = 'id', help = 'ID du joueur' },
               moneytype = { name = 'moneytype', help = 'Type d\'argent (espèces, banque, argent sale)' },
               amount = { name = 'amount', help = 'Montant de l\'argent' },
           },
       },
       job = { help = 'Vérifier votre emploi' },
       setjob = {
           help = 'Définir l\'emploi d\'un joueur (Admins uniquement)',
           params = {
               id = { name = 'id', help = 'ID du joueur' },
               job = { name = 'job', help = 'Nom de l\'emploi' },
               grade = { name = 'grade', help = 'Grade de l\'emploi' },
           },
       },
       gang = { help = 'Vérifier votre gang' },
       setgang = {
           help = 'Définir le gang d\'un joueur (Admins uniquement)',
           params = {
               id = { name = 'id', help = 'ID du joueur' },
               gang = { name = 'gang', help = 'Nom du gang' },
               grade = { name = 'grade', help = 'Grade du gang' },
           },
       },
       ooc = { help = 'Message de chat HRP (hors jeu de rôle)' },
       me = {
           help = 'Afficher un message local',
           params = {
               message = { name = 'message', help = 'Message à envoyer' }
            },
        },
    },
}

if GetConvar('rsg_locale', 'en') == 'fr' then
    Lang = Locale:new({
        phrases = Translations,
        warnOnMissing = true,
        fallbackLang = Lang,
    })
end
