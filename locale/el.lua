local Translations = {
    error = {
        not_online = 'Ο παίκτης δεν είναι ενεργός',
        wrong_format = 'Λανθασμένη μορφοποίηση',
        missing_args = 'Δεν έχουν δοθεί όλοι οι παράμετροι (x, y, z)',
        missing_args2 = 'Όλοι οι παράμετροι πρέπει να συμπληρωθούν!',
        no_access = 'Δεν έχεις πρόσβαση σε αυτή την εντολή',
        company_too_poor = 'Ο εργοδότης σου, πτώχευσε',
        item_not_exist = 'Δεν υπάρχει αυτό το αντικείμενο',
        too_heavy = 'Πολύ βαρύ σακίδιο',
        location_not_exist = 'Δεν υπάρχει αυτή η τοποθεσία',
        duplicate_license = 'Βρέθηκε διπλή Rockstar Άδεια χρήσης',
        no_valid_license  = 'Μη έγκυρη Rockstar Άδεια χρήσης',
        not_whitelisted = 'Δεν είναι προσκεκλημένος σε αυτό τον διακομιστή',
        server_already_open = 'Αυτός ο διακομιστής έχει ήδη ανοίξει',
        server_already_closed = 'Αυτός ο διακομιστής έχει ήδη κλείσει',
        no_permission = 'Δεν έχεις άδεια για αυτό..',
        no_waypoint = 'Δεν ορίστηκε προορισμός.',
        tp_error = 'Πρόβλημα καθώς μεταφερόσουν.',
        connecting_database_error = 'Πρόβλημα στην σύνδεση της βάσης δεδομένων. (Είναι ενεργός ο SQL διακομιστής?)',
        connecting_database_timeout = 'Έληξε ο χρόνος σύνδεσης της βάσης δεδομένων. (Είναι ενεργός ο SQL διακομιστής?)',
    },
    success = {
        server_opened = 'Αυτός ο διακομιστής έχει ανοίξει',
        server_closed = 'Αυτός ο διακομιστής έχει κλείσει',
        teleported_waypoint = 'Τηλεμεταφέρθηκες στο σημείο.',
    },
    info = {
        received_paycheck = 'Έχεις λάβει πληρωμή, τάξεως $%{value}',
        job_info = 'Εργασία: %{value} | Βαθμός: %{value2} | Καθήκον: %{value3}',
        gang_info = 'Συμμορία: %{value} | Βαθμός: %{value2}',
        on_duty = 'Τώρα είσαι σε υπηρεσία!',
        off_duty = 'Τώρα είσαι εκτός υπηρεσίας!',
        checking_ban = 'Γειά %s. Ελέγχουμε εάν έχεις αποκλειστεί.',
        join_server = 'Καλως ήρθες %s στο {Server Name}.',
        checking_whitelisted = 'Γειά %s. Ελέγχουμε εάν έχεις προσκληθεί.',
        exploit_banned = 'Έχεις αποκλειστεί για αντικανονικό παιχνίδι. Έλεγξε το Discord μας για παραπάνω λεπτομέριες: %{discord}',
        exploit_dropped = 'Έχεις εκδιωχθεί για αντικανονικό παιχνίδι.',
    },
    command = {
        tp = {
            help = 'Τηλεμεταφορά σε παίκτη ή συντεταγμένες (Admin Μόνο)',
            params = {
                x = { name = 'id/x', help = 'ID του παίκτη ή X θέση'},
                y = { name = 'y', help = 'Y θέση' },
                z = { name = 'z', help = 'Z θέση' },
            },
        },
        tpm = { help = 'Τηλεμεταφορά σε Marker (Admin Μόνο)' },
        togglepvp = { help = 'Ενεργοποίησε το PVP στον διακομιστή (Admin Μόνο)' },
        addpermission = {
            help = 'Δώσε πρόσβαση στον παίκτη (God Μόνο)',
            params = {
                id = { name = 'id', help = 'ID του παίκτη' },
                permission = { name = 'permission', help = 'Επίπεδο πρόσβασης' },
            },
        },
        removepermission = {
            help = 'Αφαίρεση πρόσβασης παίκτη (God Μόνο)',
            params = {
                id = { name = 'id', help = 'ID του παίκτη' },
                permission = { name = 'permission', help = 'Επίπεδο πρόσβασης' },
            },
        },
        openserver = { help = 'Άνοιξε τον διακομιστή για όλους (Admin Μόνο)' },
        closeserver = {
            help = 'Κλείσε τον server για άτομα μη εξουσιοδοτημένα. (Admin Μόνο)',
            params = {
                reason = { name = 'reason', help = 'Λόγος κλεισίματος (προαιρετικό)' },
            },
        },
        car = {
            help = 'Δημιουργία οχήματος (Admin Μόνο)',
            params = {
                model = { name = 'model', help = 'Όνομα μοντέλου του οχήματος' },
            },
        },
        dv = { help = 'Σβήσιμο οχήματος (Admin Μόνο)' },
        givemoney = {
            help = 'Δώσε χρήματα σε έναν παίκτη (Admin Μόνο)',
            params = {
                id = { name = 'id', help = 'ID του παίκτη' },
                moneytype = { name = 'moneytype', help = 'Τύπος χρήματος (μετρητά, τράπεζα, crypto)' },
                amount = { name = 'amount', help = 'Ποσό χρημάτων' },
            },
        },
        setmoney = {
            help = 'Ορισμός ποσού χρημάτων παικτών (Admin Μόνο)',
            params = {
                id = { name = 'id', help = 'ID του παίκτη' },
                moneytype = { name = 'moneytype', help = 'Τύπος χρήματος (μετρητά, τράπεζα, crypto)' },
                amount = { name = 'amount', help = 'Ποσό χρημάτων' },
            },
        },
        job = { help = 'Έλεγξε τη δουλειά σου' },
        setjob = {
            help = 'Ορισμός εργασίας παίκτη (Admin Μόνο)',
            params = {
                id = { name = 'id', help = 'ID του παίκτη' },
                job = { name = 'job', help = 'Όνομα εργασίας' },
                grade = { name = 'grade', help = 'Βαθμός εργασίας' },
            },
        },
        gang = { help = 'Έλεγξε την συμμορία σου' },
        setgang = {
            help = 'Όρισε σε έναν παίκτη μια συμμορία (Admin Μόνο)',
            params = {
                id = { name = 'id', help = 'ID του παίκτη' },
                gang = { name = 'gang', help = 'Όνομα συμμορίας' },
                grade = { name = 'grade', help = 'Βαθμός συμμορίας' },
            },
        },
        ooc = { help = 'OOC Μήνυμα Συνομιλίας' },
        me = {
            help = 'Προβολή τοπικού μηνύματος',
            params = {
                message = { name = 'message', help = 'Μήνυμα προς αποστολή' }
            },
        },
    },
}

Lang = Lang or Locale:new({
    phrases = Translations,
    warnOnMissing = true
})
