-- Script réalisé par LapinFou
-- Version 1.0

-- Site web: http://opentx-doc.fr

-- ## Options modifiable depuis l'interface Widget OpenTX
local defaultOptions = {
  { "Capteur", SOURCE, "Alt" },
  { "Auto",    BOOL,   1 },
  { "Inter",   SOURCE, 0 },
  { "Plein",   BOOL,   1 },
  { "COLOR",   COLOR,  RED },
}

-- ##############
-- ## Création ##
-- ##############
local function creationWidget(zone, options)
  local parameters = {}
  
  -- Nom de votre capteur d'altitude (il est défini dans votre page télémétrie)
  parameters.nomVario = options.Capteur
  parameters.alt_id = getFieldInfo(parameters.nomVario).id
  parameters.altMax_id = getFieldInfo(parameters.nomVario.."+").id
  
  -- Démarre l'enregistrement si l'altitude est supérieure (valeur en mètre)
  parameters.altStart = 3
  
  -- Si "Auto" alors 'altStart' est utilisé, sinon choisir un inter 3 positions (par ex: "sb")
  if (options.Auto == 0) then
    parameters.altStartMode = options.Auto
    parameters.inter_id = getFieldInfo(parameters.altStartMode).id
  else
    parameters.altStartMode = "Auto"
  end
  
  -- Il faut choisir "true" ou "false": true va afficher le graphique en plein
  if (options.Plein == 0) then
    parameters.graphPlein = false
  else
    parameters.graphPlein = true
  end
  
  -- Défini la taille d'affichage du graphique pour l'altitude: coordonnée en haut à gauche = (0,0)
  parameters.originTps = 18     -- Origine de l'axe représentant le temps en seconde
  parameters.largeurTps = 160   -- Largeur de l'axe représentant le temps en seconde
  parameters.originAlt  = 62    -- Max de l'axe représentant l'altitude en mètre (l'axe Y est inversé !!)
  parameters.hauteurAlt = 62    -- Largeur de l'axe représentant l'altitude en mètre
  
  -- Variables globales
  parameters.nbrLigneAlt = 6   -- Nombre de lignes horizontales
  parameters.nbrPixelGrad = 0  -- Nombre de pixels par graduation
  parameters.newAlt = 0        -- Nouvelle altitude provenant du capteur
  parameters.maxAltAffi = 20   -- Altitude max affichable
  parameters.altMax = 0        -- Altitude max reçue par le vario
  parameters.tableAlt = {}     -- Tableau où sont stockes toutes les altitudes
  parameters.tableIndex = 0    -- Index indiquant jusqu'où est rempli le tableau
  parameters.gradAlt = 5       -- Altitude pour 1 graduation
  parameters.pixelParMetre = 0 -- Valeur en mètre d'un pixel sur l'axe Y
  parameters.secParPix = 0     -- Nombre de seconde par pixel sur l'axe X
  parameters.tempsMax = 20     -- Init du temps max en seconde
  parameters.tpsPrec = 0       -- Temps de la dernière mise à jour du tableau
  parameters.compTemps = 6     -- Compression du temps compTemps/(compTemps-1) - La valeur mini est 2
  parameters.grdeAlt = false   -- Décalage du graphique vers la droite si l'altitude est supérieure à 960m
  parameters.startAlt = false  -- Démarre l'enregistrement

  -- Init le nombre de seconde par pixel sur l'axe X
  parameters.secParPix = 100*parameters.tempsMax/parameters.largeurTps
  
  -- Calcul nombre de pixel pour 1 graduation (arrondi inférieur)
  parameters.nbrPixelGrad = math.floor(parameters.hauteurAlt/parameters.nbrLigneAlt)
  -- Mettre à jour l'échelle de l'axe altitude
  parameters.pixelParMetre = parameters.nbrPixelGrad/parameters.gradAlt

  -- Init du tableau à 0
  for index = 0, parameters.largeurTps-1 do
      parameters.tableAlt[index] = 0
  end

  return { zone=zone, options=options , params = parameters }
end

-- ###########################
-- ## Mise à jour du Widget ##
-- ###########################
local function majWidget(widgetToUpdate, newOptions)
  -- Nom de votre capteur d'altitude (il est défini dans votre page télémétrie)
  widgetToUpdate.params.nomVario = newOptions.Capteur
  widgetToUpdate.params.alt_id = getFieldInfo(widgetToUpdate.params.nomVario).id
  widgetToUpdate.params.altMax_id = getFieldInfo(widgetToUpdate.params.nomVario.."+").id
  
  -- Si "Auto" alors 'altStart' est utilisé, sinon choisir un inter 3 positions (par ex: "sb")
  if (newOptions.Auto == 0) then
    widgetToUpdate.params.altStartMode = newOptions.Auto
    widgetToUpdate.params.inter_id = getFieldInfo(widgetToUpdate.params.altStartMode).id
  else
    widgetToUpdate.params.altStartMode = "Auto"
  end
  
  -- Il faut choisir "true" ou "false": true va afficher le graphique en plein
  if (newOptions.Plein == 0) then
    widgetToUpdate.params.graphPlein = false
  else
    widgetToUpdate.params.graphPlein = true
  end
  
  -- Init le nombre de seconde par pixel sur l'axe X
  widgetToUpdate.params.secParPix = 100*widgetToUpdate.params.tempsMax/widgetToUpdate.params.largeurTps
  
  -- Calcul nombre de pixel pour 1 graduation (arrondi inférieur)
  widgetToUpdate.params.nbrPixelGrad = math.floor(widgetToUpdate.params.hauteurAlt/widgetToUpdate.params.nbrLigneAlt)
  -- Mettre à jour l'échelle de l'axe altitude
  widgetToUpdate.params.pixelParMetre = widgetToUpdate.params.nbrPixelGrad/widgetToUpdate.params.gradAlt

  -- Init du tableau à 0
  for index = 0, widgetToUpdate.params.largeurTps-1 do
      widgetToUpdate.params.tableAlt[index] = 0
  end

end


local function tacheDeFondWidget(widgetToProcessInBackground)
end

local function rafraichitWidget(widgetToRefresh)
end

-- ###############
-- ## Fonctions ##
-- ###############
-- Gestion de la table d'altitude
local function gestionTable()
    -- Obtenir la nouvelle altitude provenant du capteur
    newAlt = math.floor(getValue(alt_id)+0.5)
 
    -- Démarre l'enregistrement
    -- Enregistrement contrôlé par un inter 3 positions
    if (altStartMode ~= "Auto") then
        local interPosition = getValue(inter_id)
        -- Met en pause l'enregistrement
        if (interPosition < -200) then
            startAlt = false
        -- Remise à zéro
        elseif (interPosition > 200) then
            init()
        -- Démarrer l'enregistrement
        else
            startAlt = true
        end
    -- Enregistrement et remise à zéro en mode automatiquement
    else
        -- Démarre l'enregistrement des altitudes
        if (newAlt > altStart) then
            startAlt = true
        end

        -- Si l'altitude max provenant du capteur ET que l'enregistrement est en cours, alors la télémétrie a été remise à zéro
        -- En cas de perte de télémétrie, getValue() renvoie 0
        -- Donc, il faut vérifier que la télémétrie est OK avec getRSSI()
        if (((math.floor(getValue(altMax_id)+0.5)) == 0) and (startAlt == true) and (getRSSI() ~= 0)) then
            init()
        end
    end
   
    -- Enregistrement des données
    if (startAlt == true) then
        -- Mettre à jour l'altitude max
        if (newAlt > altMax) then
            altMax = newAlt
        end

        -- Si l'altitude passe à 4 chifres, alors décaler le tableau + réduire la taille altitude actuelle
        if ((altMax > 960) and (grdeAlt == false)) then
            originTps = originTps+6
            grdeAlt = true
        end
    
        -- Obtenir le temps de la radio (en 1/100 de seconde)
        local tpsActuel = getTime()
        
        -- Mettre à jour l'altitude max si la nouvelle altitude est supérieure
        if (newAlt > maxAltAffi) then
            maxAltAffi = newAlt
        end
        
        -- Si la différence de temps par rapport à la dernière mesure est > à secParPix, alors mettre à jour le tableau
        if ((tpsActuel-tpsPrec) > secParPix) then
            -- Filtre les altitudes négatives
            if (newAlt < 0) then
                tableAlt[tableIndex] = 0
            else
                tableAlt[tableIndex] = newAlt
            end
            -- Incrémenter tableIndex
            tableIndex = tableIndex+1
    
            -- Mettre à jour le temps précédent
            tpsPrec = tpsActuel
        end
    
        -- Compresser le tableau lorsqu'il est rempli
        if (tableIndex > largeurTps) then
            -- Index temporaire
            local tmpIdx = 0
            
            -- Efface 1 case sur compTemps
            for index = 0, largeurTps do
                if ((index % compTemps) ~= 0) then
                    tableAlt[tmpIdx] = tableAlt[index]
                    tmpIdx = tmpIdx+1
                end
            end
    
            -- Init à 0 les cases vides du tableau afin qu'elles ne s'affichent plus
            for index= tmpIdx, largeurTps do
                tableAlt[index] = 0
            end
            
            -- Mettre à jour l'index indiquant jusqu'où est rempli le tableau
            tableIndex = tmpIdx
            -- Mettre à jour la variable "seconde par pixel"
            tempsMax = tempsMax * compTemps/(compTemps-1)
            secParPix = 100*tempsMax/largeurTps
        end
    end
end

-- Dessine les axes temps et altitude
local function dessinerAxe()
    -- Les +2 sur les largeurs correspondent à l'épaisseur du trait (2* 1 pixel)
    lcd.drawRectangle(originTps-1, originAlt+1, largeurTps+2, -hauteurAlt, SOLID)
end

-- Dessine la grille
local function dessinerGrille()
    -- Utiliser pour marquer la graduation à droite des chiffres (1 pixel)
    local pointAlt

    -- Dessine les lignes horizontales
    for index = 1, nbrLigneAlt do
        pointAlt = originAlt-nbrPixelGrad*index+1
        if (LCD_W == 212) then
            lcd.drawLine(originTps, pointAlt, originTps+largeurTps-1, pointAlt, SOLID, GREY_DEFAULT)
        else
            lcd.drawLine(originTps, pointAlt, originTps+largeurTps-1, pointAlt, DOTTED, FORCE)
        end
        -- Dessine les points à gauche de l'axe vertical sauf pour 0 mètre
        if (index == 0) then
            if (LCD_W == 212) then
                lcd.drawPoint(originTps-2, pointAlt)
            end
        else
            lcd.drawPoint(originTps-2, pointAlt)
        end
    end
end

-- Calcul l'altitude en mètre par pixel et affiche l'échelle à gauche du graphique
local function dessinerEchelle()
    -- Index de démarrage
    local idxStart

    -- Ne pas afficher la 1ère valeur sur les radios X7
    if (LCD_W == 212) then
        idxStart = 1
    else
        idxStart = 2
    end

    -- Ajuster l'altitude par graduation afin d'avoir des multiples de 5 ou 10
    while maxAltAffi > (nbrLigneAlt*gradAlt) do
        if (gradAlt >= 30) then
            gradAlt = gradAlt+10
        else
            gradAlt = gradAlt+5
        end

        -- Calcul nombre de pixel pour 1 graduation (arrondi inférieur)
        nbrPixelGrad = math.floor(hauteurAlt/nbrLigneAlt)
    
        -- Mettre à jour l'échelle de l'axe altitude
        pixelParMetre = nbrPixelGrad/gradAlt
    end

    -- Mettre à jour les nombres sur l'échelle d'altitude
    for index = idxStart, nbrLigneAlt do
        lcd.drawNumber(originTps-2, originAlt-index*nbrPixelGrad-1, index*gradAlt, SMLSIZE+RIGHT)
    end
    
    -- Affiche l'échelle de temps en bas à droite
    if (LCD_W == 212) then
        local tmpMin = math.floor(tempsMax/60)
        local tmpSec = math.floor(tempsMax % 60)
        if (tmpSec < 10) then
            lcd.drawText(originTps+largeurTps+5, originAlt-5, tmpMin..":0"..tmpSec, SMLSIZE)
        else
            lcd.drawText(originTps+largeurTps+5, originAlt-5, tmpMin..":"..tmpSec, SMLSIZE)
        end
    end
end

-- Dessine le graphique altitude
local function dessinerAltitude()
    local altActuel = 0 -- Altitude actuel
    local altPrec = 0   -- Altitude précédente

    -- Mettre à jour les valeurs affichées
    -- Gère l'affiche de l'altitude sur 4 chiffres
    if (LCD_W == 212) then
        if (grdeAlt == false) then 
            lcd.drawText(originTps+largeurTps+2,originAlt-60,newAlt.."m", MIDSIZE)
        else
            lcd.drawText(originTps+largeurTps+2,originAlt-60,newAlt.."m", SMLSIZE)
        end
        lcd.drawText(originTps+largeurTps+2,originAlt-42,"Max:",SMLSIZE)
        lcd.drawText(originTps+largeurTps+2,originAlt-34,altMax.."m",SMLSIZE)
    else
        lcd.drawText(1,originAlt-12,"Alt:", SMLSIZE)
        lcd.drawText(2,originAlt-5,newAlt, SMLSIZE)
    end
    

    -- Dessine le graphique altitude
    for index = 0, largeurTps-1 do
        -- Converti l'altitude en pixel
        altActuel = originAlt-tableAlt[index]*pixelParMetre+1
        -- Si l'altitude est inférieur à 1 pixel, alors affiche 1 seul pixel (NB: l'axe Y fonctionne à l'envers)
        if (altActuel > originAlt) then
            altActuel = originAlt
        end

        -- Affiche la barre verticale en gris
        -- Teste: affiche l'altitude si altActuel != 0 ET si l'index est inférieur à tableIndex
        if ((altActuel ~= 0) and (index < tableIndex)) then
            if (graphPlein == true) then
                if (LCD_W == 212) then
                    lcd.drawLine(originTps+index, originAlt, originTps+index, altActuel, SOLID, GREY_DEFAULT)
                else
                    lcd.drawLine(originTps+index, originAlt, originTps+index, altActuel, SOLID, FORCE)
                end
            end

            -- Dessine les contours en noir
            -- Teste: dessine le contour sauf pour l'index 0
            if (index ~= 0) then
                lcd.drawLine(originTps+index-1, altPrec, originTps+index, altActuel, SOLID, FORCE)
            end
            
            -- Mettre l'altitude précédente en mémoire
            altPrec = altActuel
        end
    end
end

return { name="AltGra", options=defaultOptions, create=creationWidget, update=majWidget, background=tacheDeFondWidget, refresh=rafraichitWidget }
