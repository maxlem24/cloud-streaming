# Signature
### Maxime et Clément

## Compile :
`mvn clean package`

## Usage
- identification `<identity>`
- client verify `<signed_data>`
- client merge `<chemin/du/fichier>`
- fog init `<identity>` `<server_keys>`
- fog verify `<signature>`
- fog verify -f `<chemin/du/fichier>`
- owner init `<identity>` `<base64_keys>`
- owner sign `<chemin/du/fichier>` `<data_id>`