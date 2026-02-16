#!/bin/bash

# ==========================================
#  GIT MASTER - MENÚ INTERACTIVO
# ==========================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 1. CONFIGURACIÓN DE CREDENCIALES
setup_credentials() {
    if [ ! -f ~/.git-credentials ]; then
        echo -e "${YELLOW}--- Configuración de GitHub ---${NC}"
        echo -n "Usuario de GitHub: "
        read GIT_USER
        echo -n "Token de GitHub (PAT): "
        read -s GIT_TOKEN
        echo ""
        echo "https://${GIT_USER}:${GIT_TOKEN}@github.com" > ~/.git-credentials
        chmod 600 ~/.git-credentials
        git config --global credential.helper store
        git config --global user.name "$GIT_USER"
        git config --global init.defaultBranch main
    fi
    USER_GIT=$(git config --global user.name)
    TOKEN_GIT=$(grep "github.com" ~/.git-credentials | cut -d':' -f3 | cut -d'@' -f1)
}

# 2. MENÚ DE SELECCIÓN DE RUTA
get_path() {
    clear
    echo -e "${BLUE}=========================================${NC}"
    echo -e "${BLUE}       GIT AUTO-UPLOAD MENU              ${NC}"
    echo -e "${BLUE}=========================================${NC}"
    echo -e "\n${YELLOW}Ingresa la ruta de la carpeta que quieres subir:${NC}"
    echo -e "${WHITE}(O presiona ENTER para subir la carpeta actual: $(pwd))${NC}"
    echo -n "Ruta: "
    read TARGET_PATH

    # Si está vacío, usar el directorio actual
    if [ -z "$TARGET_PATH" ]; then
        TARGET_PATH=$(pwd)
    fi

    # Validar si la ruta existe
    if [ ! -d "$TARGET_PATH" ]; then
        echo -e "${RED}[!] Error: La ruta '$TARGET_PATH' no es válida.${NC}"
        exit 1
    fi

    cd "$TARGET_PATH" || exit 1
}

# 3. LÓGICA DE SUBIDA
upload_process() {
    setup_credentials
    
    # Limpiar nombre del repo (espacios -> guiones)
    REPO_NAME=$(basename "$(pwd)" | tr ' ' '-')

    echo -e "\n${BLUE}[*] Trabajando en: $(pwd)${NC}"

    # Evitar bloqueos de seguridad de Git en Kali
    git config --global --add safe.directory "$(pwd)" 2>/dev/null

    # Inicializar si no existe
    if [ ! -d ".git" ]; then
        git init
        git branch -M main
    fi

    # Configurar Remoto
    git remote remove origin 2>/dev/null
    git remote add origin "https://github.com/$USER_GIT/$REPO_NAME.git"

    # Preparar archivos
    git add .
    echo -e "${BLUE}[*] Ingresa mensaje del commit (Enter para automático):${NC}"
    read MSG
    if [ -z "$MSG" ]; then MSG="Auto-Update $(date +'%Y-%m-%d %H:%M')"; fi
    
    git commit -m "$MSG" || echo "Nada nuevo para subir."

    echo -e "${YELLOW}[*] Subiendo a GitHub...${NC}"
    
    if ! git push -u origin main; then
        echo -e "${BLUE}[*] El repo no existe en GitHub. Creándolo...${NC}"
        curl -s -H "Authorization: token $TOKEN_GIT" \
             -d "{\"name\":\"$REPO_NAME\"}" \
             https://api.github.com/user/repos > /dev/null
        git push -u origin main
    fi

    if [ $? -eq 0 ]; then
        echo -e "\n${GREEN}=========================================${NC}"
        echo -e "   EXITO: https://github.com/$USER_GIT/$REPO_NAME"
        echo -e "=========================================${NC}"
    fi
}

# EJECUCIÓN
get_path
upload_process
