# AltGra
Altitude Graphique - Script LUA conçu pour OpenTX 2.2 ou supérieur

Ce script permet d'afficher l'altitude de façon graphique.

Fonctionnalités principales:
 * L'axe du temps se compresse au fur et à mesure. Ainsi on peut voir toute la séance de vol.
 * Le script se remet à zéro après un appui long sur le bouton ENT et en choisissant réinitialisation télémétrie.
 * Si l’altitude dépasse les 1000m (punaise, vous avez de bons yeux), alors l'écran se modifie afin d'afficher tout correctement (voir les captures d'écran ci-dessous).

<img src="images/X9_pres.png" />
<img src="images/X7_pres.png" />

**Important:** ce script ne gère pas les altitudes négatives. Elles sont forcées à 0m.

Le script démarre automatiquement lorsque l'altitude dépasse 3m (réglable dans le script).

Si besoin, il faut modifier le nom du capteur (le nom est visible dans la page télémétrie). Le nom par défaut est "Alt".
Si vous ne souhaitez pas que les graphiques soient pleins, alors il faut mettre la variable graphPlein sur false.
```
local nomVario = "Alt"      -- Nom de votre capteur d'altitude (il est défini dans votre page télémétrie)
local altStart = 3          -- Démarre l'enregistrement si l'altitude est supérieure (valeur en mètre)
local graphPlein = true     -- Il faut choisir "true" ou "false": true va afficher le graphique en plein
```
Voilà ce qui est affiché si vous régler `graphPlein = false`

<img src="images/X9_non_plein.png" />
<img src="images/X7_non_plein.png" />

Le script doit être copié sur la carte SD dans le dossier suivant:
**\SCRIPTS\TELEMETRY**

Puis il faut l'activer:
<img src="images/radio_telemetrie.png" />
