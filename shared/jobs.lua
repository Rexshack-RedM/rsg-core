RSGShared = RSGShared or {}

RSGShared.ForceJobDefaultDutyAtLogin = true -- true: Force duty state to jobdefaultDuty | false: set duty state from database last saved

RSGShared.Jobs = {
    ['unemployed'] = {
        label = 'Civilian',
        defaultDuty = true,
        offDutyPay = false,
        grades = {
            ['0'] = {
                name = 'Freelancer',
                payment = 10
            },
        },
    },
    ['medic'] = {
        label = 'Medic',
        defaultDuty = true,
        offDutyPay = false,
        grades = {
            ['0'] = {
                name = 'Recruit',
                payment = 50
            },
            ['1'] = {
                name = 'Trainee',
                payment = 75
            },
            ['2'] = {
                name = 'Doctor',
                payment = 100
            },
            ['3'] = {
                name = 'Surgeon',
                payment = 125
            },
            ['4'] = {
                name = 'Manager',
                isboss = true,
                payment = 150
            },
        },
    },
    ['valweaponsmith'] = { --valentine
        label = 'Valentine Weaponsmith',
        defaultDuty = true,
        offDutyPay = false,
        grades = {
            ['0'] = {
                name = 'Trainee',
                payment = 25
            },
            ['1'] = {
                name = 'Master',
                isboss = true,
                payment = 75
            },
        },
    },
    ['rhoweaponsmith'] = { -- rhodes
        label = 'Rhodes Weaponsmith',
        defaultDuty = true,
        offDutyPay = false,
        grades = {
            ['0'] = {
                name = 'Trainee',
                payment = 25
            },
            ['1'] = {
                name = 'Master',
                isboss = true,
                payment = 75
            },
        },
    },
}
