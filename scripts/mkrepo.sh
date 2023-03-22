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

set -eux

ORG="fiubatps"
API="https://api.github.com"

# Template con el que inicializar los repos (rama main).
SKEL_REPO="./.labs"
SKEL_REFSPEC="main:refs/heads/main"
#SKEL_REPO="./jos"
#SKEL_REFSPEC="main:refs/heads/main"

# Orga: ramas adicionales que enviar desde el esqueleto.
# SKEL_REPO="$HOME/orga/orgalabs"
# SKEL_REFSPEC="origin/master:refs/heads/master origin/2020_1/lab1:refs/heads/lab1"

# Algo 2: todas las ramas
# SKEL_REPO="$HOME/fiuba/skel/algo2_alu_skel"
# SKEL_REFSPEC="--all"

# El identificador numérico de un equipo "eqx" se puede obtener con:
#   http -a ... $API/orgs/$ORG/teams | jq '.[] | select(.slug == "eqx") | .id'

### Sistemas operativos ###
ADM_ID=3581967  # sisop-adm

#DOC_ID=3581970  # sisop-20a
#DOC_SLUG="sisop-20a"
#DOC_ID=4731728  # sisop-21a
#DOC_SLUG="sisop-21a"
#DOC_ID=5845178 # sisop-22a
#DOC_SLUG="sisop-22a"
DOC_ID=6491595 # sisop-22b
DOC_SLUG="sisop-22b"

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
TOKEN=$(< .fiubatp.tok)

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

status_checks='null'
push_restrictions='{"users": [], "teams": ["'"$DOC_SLUG"'"]}'
required_pr_review='{"dismiss_stale_reviews": true, "require_code_owner_reviews": false, "dismissal_restrictions": {}}'

while read users repo; do
    url="https://nobody:$TOKEN@github.com/$ORG/$repo"

    echo "############### $repo ###############"

    # Crear el repositorio.
    post "orgs/$ORG/repos" name:="\"$repo\""   \
                           private:=true       \
                           has_wiki:=false     \
                           allow_squash_merge:=false \
                           allow_rebase_merge:=false

    # Dar permisos a los equipos docentes.
    if [[ -n ADM_ID ]]; then
        put "teams/$ADM_ID/repos/$ORG/$repo" permission:='"admin"'
        put "teams/$DOC_ID/repos/$ORG/$repo" permission:='"maintain"'
    else
        put "teams/$DOC_ID/repos/$ORG/$repo" permission:='"admin"'
    fi

    # Enviar el esqueleto.
    if [ -n "${SKEL_REPO-}" ]; then
        git -C "$SKEL_REPO" push "$url" ${SKEL_REFSPEC:-main:refs/heads/main}

        # Proteger la rama main.
        #put "repos/$ORG/$repo/branches/main/protection" \
        #    enforce_admins:=false                         \
        #    allow_deletions:=false                        \
        #    restrictions:="$push_restrictions"            \
        #    required_status_checks:="$status_checks"      \
        #    required_pull_request_reviews:="$required_pr_review"
    fi

    # Enviar la invitación.
    for user in $(echo $users | tr , ' '); do
        put "repos/$ORG/$repo/collaborators/$user" permission:='"push"'
    done
done
