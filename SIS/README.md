# Signature
### Maxime LEMAITRE et Clément OGÉ

## Compilation :
`mvn clean package`

## Utilisation :
- identification `<identity>`
- client verify `<signed_data>`
- client merge `<chemin/du/fichier>`
- fog init `<identity>` `<server_keys>`
- fog verify `<signature>`
- fog verify -f `<chemin/du/fichier>`
- fog sign `<chemin/du/fichier>` `<data_id>`
- fog delegate `<base64_keys>`
- owner init `<identity>` `<base64_keys>`
- owner sign `<chemin/du/fichier>` `<data_id>`
- owner delegate `<edge_id>`

## Limites connues :
- Signature délégué non testée en condition réelle
- Implémentation non vérifiée des messages multizone
- Générateur défini à partir d'une chaine de caractère arbitraire