-- Script réalisé par LapinFou
-- Version 1.0

-- Site web: http://opentx-doc.fr

-- ## Options modifiable depuis l'interface Widget OpenTX
local defaultOptions = {
  { "Capteur", SOURCE, 249 },
  { "Plein",   BOOL,   1 },
  { "Auto",    BOOL,   1 },
  { "Inter",   SOURCE, 110 },
  { "Couleur", COLOR,  RED }
}

-- ##############
-- ## Création ##
-- ##############
local function creationWidget(zone, options)
  local maZone  = { zone=zone, options=options, params={} }
  
  -- Démarre l'enregistrement si l'altitude est supérieure (valeur en mètre)
  maZone.params.altStart = 3
  
  -- Conversion en boolean
  if (options.Plein == 0) then
    maZone.params.graphPlein = false
  else
    maZone.params.graphPlein = true
  end

  if (options.Auto == 0) then
    maZone.params.auto = false
  else
    maZone.params.auto = true
  end
  
  -- Variables globales
  maZone.params.newAlt = 0        -- Nouvelle altitude provenant du capteur
  maZone.params.maxAltAffi = 20   -- Altitude max affichable
  maZone.params.altMax = 0        -- Altitude max reçue par le vario
  maZone.params.tableAlt = {}     -- Tableau où sont stockes toutes les altitudes
  maZone.params.tableIndex = 0    -- Index indiquant jusqu'où est rempli le tableau
  maZone.params.gradAlt = 5       -- Altitude pour 1 graduation
  maZone.params.tempsMax = 20     -- Init du temps max en seconde
  maZone.params.tpsPrec = 0       -- Temps de la dernière mise à jour du tableau
  maZone.params.compTemps = 6     -- Compression du temps compTemps/(compTemps-1) - La valeur mini est 2
  maZone.params.grdeAlt = false   -- Décalage du graphique vers la droite si l'altitude est supérieure à 960m
  maZone.params.startAlt = false  -- Démarre l'enregistrement

  -- Determiner le type d'affichage
  if ((maZone.zone.w > 380) and (maZone.zone.h > 165)) then
    maZone.params.affichage = "XL"
  elseif ((maZone.zone.w > 180) and (maZone.zone.h > 145)) then
    maZone.params.affichage = "L"
  elseif ((maZone.zone.w > 170) and (maZone.zone.h > 65)) then
    maZone.params.affichage = "M"
  elseif ((maZone.zone.w > 150) and (maZone.zone.h > 28)) then
    maZone.params.affichage = "S"
  end

  -- Nombre de lignes horizontales
  if (maZone.params.affichage == "L") then
    maZone.params.nbrLigneAlt = 5
  elseif (maZone.params.affichage == "S") then
    maZone.params.nbrLigneAlt = 4
  else
    maZone.params.nbrLigneAlt = 6
  end

  -- Calcul de la largeur du temps
  if (maZone.params.affichage == "XL") then
	maZone.params.largeurTps = maZone.zone.w-52
  elseif ((maZone.params.affichage == "L") or (maZone.params.affichage == "M")) then
	maZone.params.largeurTps = maZone.zone.w-24
  else
    maZone.params.largeurTps = maZone.zone.w-1
  end
  
  -- Nombre de seconde par pixel sur l'axe X
  -- Init le nombre de seconde par pixel sur l'axe X
  maZone.params.secParPix = 100*maZone.params.tempsMax/maZone.params.largeurTps
  
  -- Hauteur de l'axe représentant l'altitude en mètre
  if (maZone.params.affichage == "L") then
    maZone.params.hauteurAlt = maZone.zone.h-20
  else
    maZone.params.hauteurAlt = maZone.zone.h
  end  
  
  -- Nombre de pixels par graduation
  -- Calcul nombre de pixel pour 1 graduation (arrondi inférieur)
  maZone.params.nbrPixelGrad = math.floor(maZone.params.hauteurAlt/maZone.params.nbrLigneAlt)
  
  -- Valeur en mètre d'un pixel sur l'axe Y
  -- Mettre à jour l'échelle de l'axe altitude
  maZone.params.pixelParMetre = maZone.params.nbrPixelGrad/maZone.params.gradAlt

  -- Init du tableau à 0
  for index = 0, maZone.params.largeurTps-1 do
      maZone.params.tableAlt[index] = 0
  end

  return maZone
end

-- ###########################
-- ## Mise à jour du Widget ##
-- ###########################
local function majWidget(widgetToUpdate, newOptions)
  widgetToUpdate.options = newOptions

  -- Conversion en boolean
  if (options.Plein == 0) then
    widgetToUpdate.params.graphPlein = false
  else
    widgetToUpdate.params.graphPlein = true
  end

  if (options.Auto == 0) then
    widgetToUpdate.params.auto = false
  else
    widgetToUpdate.params.auto = true
  end


  print("=== DEBUG ===")
  for key,value in pairs(widgetToUpdate.options) do
    print("widgetToUpdate.options."..key.." = "..tostring(value))
  end
  for key,value in pairs(widgetToUpdate.params) do
    print("widgetToUpdate.params."..key.." = "..tostring(value))
  end
  for key,value in pairs(widgetToUpdate.zone) do
    print("widgetToUpdate.zone."..key.." = "..tostring(value))
  end
  print("=== DEBUG ===")

end

local function tacheDeFondWidget(maZone)
end

local function rafraichitWidget(maZone)
  local pointAlt =0   -- Utiliser pour marquer la graduation à droite des chiffres (1 pixel)
  local idxStart = 0  -- Index de démarrage
  local originTpsX
  local altActuel = 0 -- Altitude actuel
  local altPrec = 0   -- Altitude précédente

  -- Ajuster l'altitude par graduation afin d'avoir des multiples de 5 ou 10
  while maZone.params.maxAltAffi > (maZone.params.nbrLigneAlt*maZone.params.gradAlt) do
    if (maZone.params.gradAlt >= 30) then
      maZone.params.gradAlt = maZone.params.gradAlt+10
    else
      maZone.params.gradAlt = maZone.params.gradAlt+5
    end
  end

  -- Calcul nombre de pixel pour 1 graduation (arrondi inférieur)
  maZone.params.nbrPixelGrad = math.floor(maZone.params.hauteurAlt/maZone.params.nbrLigneAlt)
  
  -- Mettre à jour l'échelle de l'axe altitude
  maZone.params.pixelParMetre = maZone.params.nbrPixelGrad/maZone.params.gradAlt

  -- Fond du Widget
  if (maZone.params.affichage == "S") then
    lcd.drawFilledRectangle(maZone.zone.x, maZone.zone.y, maZone.zone.w, maZone.zone.h, SOLID + WHITE)
  else
    lcd.drawFilledRectangle(maZone.zone.x, maZone.zone.y-1, maZone.zone.w, maZone.zone.h+3, SOLID + WHITE)
  end
  
  -- Origine de l'axe du temps
  if (maZone.params.affichage == "S") then
    originTpsX = maZone.zone.x + 1
  else
    if (maZone.params.grdeAlt == true) then
	  originTpsX = maZone.zone.x + 24
	else
	  originTpsX = maZone.zone.x + 18
	end
  end

  -- Dessine le contour du graphique altitude
  lcd.drawRectangle(originTpsX-1, maZone.zone.y-1, maZone.params.largeurTps+2, maZone.params.hauteurAlt+2, SOLID, 2)
  
  -- Affiche l'échelle de temps uniquement pour les écrans XL et L
  if ((maZone.params.affichage == "XL") or (maZone.params.affichage == "L")) then
    local tmpMin = math.floor(maZone.params.tempsMax/60)
    local tmpSec = math.floor(maZone.params.tempsMax % 60)
	local originChronoX
	local originChronoY = maZone.zone.y+maZone.params.hauteurAlt

    if (maZone.params.affichage == "XL") then
	  originChronoX = originTpsX+maZone.params.largeurTps+5
	else
	  originChronoX = originTpsX+(maZone.zone.h/2)
	end
	
    if (tmpSec < 10) then
      lcd.drawText(originChronoX, originChronoY, tmpMin..":0"..tmpSec, SMLSIZE + TEXT_COLOR)
    else
      lcd.drawText(originChronoX, originChronoY, tmpMin..":"..tmpSec, SMLSIZE + TEXT_COLOR)
    end
	
  end
  
  -- Dessine les lignes horizontales
  for index = 1, maZone.params.nbrLigneAlt do
    pointAlt = maZone.zone.y+maZone.params.hauteurAlt-maZone.params.nbrPixelGrad*index+1
    lcd.drawLine(originTpsX, pointAlt, originTpsX+maZone.params.largeurTps-1, pointAlt, DOTTED, GREY)
    lcd.drawPoint(originTpsX-2, pointAlt)
  end

  -- Mettre à jour les nombres sur l'échelle d'altitude
  if (maZone.params.affichage == "M") then
    idxStart = 2
  else
    idxStart = 1
  end

  if (maZone.params.affichage ~= "S") then
    for index = idxStart, maZone.params.nbrLigneAlt do
      lcd.drawNumber(originTpsX-2, maZone.zone.y+maZone.params.hauteurAlt-index*maZone.params.nbrPixelGrad-7, index*maZone.params.gradAlt, SMLSIZE+RIGHT)
    end
  end

  -- Mettre à jour les valeurs affichées
  -- Gère l'affiche de l'altitude sur 4 chiffres
  -- if (maZone.params.affichage == "XL") then
    -- if (maZone.params.grdeAlt == false) then 
      -- lcd.drawText(originTpsX+maZone.params.largeurTps+2,originAlt-60,newAlt.."m", MIDSIZE)
    -- else
      -- lcd.drawText(originTpsX+maZone.params.largeurTps+2,originAlt-60,newAlt.."m", SMLSIZE)
    -- end
    -- lcd.drawText(originTpsX+maZone.params.largeurTps+2,originAlt-42,"Max:",SMLSIZE)
    -- lcd.drawText(originTpsX+maZone.params.largeurTps+2,originAlt-34,altMax.."m",SMLSIZE)
  -- else
    -- lcd.drawText(1,originAlt-12,"Alt:", SMLSIZE)
    -- lcd.drawText(2,originAlt-5,newAlt, SMLSIZE)
  -- end
  
  -- -- Dessine le graphique altitude
  -- for index = 0, largeurTps-1 do
    -- -- Converti l'altitude en pixel
    -- altActuel = originAlt-tableAlt[index]*pixelParMetre+1
    -- -- Si l'altitude est inférieur à 1 pixel, alors affiche 1 seul pixel (NB: l'axe Y fonctionne à l'envers)
    -- if (altActuel > originAlt) then
        -- altActuel = originAlt
    -- end

    -- -- Affiche la barre verticale en gris
    -- -- Teste: affiche l'altitude si altActuel != 0 ET si l'index est inférieur à tableIndex
    -- if ((altActuel ~= 0) and (index < tableIndex)) then
      -- if (graphPlein == true) then
        -- if (LCD_W == 212) then
          -- lcd.drawLine(originTps+index, originAlt, originTps+index, altActuel, SOLID, GREY_DEFAULT)
        -- else
          -- lcd.drawLine(originTps+index, originAlt, originTps+index, altActuel, SOLID, FORCE)
        -- end
      -- end

      -- -- Dessine les contours en noir
      -- -- Teste: dessine le contour sauf pour l'index 0
      -- if (index ~= 0) then
        -- lcd.drawLine(originTps+index-1, altPrec, originTps+index, altActuel, SOLID, FORCE)
      -- end
      
      -- -- Mettre l'altitude précédente en mémoire
      -- altPrec = altActuel
    -- end
  -- end
 
end

return { name="AltGra", options=defaultOptions, create=creationWidget, update=majWidget, background=tacheDeFondWidget, refresh=rafraichitWidget }
