#!/bin/bash

# Colores para la terminal
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 1. CONFIGURACIÓN DE CREDENCIALES
setup_credentials() {
    if [ ! -f ~/.git-credentials ]; then
        echo -e "${YELLOW}--- Configuración de GitHub (Solo una vez) ---${NC}"
        echo -n "Usuario de GitHub: "
        read GIT_USER
        echo -n "Token de GitHub (PAT): "
        read -s GIT_TOKEN
        echo ""
        
        # Guardar credenciales para que Git no las pida siempre
        echo "https://${GIT_USER}:${GIT_TOKEN}@github.com" > ~/.git-credentials
        chmod 600 ~/.git-credentials
        
        git config --global credential.helper store
        git config --global user.name "$GIT_USER"
        git config --global user.email "$GIT_USER@users.noreply.github.com"
        echo -e "${GREEN}[V] Credenciales guardadas.${NC}"
    fi
    
    # Extraer variables para la API
    USER_GIT=$(git config --global user.name)
    TOKEN_GIT=$(grep "github.com" ~/.git-credentials | cut -d':' -f3 | cut -d'@' -f1)
}

# 2. LÓGICA PRINCIPAL
main() {
    # Limpiar nombre del repo: espacios por guiones
    FOLDER_NAME=$(basename "$PWD")
    REPO_NAME=$(echo "$FOLDER_NAME" | tr ' ' '-')

    # Inicializar si es necesario
    if [ ! -d ".git" ]; then
        echo -e "${BLUE}[*] Inicializando repositorio Git...${NC}"
        git init
        git branch -M main
    fi

    # Configurar el remoto (borra el anterior si existe para evitar errores de URL)
    git remote remove origin 2>/dev/null
    git remote add origin "https://github.com/$USER_GIT/$REPO_NAME.git"

    echo -e "${BLUE}[*] Agregando archivos...${NC}"
    git add .

    # Commit con fecha/hora
    COMMIT_MSG="Auto-Update $(date +'%Y-%m-%d %H:%M')"
    git commit -m "$COMMIT_MSG" || echo "No hay cambios nuevos para commit."

    echo -e "${YELLOW}[*] Intentando subir a GitHub...${NC}"
    
    # Intentar Push
    if ! git push -u origin main; then
        echo -e "${YELLOW}[!] El repositorio no existe en GitHub. Creándolo mediante API...${NC}"
        
        # Crear repo en GitHub
        CREATE_REPO=$(curl -s -H "Authorization: token $TOKEN_GIT" \
            -d "{\"name\":\"$REPO_NAME\", \"private\":false}" \
            https://api.github.com/user/repos)

        if echo "$CREATE_REPO" | grep -q "name"; then
            echo -e "${GREEN}[V] Repositorio '$REPO_NAME' creado en GitHub.${NC}"
            git push -u origin main
        else
            echo -e "${RED}[X] Error: No se pudo crear el repo. Revisa tu Token y permisos.${NC}"
            exit 1
        fi
    fi

    if [ $? -eq 0 ]; then
        echo -e "\n${GREEN}=========================================${NC}"
        echo -e "${GREEN}   SUBIDA EXITOSA: $REPO_NAME            ${NC}"
        echo -e "   URL: https://github.com/$USER_GIT/$REPO_NAME"
        echo -e "${GREEN}=========================================${NC}"
    fi
}

# Ejecutar funciones
setup_credentials
main
