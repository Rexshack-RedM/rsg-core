local Translations = {
    error = {
        not_online = 'Jugador no conectado',
        wrong_format = 'Formato incorrecto',
        missing_args = 'No se han introducido todos los argumentos (x, y, z)',
        missing_args2 = '¡Todos los argumentos deben ser rellenados!',
        no_access = 'No hay acceso a este comando',
        company_too_poor = 'Su empleador está en quiebra',
        item_not_exist = 'Item no existe',
        too_heavy = 'Inventario full',
        location_not_exist = 'La ubicación no existe',
        duplicate_license = 'Se ha encontrado un duplicado de la licencia de Rockstar',
        no_valid_license  = 'No se ha encontrado una licencia válida de Rockstar',
        not_whitelisted = 'No estás en la whitelist de este servidor',
        server_already_open = 'El servidor ya está abierto',
        server_already_closed = 'El servidor ya está cerrado',
        no_permission = 'No tienes permisos para esto..',
        no_waypoint = 'No se ha fijado ningún punto de referencia.',
        tp_error = 'Error al teletransportarse.',
    },
    success = {
        server_opened = 'El servidor ha sido abierto',
        server_closed = 'El servidor ha sido cerrado',
        teleported_waypoint = 'Teletransportado a un punto de referencia.',
    },
    info = {
        received_paycheck = 'Has recibido tu paga de $%{value}',
        job_info = 'Trabajo: %{value} | Grado: %{value2} | En servicio: %{value3}',
        gang_info = 'Gang: %{value} | Grado: %{value2}',
        on_duty = '¡Ahora estás de servicio!',
        off_duty = '¡Ahora estás fuera ee servicio!',
        checking_ban = 'Hola %s.Estamos comprobando si está baneado.',
        join_server = 'Bienvenido %s to {Server Name}.',
        checking_whitelisted = 'Hola %s. Estamos revisando su asignación.',
        exploit_banned = 'Has sido baneado por hacer trampas. Consulta nuestro Discord para obtener más información: %{discord}',
        exploit_dropped = 'Te han kickeado por explotación',
    },
    command = {
        tp = {
            help = 'TP al jugador o a las coordenadas (Sólo Admin)',
            params = {
                x = { name = 'id/x', help = 'ID de jugador o posición X'},
                y = { name = 'y', help = 'Y posición'},
                z = { name = 'z', help = 'Z posición'},
            },
        },
        tpm = { help = 'TP al marcador (Sólo para admin)' },
        noclip = { help = 'No Clip (Sólo para admin)' },
        addpermission = {
            help = 'Dar permisos al jugador (Sólo modo dios)',
            params = {
                id = { name = 'id', help = 'ID del jugadaor' },
                permission = { name = 'permission', help = 'Nivel de autorización' },
            },
        },
        removepermission = {
            help = 'Eliminar los permisos de los jugadores (Sólo modo dios)',
            params = {
                id = { name = 'id', help = 'ID del jugadaor' },
                permission = { name = 'permission', help = 'Nivel de autorización' },
            },
        },
        openserver = { help = 'Abrir el servidor para todos (Sólo para admin)' },
        closeserver = {
            help = 'Cerrar el servidor para personas sin permisos (Sólo para admin)',
            params = {
                reason = { name = 'reason', help = 'Motivo del cierre (opcional)' },
            },
        },
        car = {
            help = 'Aparecer Vehículo  (Sólo admin)',
            params = {
                model = { name = 'model', help = 'Nombre del modelo del vehículo' },
            },
        },
        dv = { help = 'Borrar vehículo (Sólo admin)' },
        spawnwagon = { help = 'Generar un carro (Sólo admin)' },
        spawnhorse = { help = 'Generar un caballo (Sólo Admin)' },
        givemoney = {
            help = 'Dar dinero a un jugador (Sólo admin)',
            params = {
                id = { name = 'id', help = 'ID de jugador' },
                moneytype = { name = 'moneytype', help = 'Tipo de dinero (efectivo, banco, oro)' },
                amount = { name = 'amount', help = 'Cantidad de dinero' },
            },
        },
        setmoney = {
            help = 'Dar la cantidad de dinero de los jugadores (sólo admin)',
            params = {
                id = { name = 'id', help = 'ID de jugador' },
                moneytype = { name = 'moneytype', help = 'Tipo de dinero (efectivo, banco, oro)' },
                amount = { name = 'amount', help = 'Cantidad de dinero' },
            },
        },
        job = { help = 'Comprueba tu trabajo' },
        setjob = {
            help = 'Establecer un trabajo de jugador (sólo admin)',
            params = {
                id = { name = 'id', help = 'ID de jugador' },
                job = { name = 'job', help = 'Nombre de trabajo' },
                grade = { name = 'grade', help = 'Grado de trabajo' },
            },
        },
        gang = { help = 'Comprueba tu banda' },
        setgang = {
            help = 'Establecer una banda de jugadores (sólo admin)',
            params = {
                id = { name = 'id', help = 'ID de jugador' },
                gang = { name = 'gang', help = 'Nombre de la banda' },
                grade = { name = 'grade', help = 'Grado en la banda' },
            },
        },
        ooc = { help = 'OOC Chat Mensaje' },
        me = {
            help = 'Muestra mensaje local',
            params = {
                message = { name = 'message', help = 'Mensaje a enviar' }
            },
        },
    },
}

if GetConvar('rsg_locale', 'en') == 'es' then
    Lang = Locale:new({
        phrases = Translations,
        warnOnMissing = true,
        fallbackLang = Lang,
    })
end
