# Outlaw_LawTablet (MVP)

Avocat Tablet + Bloc-note + Impression en item (doc_*).

## Dépendances
- ox_lib
- ox_mysql
- ox_inventory
- ESX (pour job/identifier). Fallbacks simples inclus.

## Installation
1. Mettre le dossier `Outlaw_LawTablet` dans `resources/`.
2. Ajouter `ensure Outlaw_LawTablet` dans `server.cfg` (après ox_lib, ox_mysql, ox_inventory).
3. Définir les **items** dans `ox_inventory/data/items.lua` (ou votre fichier items).
   Exemple à coller :

```lua
['avocat_tablet'] = {
  label = 'Tablette Avocat',
  weight = 500,
  stack = false,
  close = true,
  description = 'Accès bloc-note légal',
  client = { anim = { dict = 'amb@code_human_in_bus_passenger_idles@female@tablet@base', clip = 'base' } }
},
['doc_plainte'] = {
  label = 'Document – Plainte',
  weight = 50,
  stack = false,
  description = 'Copie imprimée d'une plainte',
},
['doc_plaidoyer'] = {
  label = 'Document – Plaidoyer',
  weight = 50,
  stack = false,
  description = 'Copie imprimée d'un plaidoyer',
},
['doc_note'] = {
  label = 'Document – Note',
  weight = 50,
  stack = false,
  description = 'Copie imprimée d'une note',
},
```

4. Donnez-vous l'item `avocat_tablet` via admin pour tester.

## Utilisation
- **Utiliser** `avocat_tablet` → ouvre l'UI Tablette (NUI).
- Créer une note (Plainte/Procès/Note), puis **Imprimer** avec l'ID → reçoit un item `doc_*` avec un snapshot HTML.
- **Utiliser** l'item `doc_*` → ouvre le lecteur (read-only) du document imprimé.
- Dans la tablette: champ "Code document" → bouton **Vérifier** pour valider un code public.

## SQL
Tables créées automatiquement au démarrage (voir `server/migrations.lua`):
- `outlaw_notes`
- `outlaw_documents_printed`

## Sécurité & Permissions
- `Config.WriterJob = 'avocat'` contrôle qui peut créer/imprimer.
- `Config.AllowPoliceRead = true` permet la lecture côté police (optionnel).
- Le contenu est **sanitizé** côté serveur de manière simple (MVP).

## Personnalisation
- Couleurs/types/status dans `config.lua`.
- Gabarit HTML imprimé dans `server/documents.lua` (`buildHtml`).

## Limites MVP
- Pas encore de "Cases/Clients" ni de versioning complet (prévu V1).
- La vérification est basique (hash maison). Vous pouvez remplacer par SHA256.
- Pas de révocation via UI (ajoutez plus tard un bouton “Révoquer”).

## Support
- Logs console `[Outlaw_LawTablet]`.
- Discord webhook optionnel (`Config.DiscordWebhook`).

## IMPORTANT — Wiring item usage (ox_inventory)
Pour que l'usage des items ouvre l'UI, ajoutez **server export** dans les items :
```lua
['avocat_tablet'] = {
  label = 'Tablette Avocat', weight = 500, stack = false, close = true,
  description = 'Accès bloc-note légal',
  server = { export = 'Outlaw_LawTablet.useTablet' },
},
['doc_plainte'] = {
  label = 'Document – Plainte', weight = 50, stack = false, description = 'Copie imprimée d\'une plainte',
  server = { export = 'Outlaw_LawTablet.useDocument' },
},
['doc_plaidoyer'] = {
  label = 'Document – Plaidoyer', weight = 50, stack = false, description = 'Copie imprimée d\'un plaidoyer',
  server = { export = 'Outlaw_LawTablet.useDocument' },
},
['doc_note'] = {
  label = 'Document – Note', weight = 50, stack = false, description = 'Copie imprimée d\'une note',
  server = { export = 'Outlaw_LawTablet.useDocument' },
},
```
> Si vous ne mettez pas ces exports, un **fallback** écoute `ox_inventory:usedItem` et devrait quand même ouvrir la tablette/lecteur selon la version d'ox_inventory.

## Debug
- Commande `/lawtablet` ouvre l'UI sans item (pour tester).
