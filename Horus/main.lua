-- Script réalisé par LapinFou
-- Version 1.0

-- Site web: http://opentx-doc.fr

-- ## Options modifiable depuis l'interface Widget OpenTX
local defaultOptions = {
  { "Capteur", SOURCE, 249 },
  { "Auto",    BOOL,   1 },
  { "Inter",   SOURCE, 110 },
  { "Plein",   BOOL,   1 }
}

-- ##############
-- ## Création ##
-- ##############
local function creationWidget(zone, options)
  local maZone  = { zone=zone, options=options, parameters={} }
  
  -- ID capteur d'altitude
--  maZone.parameters.alt_id = getFieldInfo(maZone.options.Capteur).id
--  maZone.parameters.altMax_id = getFieldInfo(maZone.options.Capteur.."+").id
   if (maZone.options.Capteur == 0) then
    if (getFieldInfo("Alt") ~= nil) then
      maZone.options.Capteur = getFieldInfo("Alt").id
--      options.Capteur = getFieldInfo("Alt").id
    else
      maZone.options.Capteur = 240
    end
  end
 
  print("DEBUG: maZone.options.Capteur="..maZone.options.Capteur)
 
  -- Démarre l'enregistrement si l'altitude est supérieure (valeur en mètre)
  maZone.parameters.altStart = 3
  
  -- Si "Auto" alors 'altStart' est utilisé, sinon choisir un inter 3 positions (par ex: "sb")
  if (options.Auto == 0) then
    maZone.parameters.altStartMode = maZone.options.Auto
    maZone.parameters.inter_id = getFieldInfo(maZone.parameters.altStartMode).id
  else
    maZone.parameters.altStartMode = "Auto"
  end
  
  -- Il faut choisir "true" ou "false": true va afficher le graphique en plein
  if (options.Plein == 0) then
    maZone.parameters.graphPlein = false
  else
    maZone.parameters.graphPlein = true
  end
  
  -- Défini la taille d'affichage du graphique pour l'altitude: coordonnée en haut à gauche = (0,0)
  maZone.parameters.originTps = 18     -- Origine de l'axe représentant le temps en seconde
  maZone.parameters.largeurTps = 160   -- Largeur de l'axe représentant le temps en seconde
  maZone.parameters.originAlt  = 62    -- Max de l'axe représentant l'altitude en mètre (l'axe Y est inversé !!)
  maZone.parameters.hauteurAlt = 62    -- Largeur de l'axe représentant l'altitude en mètre
  
  -- Variables globales
  maZone.parameters.nbrLigneAlt = 6   -- Nombre de lignes horizontales
  maZone.parameters.nbrPixelGrad = 0  -- Nombre de pixels par graduation
  maZone.parameters.newAlt = 0        -- Nouvelle altitude provenant du capteur
  maZone.parameters.maxAltAffi = 20   -- Altitude max affichable
  maZone.parameters.altMax = 0        -- Altitude max reçue par le vario
  maZone.parameters.tableAlt = {}     -- Tableau où sont stockes toutes les altitudes
  maZone.parameters.tableIndex = 0    -- Index indiquant jusqu'où est rempli le tableau
  maZone.parameters.gradAlt = 5       -- Altitude pour 1 graduation
  maZone.parameters.pixelParMetre = 0 -- Valeur en mètre d'un pixel sur l'axe Y
  maZone.parameters.secParPix = 0     -- Nombre de seconde par pixel sur l'axe X
  maZone.parameters.tempsMax = 20     -- Init du temps max en seconde
  maZone.parameters.tpsPrec = 0       -- Temps de la dernière mise à jour du tableau
  maZone.parameters.compTemps = 6     -- Compression du temps compTemps/(compTemps-1) - La valeur mini est 2
  maZone.parameters.grdeAlt = false   -- Décalage du graphique vers la droite si l'altitude est supérieure à 960m
  maZone.parameters.startAlt = false  -- Démarre l'enregistrement

  -- Init le nombre de seconde par pixel sur l'axe X
  maZone.parameters.secParPix = 100*maZone.parameters.tempsMax/maZone.parameters.largeurTps
  
  -- Calcul nombre de pixel pour 1 graduation (arrondi inférieur)
  maZone.parameters.nbrPixelGrad = math.floor(maZone.parameters.hauteurAlt/maZone.parameters.nbrLigneAlt)
  -- Mettre à jour l'échelle de l'axe altitude
  maZone.parameters.pixelParMetre = maZone.parameters.nbrPixelGrad/maZone.parameters.gradAlt

  -- Init du tableau à 0
  for index = 0, maZone.parameters.largeurTps-1 do
      maZone.parameters.tableAlt[index] = 0
  end

  print("=== DEBUG ===")
  for key,value in pairs(maZone.options) do
    print("maZone.options."..key.." = "..tostring(value))
  end
  for key,value in pairs(maZone.parameters) do
    print("maZone.parameters."..key.." = "..tostring(value))
  end
  for key,value in pairs(maZone.zone) do
    print("maZone.zone."..key.." = "..tostring(value))
  end
  print("=== DEBUG ===")


  return maZone
end

-- ###########################
-- ## Mise à jour du Widget ##
-- ###########################
local function majWidget(widgetToUpdate, newOptions)
  print("=== DEBUG ===")
  for key,value in pairs(newOptions) do
    print("newOptions."..key.." = "..tostring(value))
  end
  print("=== DEBUG ===")
  
  --  print(widgetToUpdate)
  widgetToUpdate.options = newOptions

  if (newOptions.Capteur == 0) then
    if (getFieldInfo("Alt") ~= nil) then
      widgetToUpdate.options.Capteur = getFieldInfo("Alt").id
    else
      widgetToUpdate.options.Capteur = 240
    end
  end


  -- Nom de votre capteur d'altitude (il est défini dans votre page télémétrie)
  --widgetToUpdate.params.alt_id = getFieldInfo(newOptions.Capteur).id
  --widgetToUpdate.params.altMax_id = getFieldInfo(newOptions.Capteur.."+").id
  print("=== DEBUG ===")
  for key,value in pairs(widgetToUpdate.options) do
    print("widgetToUpdate.options."..key.." = "..tostring(value))
  end
  for key,value in pairs(widgetToUpdate.parameters) do
    print("widgetToUpdate.parameters."..key.." = "..tostring(value))
  end
  for key,value in pairs(widgetToUpdate.zone) do
    print("widgetToUpdate.zone."..key.." = "..tostring(value))
  end
  print("=== DEBUG ===")

end


local function tacheDeFondWidget(widgetToProcessInBackground)
end

local function rafraichitWidget(widgetToRefresh)
end

return { name="AltGra", options=defaultOptions, create=creationWidget, update=majWidget, background=tacheDeFondWidget, refresh=rafraichitWidget }
