RSGShared = RSGShared or {}
RSGShared.Vehicles = RSGShared.Vehicles or {}

local Vehicles = {

--[[
    --- Compacts (0)
    {
        model = 'asbo',        -- This has to match the spawn code of the vehicle
        name = 'Asbo',         -- This is the display of the vehicle
        brand = 'Maxwell',     -- This is the vehicle's brand
        price = 4000,          -- The price that the vehicle sells for
        category = 'compacts', -- Catgegory of the vehilce, stick with GetVehicleClass() options https://docs.fivem.net/natives/?_0x29439776AAA00A62
        type = 'automobile',   -- Vehicle type, refer here https://docs.fivem.net/natives/?_0x6AE51D4B & here https://docs.fivem.net/natives/?_0xA273060E
        shop = 'pdm',          -- Can be a single shop or multiple shops. For multiple shops for example {'shopname1','shopname2','shopname3'}
    },
--]]

}

for i = 1, #Vehicles do
    RSGShared.Vehicles[Vehicles[i].model] = {
        spawncode = Vehicles[i].model,
        name = Vehicles[i].name,
        brand = Vehicles[i].brand,
        model = Vehicles[i].model,
        price = Vehicles[i].price,
        category = Vehicles[i].category,
        hash = joaat(Vehicles[i].model),
        type = Vehicles[i].type,
        shop = Vehicles[i].shop
    }
end
