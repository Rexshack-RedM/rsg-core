-----------------------------------------------------------------------
-- Seed jobs (ported from rsg-core/shared/jobs.lua)
--
-- Only used the FIRST time rsg-core starts with an empty
-- `multijob_jobs` table. After that, jobs live in the database and are
-- managed in-game with /jobadmin. Editing this file afterwards has no
-- effect unless you empty the table.
-----------------------------------------------------------------------
MultiJobDefaultJobs = {
    unemployed = {
        label = 'Civilian', defaultDuty = true, offDutyPay = false,
        grades = { ['0'] = { name = 'Freelancer', payment = 3 } },
    },
    vallaw = {
        label = 'Valentine Law Enforcement', type = 'leo', defaultDuty = false, offDutyPay = false,
        grades = {
            ['0'] = { name = 'Recruit', payment = 10 },
            ['1'] = { name = 'Deputy', payment = 25 },
            ['2'] = { name = 'Sheriff', isboss = true, payment = 50 },
        },
    },
    rholaw = {
        label = 'Rhodes Law Enforcement', type = 'leo', defaultDuty = false, offDutyPay = false,
        grades = {
            ['0'] = { name = 'Recruit', payment = 10 },
            ['1'] = { name = 'Deputy', payment = 25 },
            ['2'] = { name = 'Sheriff', isboss = true, payment = 50 },
        },
    },
    blklaw = {
        label = 'Blackwater Law Enforcement', type = 'leo', defaultDuty = false, offDutyPay = false,
        grades = {
            ['0'] = { name = 'Recruit', payment = 10 },
            ['1'] = { name = 'Deputy', payment = 25 },
            ['2'] = { name = 'Sheriff', isboss = true, payment = 50 },
        },
    },
    strlaw = {
        label = 'Strawberry Law Enforcement', type = 'leo', defaultDuty = false, offDutyPay = false,
        grades = {
            ['0'] = { name = 'Recruit', payment = 10 },
            ['1'] = { name = 'Deputy', payment = 25 },
            ['2'] = { name = 'Sheriff', isboss = true, payment = 50 },
        },
    },
    stdenlaw = {
        label = 'Saint Denis Law Enforcement', type = 'leo', defaultDuty = false, offDutyPay = false,
        grades = {
            ['0'] = { name = 'Recruit', payment = 10 },
            ['1'] = { name = 'Deputy', payment = 25 },
            ['2'] = { name = 'Sheriff', isboss = true, payment = 50 },
        },
    },
    medic = {
        label = 'Medic', type = 'medic', defaultDuty = false, offDutyPay = false,
        grades = {
            ['0'] = { name = 'Recruit', payment = 5 },
            ['1'] = { name = 'Trainee', payment = 25 },
            ['2'] = { name = 'Doctor', payment = 50 },
            ['3'] = { name = 'Surgeon', payment = 75 },
            ['4'] = { name = 'Manager', isboss = true, payment = 100 },
        },
    },
    herbalist = {
        label = 'Herbalist', defaultDuty = true, offDutyPay = false,
        grades = {
            ['0'] = { name = 'Apprentice', payment = 0 },
            ['1'] = { name = 'Master', payment = 0, isboss = true },
        },
    },
    macfarranch = {
        label = 'Macfarlane Rancher', type = 'rancher', defaultDuty = true, offDutyPay = false,
        grades = {
            ['0'] = { name = 'Trainee Rancher', payment = 3 },
            ['1'] = { name = 'Ranch Hand', payment = 5 },
            ['2'] = { name = 'Ranch Manager', isboss = true, payment = 0 },
        },
    },
    emeraldranch = {
        label = 'Emerald Rancher', type = 'rancher', defaultDuty = true, offDutyPay = false,
        grades = {
            ['0'] = { name = 'Trainee Rancher', payment = 3 },
            ['1'] = { name = 'Ranch Hand', payment = 5 },
            ['2'] = { name = 'Ranch Manager', isboss = true, payment = 0 },
        },
    },
    pronghornranch = {
        label = 'Pronghorn Rancher', type = 'rancher', defaultDuty = true, offDutyPay = false,
        grades = {
            ['0'] = { name = 'Trainee Rancher', payment = 3 },
            ['1'] = { name = 'Ranch Hand', payment = 5 },
            ['2'] = { name = 'Ranch Manager', isboss = true, payment = 0 },
        },
    },
    downesranch = {
        label = 'Downes Rancher', type = 'rancher', defaultDuty = true, offDutyPay = false,
        grades = {
            ['0'] = { name = 'Trainee Rancher', payment = 3 },
            ['1'] = { name = 'Ranch Hand', payment = 5 },
            ['2'] = { name = 'Ranch Manager', isboss = true, payment = 0 },
        },
    },
    hillhavenranch = {
        label = 'Hill Haven Rancher', type = 'rancher', defaultDuty = true, offDutyPay = false,
        grades = {
            ['0'] = { name = 'Trainee Rancher', payment = 3 },
            ['1'] = { name = 'Ranch Hand', payment = 5 },
            ['2'] = { name = 'Ranch Manager', isboss = true, payment = 0 },
        },
    },
    hangingdogranch = {
        label = 'Hanging Dog Rancher', type = 'rancher', defaultDuty = true, offDutyPay = false,
        grades = {
            ['0'] = { name = 'Trainee Rancher', payment = 3 },
            ['1'] = { name = 'Ranch Hand', payment = 5 },
            ['2'] = { name = 'Ranch Manager', isboss = true, payment = 0 },
        },
    },
}
