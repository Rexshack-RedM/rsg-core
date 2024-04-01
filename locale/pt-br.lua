local Translations = {
    error = {
        not_online = 'Jogador não está online',
        wrong_format = 'Formato incorreto',
        missing_args = 'Não foram inseridos todos os argumentos (x, y, z)',
        missing_args2 = 'Todos os argumentos devem ser preenchidos!',
        no_access = 'Sem acesso a este comando',
        company_too_poor = 'Seu empregador está quebrado',
        item_not_exist = 'Item não existe',
        too_heavy = 'Inventário muito cheio',
        location_not_exist = 'Localização não existe',
        duplicate_license = 'Licença Rockstar duplicada encontrada',
        no_valid_license = 'Nenhuma licença Rockstar válida encontrada',
        not_whitelisted = 'Você não está na lista branca deste servidor',
        server_already_open = 'O servidor já está aberto',
        server_already_closed = 'O servidor já está fechado',
        no_permission = 'Você não tem permissões para isso...',
        no_waypoint = 'Nenhum ponto de referência definido.',
        tp_error = 'Erro ao teleportar.',
    },
    success = {
        server_opened = 'O servidor foi aberto',
        server_closed = 'O servidor foi fechado',
        teleported_waypoint = 'Teleportado para o ponto de referência.',
    },
    info = {
        received_paycheck = 'Você recebeu seu pagamento de $%{value}',
        job_info = 'Trabalho: %{value} | Grau: %{value2} | Dever: %{value3}',
        gang_info = 'Gangue: %{value} | Grau: %{value2}',
        on_duty = 'Agora você está de serviço!',
        off_duty = 'Agora você está fora de serviço!',
        checking_ban = 'Olá %s. Estamos verificando se você está banido.',
        join_server = 'Bem-vindo %s a {Nome do Servidor}.',
        checking_whitelisted = 'Olá %s. Estamos verificando sua permissão.',
        exploit_banned = 'Você foi banido por trapaça. Verifique o nosso Discord para mais informações: %{discord}',
        exploit_dropped = 'Você foi expulso por exploração',
        pvp_on = 'PVP : No',
        pvp_off = 'PVP : Fora',
    },
    command = {
        tp = {
            help = 'Teleportar para jogador ou coordenadas (Apenas para administradores)',
            params = {
                x = { name = 'id/x', help = 'ID do jogador ou posição X' },
                y = { name = 'y', help = 'Posição Y' },
                z = { name = 'z', help = 'Posição Z' },
            },
        },
        pvp = {
            help = 'PvP ON/OFF)',
        },
        tpm = { help = 'Teleportar para marcador (Apenas para administradores)' },
        noclip = { help = 'Modo de voo (Apenas para administradores)' },
        addpermission = {
            help = 'Dar permissões ao jogador (Apenas para administradores)',
            params = {
                id = { name = 'id', help = 'ID do jogador' },
                permission = { name = 'permissão', help = 'Nível de permissão' },
            },
        },
        removepermission = {
            help = 'Remover permissões do jogador (Apenas para administradores)',
            params = {
                id = { name = 'id', help = 'ID do jogador' },
                permission = { name = 'permissão', help = 'Nível de permissão' },
            },
        },
        openserver = { help = 'Abrir o servidor para todos (Apenas para administradores)' },
        closeserver = {
            help = 'Fechar o servidor para pessoas sem permissões (Apenas para administradores)',
            params = {
                reason = { name = 'razão', help = 'Motivo do fechamento (opcional)' },
            },
        },
        car = {
            help = 'Spawn de veículo (Apenas para administradores)',
            params = {
                model = { name = 'modelo', help = 'Nome do modelo do veículo' },
            },
        },
        dv = { help = 'Deletar veículo (Apenas para administradores)' },
        spawnwagon = { help = 'Spawn de uma carroça (Apenas para administradores)' },
        spawnhorse = { help = 'Spawn de um cavalo (Apenas para administradores)' },
        givemoney = {
            help = 'Dar dinheiro a um jogador (Apenas para administradores)',
            params = {
                id = { name = 'id', help = 'ID do jogador' },
                moneytype = { name = 'tipo_de_dinheiro', help = 'Tipo de dinheiro (dinheiro, banco, bloodmoney)' },
                amount = { name = 'quantidade', help = 'Quantidade de dinheiro' },
            },
        },
        setmoney = {
            help = 'Definir a quantidade de dinheiro de um jogador (Apenas para administradores)',
            params = {
                id = { name = 'id', help = 'ID do jogador' },
                moneytype = { name = 'tipo_de_dinheiro', help = 'Tipo de dinheiro (dinheiro, banco, bloodmoney)' },
                amount = { name = 'quantidade', help = 'Quantidade de dinheiro' },
            },
        },
        job = { help = 'Verificar seu emprego' },
        setjob = {
            help = 'Definir o emprego de um jogador (Apenas para administradores)',
            params = {
                id = { name = 'id', help = 'ID do jogador' },
                job = { name = 'emprego', help = 'Nome do emprego' },
                grade = { name = 'grau', help = 'Grau do emprego' },
            },
        },
        gang = { help = 'Verificar sua gangue' },
        setgang = {
            help = 'Definir a gangue de um jogador (Apenas para administradores)',
            params = {
                id = { name = 'id', help = 'ID do jogador' },
                gang = { name = 'gangue', help = 'Nome da gangue' },
                grade = { name = 'grau', help = 'Grau da gangue' },
            },
        },
        ooc = { help = 'Mensagem no chat OOC' },
        me = {
            help = 'Mostrar mensagem local',
            params = {
                message = { name = 'mensagem', help = 'Mensagem a ser enviada' }
            },
        },
    },
}

if GetConvar('rsg_locale', 'en') == 'pt-br' then
    Lang = Locale:new({
        phrases = Translations,
        warnOnMissing = true,
        fallbackLang = Lang,
    })
end
