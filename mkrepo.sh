#!/bin/bash
#
# Versión mínima de lo que la creación de repositorios podría ser:
# crear el repo sin ninguna configuración, y marcar un equipo como
# admin.
#
# Se necesita solamente rellenar DOC_SLUG: el nombre del equipo docente
# (que debe existir en la organización); y DOC_ID, el identificador
# numérico correspondiente a ese equipo. A este equipo se le asigna
# permiso de administración de los repositorios.
#
# Opcionalmente, se puede definir ADM_ID con otro identificador numérico
# de equipo. De estar definido, se asigna permiso de administración a
# este equipo, y a DOC_ID se le asigna permiso "maintain".
#
# La lista de repositorios a crear se obtiene de entrada estándar (en
# formato "username repo_name"). Por ejemplo:
#
#     janemart  sisop_2019_martinez
#     johnrdoe  sisop_2019c1_repo17
#     perezsam  sisop_2019c2_123456
#
# Se pueden agregar múltiples colaboradores por repositorio separando,
# en la primera columna del archivo, los nombres de usuario con comas:
#
#     janemart,johnrdoe  sisop_2019c1_doe_martinez

set -eu

ORG="fiubatps"
API="https://api.github.com"

# El identificador numérico de un equipo "eqx" se puede obtener con:
#   http -a ... $API/orgs/$ORG/teams | jq '.[] | select(.slug == "eqx") | .id'

### Sistemas operativos ###
ADM_ID=3581967  # sisop-adm
DOC_ID=3581970  # sisop-20a
DOC_SLUG="sisop-20a"

### Organización del Computador ###
# ADM_ID=3581979  # orga-adm
# DOC_ID=3581981  # orga-20a
# DOC_SLUG="orga-20a"

### Algoritmos y Programación II ###
# ADM_ID=3581963  # algorw-adm
# DOC_ID=3581965  # algorw-20a
# DOC_SLUG="algorw-20a"

# Autenticación (con API token) para el bot de la administración.
USER="fiubatp"
TOKEN=$(< ~/.fiubatp.tok)

api() {
      local verb="$1"; shift
      local endpoint="$1"; shift
      # apt install httpie
      http --check-status --ignore-stdin --headers \
           --auth "$USER:$TOKEN" "$verb" "$API/$endpoint" "$@"
}

get() {
    api GET "$@"
}

post() {
    api POST "$@"
}

put() {
    api PUT "$@"
}

while read users repo; do
    url="https://github.com/$ORG/$repo"

    # Crear el repositorio.
    post "orgs/$ORG/repos" name:="\"$repo\"" private:=true

    # Dar permisos a los equipos docentes.
    if [[ -v ADM_ID ]]; then
        put "teams/$ADM_ID/repos/$ORG/$repo" permission:='"admin"'
        put "teams/$DOC_ID/repos/$ORG/$repo" permission:='"maintain"'
    else
        put "teams/$DOC_ID/repos/$ORG/$repo" permission:='"admin"'
    fi

    # Enviar la invitación.
    for user in $(echo $users | tr , ' '); do
        put "repos/$ORG/$repo/collaborators/$user"
    done
done
