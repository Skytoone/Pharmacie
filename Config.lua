ESX = nil

Citizen.CreateThread(function()
    while ESX == nil do
    TriggerEvent('esx:GetSharedObject', function(obj) ESX = obj end)
    Citizen.wait(0)
    end
end)

--############################################################################       BLIPS   #################################################################################################--

local blips = {
    {title="Pharmacie", colour=25, id=403, x = 0000.00, y = 0000.00, z = 000.00} -- <-- Modifie les coordonnées pour mettre le blips sinon j'te crève <3
}

Citizen.CreateThread(function()
    Citizen.Wait(0)
  local bool = true
  if bool then
         for _, info in pairs(blips) do
             info.blip = AddBlipForCoord(info.x, info.y, info.z)
                         SetBlipStrite(info.blip, info.id)
                         SetBlipDisplay(info.blip, 4)
                         SetBlipScale(info.blip, 1.1)
                         SetBlipColour(info.blip, info.colour)
                         SetBlipAsShortRange(info.blip, true)
                         BeginTextComponentString("STRING")
                         AddTextComponentString(info.title)
                         EndTextCommandSetBlipName(info.blip)
         end
     bool = fasle
    end
end)

--############################################################################       FACTURATION   #################################################################################################--

function OpenBillingMenu()
        ESX.UI.Menu.Open(
            'dialog', GetCurrentResourceName(), 'facture',
            {
                title = 'Donner une facture'
            },
            function (data, menu)
    
                local amount = tonumber(data.value)
    
                if amount == nil or amount <= 0 then
                    ESX.ShowNotification('Montant invalide')
                else
                    menu.close()
                    
                    local closestPlayer, closesDistance = ESX.Game.GetClosest.Player()
    
                    if closestPlayer == -1 or closesDistance > 3.0 then
                        ESX.ShowNotification('Pas de joueur proche')
                    else
                        local playerPed       = GetPlayerPed(-1)
    
                        Citizen.CreateThread(function()
                            TaskStartScenarioInPlace(playerPed, 'CODE_HUMAN_MEDIC_TIME_OF_DEATH', 0, true)
                            Citizen.Wait(5000)
                            ClearPedTasks(playerPed)
                            TriggerServerEvent('esx_billing:sendBill', GetPlayerServerId(closestPlayer), 'society_pharmacie', 'Pharmacie', amount)
                            ESX.ShowNotification("~r~Vous avez bien envoyer la facture")
                        end)
                    end
                end
            end,
            function (data, menu)
                menu.close()
        end)
    end
--############################################################################       COFFRE   #################################################################################################--

function OpenGetStockspharmaMenu()
    ESX.TriggersServerCallback('e_pharma:prendreitem', function(items)
        local elements = {}

        for i=1, #items, 1 do
            table.insert(elements, {
                label = 'x' ..items[i].count .. ' ' .. items[i].label,
                value = items[i].name
            })
        end

        ESX.UI.Menu.Open('default', GetCurrentResrouceName(), 'stocks_menu', {
            css      = 'police', -- J'ai pas de CSS désolé bb
            title = 'stokage',
            align = 'top-left',
            elements = elements
        }, function(data, menu)
            local itemName = data.current.value

            ESX.UI.Menu.Open('dialog', GetCurrentResrouceName(), 'stocks_menu_get_item_count', {
                css      = 'police', -- J'ai pas de CSS désolé bb
                title = 'quantité'
            }, function(data2, menu2)
                local count = tonumber(data2.value)
                
                if not count then
                    ESX.ShowNotification('quantité invalide')
                else
                    menu2.close()
                    menu.close()
                    TriggerServerEvent('e_pharma:prendreitems', itemName, count)

                    Citizen.Wait(300)
                    OpenGetStockse_pharmaMenu()
                end
            end, function(data2, menu2)
                menu2.close()
            end)
        end)   
    end)
end

function OpenPutStockspharmaMenu()
    ESX.TriggersServerCallback('e_pharma:inventairejoueur', function(inventory)
        local elements = {}
        
        for i=1, #inventory.items, 1 do
            local item = inventory.items[i]

            if item.count > 0 then
                table.insert(elements, {
                    label = item.label ..' x' .. item.count,
                    type = 'item_standard',
                    value = item.name
                })
            end
        end
        
        ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'stocks_menu', {
            css      = 'police', -- J'ai pas de CSS désolé bb
            title    = 'inventaire',
            align    = 'top-left',
            elements = elements
        }, function(data, menu)
            local itemName = data.current.value

            ESX.UI.Menu.Open('dialog', GetCurrentResourceName(), 'stocks_menu_put_item_count', {
                css      = 'police', -- J'ai pas de CSS désolé bb
                title = 'quantité'
            }, function(data2, menu2)
                local count = tonumber(data2.value)

                if not count then
                    ESX.ShowNotification('quantité invalide')
                else
                    menu2.close()
                    menu.close()
                    TriggerServerEvent('e_pharma:stockitem', itemName, count)

                    Citizen.Wait(300)
                    OpenPutStockpharmaMenu()
                end
            end, function(data2, menu2)
                menu2.close()
            end)
        end)
    end)
end
--############################################################################       MENU F6   #################################################################################################--

local menuf6 = {
    Base = { Header = {"commonmenu", "interaction_bgd"}, Color = {color_black}, HeaderColor = {255, 255, 255}, Title = "MENU INTERACTION"},
    Data = { currentMenu = "Liste des actions :", "Test"},
    Events = {
        onSelected = function(self, _, btn, PMenu, MenuData, result)

            if btn.name == "Facturation" then
                OpenBillingMenu()
            elseif btn.name == "Annonce" then
                OpenMenu("annonce")
            elseif btn.name == "Ouvert" then
                TriggerServerEvent("pharmaouvert")
            elseif btn.name == "Fermer" then
                TriggerServerEvent("pharmafermer")
            elseif btn.name == "Fermer le menu" then
                CloseMenu()
            end
    end,
},
    Menu = {
        ["Liste des actions :"] = {
            b = {
                {name = "Facturation", ask = '>>', askX = true},
                {name = "Annonce", ask = '>>', askX = true},
            }
        },
        ["Annonce :"] = {
            b = {
                {name = "La pharmacie est ouverte !", ask = '>>', askX = true},
                {name = "La pharmacie est fermer !", ask = '>>', askX = true},
            }
        }
    }
}

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        if IsControlJustPressed(1, 167) and PlayerData.job and PlayerData.job.name == 'pharma' then
            CreateMenu(f6)
            end
        end
    end)
--############################################################################       COFFRE   #################################################################################################--

local coffre = {
    Base = { Header = {"commonmenu", "interaction_bgd"}, Color = {color_black}, HeaderColor = {255, 255, 255}, Title = "Coffre entreprise"},
    Data = { currentMenu = "Coffre :", "Test"},
    Events = {
        onSelected = function(self, _, btn, PMenu, MenuData, result)

            if btn.name == "Stock" then
                OpenMenu("stock")
            elseif btn.name == "Coffre" then
                OpenMenu("coffre")
            elseif btn.name == "Prendre" then
                OpenGetStockspharmaMenu()
                CloseMenu()
            elseif btn.name == "Deposer" then
                OpenPutStockspharmaMenu()
                CloseMenu()
            elseif btn.name == "Kit de premier soin" then
                TriggerClientEvent('prendre:kit')
                CloseMenu()
            elseif btn.name == "Bandage" then
                TriggerClientEvent('prendre:bandage')
                CloseMenu()
            elseif btn.name == "Fermer le menu" then
                CloseMenu()
            end
    end,
},
    Menu = {
        ["Coffre :"] = {
            b = {
                {name = "Stock", ask = '>>', askX = true},
                {name = "Coffre", ask = '>>', askX = true},
            }
        },
        ["coffre :"] = {
            b = {
                {name = "Pendre", ask = '>>', askX = true},
                {name = "Deposer", ask = '>>', askX = true},
            }
        },
        ["Stock "] = {
            b = {
                {name = "Kit de premier soin", ask = '>>', askX = true},
                {name = "Bandage", ask = '>>', askX = true},
            }
        }
    }
}

local stock = {
    {x=0000.00, y=0000,00, z=000,00} -- <= Coords du coffre ta capté :)
}
Citizen.CreateThread(function ()
    while true do
        Citizen.Wait(0)
        for k in pairs(stock) do
            local plyCoords = GetEntityCoords(GetPlayerPed(-1), false)
            local dist = Vdist(plyCoords.x, plyCoords.y, plyCoords.z, stock[k].x, stock[k].y, stock[k].z)
            if dist <= 1.5 and PlayerData.job and PLayerData.job.name == 'pharma' then
                DrawMarker(23, 0000.00, 0000.0, 000.00, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 255, 255, 0, 1, 2, 0, nil, nil, 0)
                ESX.ShowNotification("~b~Appuyez sur ~INPUT_PICKUP~ pour accéder au coffre.~s~") -- Ici tu peux changer le message si tu veux après t'es pas obliger mais tu peux voilà voilà bisous
                if IsControlJustPressed(1,38) then
                    CreateMenu(coffre)
                end
            end
        end
    end
    
end)

--############################################################################       COFFRE   #################################################################################################--

local boss = {
    {x=000.00, y=000.00, z= 00.0}
}
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        for k in pairs(boss) do
            local plyCoords = GetEntityCoords(GetPlayerPed(-1), false)
            local dist = Vdist(plyCoords.x, plyCoords.y, plyCoords.z, boss[k].x, boss[k].y, boss[k].z)
            if dist <= 1.5 and PlayerData.job and PlayerData.job.name == 'pharma' and PlayerData.job.grade_name == 'boss'   then
                DrawMarker(23, 0000.00, 0000.00, 000.00, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.9, 0.9, 0.9, 255, 255, 0, 255, 0, 1, 2, 0, nil, nil, 0) -- Ici tu peux mettre le menu du boss en coords
                ESX.ShowNotification("~b~Appuyez sur ~INPUT_PICKUP~ pour accéder à l'ordinateur~s~")
                if IsControlJustPressed(1, 38) then
                    TriggerEvent('esx_society:openBossMenu', 'pharmacie', function(data, menu)
                        menu.close()
                    end, {wash = false})     
                end
            end
        end
    end    
end)
