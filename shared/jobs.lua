RSGShared = RSGShared or {}
RSGShared.ForceJobDefaultDutyAtLogin = true -- true: Force duty state to jobdefaultDuty | false: set duty state from database last saved
RSGShared.Jobs = {

    unemployed = {
        name = 'unemployed',
        label = 'Civilian',
        defaultDuty = true,
        offDutyPay = false,
        grades = {
            ['0'] = { name = 'Freelancer', payment = 3 },
        },
    },

}
