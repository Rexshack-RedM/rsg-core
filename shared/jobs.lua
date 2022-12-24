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
    ['farmer'] = {
        label = 'Farmer',
        defaultDuty = true,
        offDutyPay = false,
        grades = {
            ['0'] = {
                name = 'Farm Hand',
                payment = 25
            },
            ['1'] = {
                name = 'Farm Owner',
                isboss = true,
                payment = 75
            },
        },
    },
    ['weaponsmith'] = {
        label = 'Weaponsmith',
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
    ['saloontender'] = {
        label = 'Saloon Tender',
        defaultDuty = true,
        offDutyPay = false,
        grades = {
            ['0'] = {
                name = 'Trainee',
                payment = 25
            },
            ['1'] = {
                name = 'Tender',
                payment = 50
            },
            ['2'] = {
                name = 'Manager',
                isboss = true,
                payment = 75
            },
        },
    },
    ['railroad'] = {
        label = 'Railroad',
        defaultDuty = true,
        offDutyPay = false,
        grades = {
            ['0'] = {
                name = 'Conductor',
                payment = 25
            },
            ['1'] = {
                name = 'Driver',
                payment = 50
            },
            ['2'] = {
                name = 'Station Manager',
                isboss = true,
                payment = 75
            },
        },
    },
    ['police'] = {
        label = 'Law Enforcement',
        defaultDuty = true,
        offDutyPay = false,
        grades = {
            ['0'] = {
                name = 'Recruit',
                payment = 50
            },
            ['1'] = {
                name = 'Officer',
                payment = 75
            },
            ['2'] = {
                name = 'Sergeant',
                payment = 100
            },
            ['3'] = {
                name = 'Lieutenant',
                payment = 125
            },
            ['4'] = {
                name = 'Chief',
                isboss = true,
                payment = 150
            },
        },
    },
    ['ambulance'] = {
        label = 'EMS',
        defaultDuty = true,
        offDutyPay = false,
        grades = {
            ['0'] = {
                name = 'Recruit',
                payment = 50
            },
            ['1'] = {
                name = 'Paramedic',
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
                name = 'Chief',
                isboss = true,
                payment = 150
            },
        },
    },
    ['realestate'] = {
        label = 'Real Estate',
        defaultDuty = true,
        offDutyPay = false,
        grades = {
            ['0'] = {
                name = 'Recruit',
                payment = 50
            },
            ['1'] = {
                name = 'House Sales',
                payment = 75
            },
            ['2'] = {
                name = 'Business Sales',
                payment = 100
            },
            ['3'] = {
                name = 'Broker',
                payment = 125
            },
            ['4'] = {
                name = 'Manager',
                isboss = true,
                payment = 150
            },
        },
    },
    ['judge'] = {
        label = 'Honorary',
        defaultDuty = true,
        offDutyPay = false,
        grades = {
            ['0'] = {
                name = 'Judge',
                payment = 100
            },
        },
    },
    ['lawyer'] = {
        label = 'Law Firm',
        defaultDuty = true,
        offDutyPay = false,
        grades = {
            ['0'] = {
                name = 'Associate',
                payment = 50
            },
        },
    }
}