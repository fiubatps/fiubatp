#!/bin/bash
#
# Versión mínima de lo que la creación de repositorios podría ser:
# crear el repo sin ninguna configuración, y marcar un equipo como
# admin.
#
# Se necesita solamente rellenar TEAM_SLUG: el nombre del equipo docente
# (que debe existir en la organización); y TEAM_ID, el identificador
# numérico correspondiente a ese equipo.
#
# La lista de repositorios a crear se obtiene de entrada estándar (en
# formato "username repo_slug"). Todos los repositorios se prefijan
# con el nombre del equipo y el año, por lo que con una entrada de:
#
#     janemart _martinez
#     johnrdoe c1_repo17
#     perezsam c2_123456
#
# resultaría en los siguientes repositorios de Sistemas Operativos en
# 2019:
#
#     sisop_2019_martinez
#     sisop_2019c1_repo17
#     sisop_2019c2_123456
#
# Se pueden agregar múltiples colaboradores por repositorio separando,
# en la primera columna del archivo, los nombres de usuario con comas:
#
#     janemart,johnrdoe  c1_doe_martinez

set -eu

ORG="fiubatps"
API="https://api.github.com"
YEAR=$(date +%Y)

# El identificador numérico de un equipo "eqx" se puede obtener con:
#   http -a ... $API/orgs/$ORG/teams | jq '.[] | select(.slug == "eqx") | .id'
TEAM_ID=3141585
TEAM_SLUG="sisop"

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
    repo="${TEAM_SLUG}_${YEAR}${repo}"
    url="https://github.com/$ORG/$repo"

    # Crear el repositorio.
    post "orgs/$ORG/repos" name:="\"$repo\"" private:=true

    # Dar permisos al equipo docente. (En el futuro, si hay múltiples
    # correctores, otorgar a este equipo acceso "push" en lugar de
    # "admin", y crear un sub-equipo separado para administradores.)
    put "teams/$TEAM_ID/repos/$ORG/$repo" permission:='"admin"'

    # Enviar la invitación.
    for user in $(echo $users | tr , ' '); do
        put "repos/$ORG/$repo/collaborators/$user"
    done
done
