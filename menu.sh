#!/bin/bash
# 🚀 CARC 3LT PANEL PRO V.1.3_Beta🚀
# DASHBOARD PRINCIPAL - HÍBRIDO Y ROBUSTO
# ------------------------------------
DIR_BASE="/etc/carc3lt"
DIR_MOD="$DIR_BASE/modules"
DIR_TOOL="$DIR_BASE/tools"
KEY_FILE="$DIR_BASE/license.key"

# --- CONFIGURACIÓN DE TU BOT (ASEGÚRATE QUE SEA CORRECTA) ---
IP_SERVER_VALIDADOR="144.24.181.165"

# Colores Neon
P='\033[1;35m'; C='\033[1;36m'; W='\033[1;37m'; Y='\033[1;33m'; R='\033[1;31m'; G='\033[1;32m'; N='\033[0m'
BARRA="${P}======================================================${N}"

# --- FUNCIÓN DE EJECUCIÓN INTELIGENTE ---
# Ejecuta directamente, siendo compatible con binarios SHC y loaders Base64.
exe_mod() {
    local archivo=$1
    if [[ -f "$DIR_MOD/$archivo" ]]; then
        "$DIR_MOD/$archivo"
    else
        echo -e "${R}Error: Módulo '$archivo' no encontrado.${N}"; sleep 2
    fi
}

exe_tool() {
    local archivo=$1
    if [[ -f "$DIR_TOOL/$archivo" ]]; then
        "$DIR_TOOL/$archivo"
    else
        echo -e "${R}Error: Herramienta '$archivo' no encontrada.${N}"; sleep 2
    fi
}

# --- VALIDACIÓN DE KEY AL INICIO ---
# [CORRECCIÓN] Se ha mejorado para manejar fallos de conexión a internet.
verificar_key_online() {
    if [[ ! -f "$KEY_FILE" ]]; then
        clear
        echo -e "${R}Error: Archivo de licencia no encontrado.${N}"
        echo -e "${Y}Por favor, reinstala el panel para registrar tu licencia.${N}"
        exit 1
    fi
    
    KEY=$(cat "$KEY_FILE")
    MY_IP=$(curl -s --max-time 5 ifconfig.me) # Timeout reducido a 5s

    # Si no hay IP, significa que no hay conexión a internet.
    if [[ -z "$MY_IP" ]]; then
        clear
        echo -e "${R}Error de Conexión: No se pudo verificar la licencia.${N}"
        echo -e "${Y}Asegúrate de que el servidor tenga acceso a internet.${N}"
        exit 1
    fi

    echo -e "${C}[*] Verificando estado de la licencia...${N}"
    RES=$(curl -s --max-time 10 "http://$IP_SERVER_VALIDADOR:5000/validar/$KEY/$MY_IP")

    if [[ "$RES" != *"AUTORIZADO"* ]]; then
        clear
        echo -e "${R}Error: Tu licencia ha sido revocada, ha expirado o el servidor de validación no responde.${N}"
        echo -e "${Y}Contacta con el soporte.${N}"
        exit 1
    fi
    # Si la validación es exitosa, el script continúa silenciosamente.
}
verificar_key_online

# Optimizacion: Obtenemos datos que no cambian fuera del bucle
IP_PUBLICA=$(curl -s ifconfig.me)
OS_NAME=$(grep -oP 'PRETTY_NAME="\K[^"]+' /etc/os-release 2>/dev/null || uname -o)


# --- BUCLE PRINCIPAL ---
while true; do
    clear
    ram_used=$(free -m | grep Mem | awk '{print $3}')
    ram_total=$(free -m | grep Mem | awk '{print $2}')
    uptime_v=$(uptime -p | sed 's/up //')
    
    echo -e "${BARRA}"
    echo -e " ${W}RAM: ${C}$ram_used/${ram_total}MB${N}  |  ${W}IP: ${C}$IP_PUBLICA${N}"
    echo -e " ${W}OS: ${Y}$OS_NAME${N} | ${W}Up: ${G}$uptime_v${N}"
    echo -e "${BARRA}"
    echo -e "            ${P}🚀 CARC 3LT PANEL PRO V.1.3_Beta🚀${N}"
    echo -e "${BARRA}"
    
    echo -e " ${P}[1]${N} ${C}ADMINISTRAR USUARIOS${N}"
    echo -e " ${P}[2]${N} ${C}GESTIONAR PROTOCOLOS${N}"
    echo -e " ${P}[3]${N} ${C}HERRAMIENTAS SISTEMA${N}"
    echo ""
    echo -e " ${P}[4]${N} ${Y}ACTUALIZAR PANEL${N}"
    echo -e " ${P}[0]${N} ${R}SALIR DEL SISTEMA${N}"
    echo -e "${BARRA}"
    read -p " Selecciona una opción: " opt
    
    case $opt in
        1) exe_mod "ssh-manager" ;;
        2) exe_mod "protocols" ;;
        3) 
            clear
            echo -e "${BARRA}"; echo -e "      ${C}🛠️ HERRAMIENTAS${N}"; echo -e "${BARRA}"
            echo -e " ${P}[1]${N} Acceso Root & Pass"
            echo -e " ${P}[2]${N} Firewall Manual"
            echo -e " ${P}[3]${N} Limpiar Caché de RAM"
            echo -e " ${P}[4]${N} ${G}Instalar Panel 3x-UI${N}"
            echo -e " ${P}[0]${N} Volver"
            echo -e "${BARRA}"
            read -p " Selecciona una opción: " sub
            case $sub in
                1) exe_tool "rootpass" ;;
                2) exe_tool "firewall" ;;
                3) 
                   # [CORRECCIÓN] Añadida explicación y confirmación para una mejor experiencia de usuario.
                   echo -e "\n${Y}Esta acción libera la memoria caché de archivos del sistema.${N}"
                   echo -e "${W}No afecta a la RAM usada por los programas en ejecución.${N}"
                   read -p " ¿Deseas continuar? [s/n]: " confirm
                   if [[ "$confirm" == "s" || "$confirm" == "S" ]]; then
                       sync; echo 3 > /proc/sys/vm/drop_caches
                       echo -e "\n ${G}✅ Caché de RAM Liberada.${N}"
                   else
                       echo -e "\n ${R}Operación cancelada.${N}"
                   fi
                   sleep 2
                   ;;
                4) exe_tool "install-3xui" ;;
                0) continue ;;
                *) echo -e "\n${R}Opción no válida.${N}"; sleep 1 ;;
            esac ;;
        4) 
            echo -e "\n${Y}[*] Buscando actualizaciones en el repositorio oficial...${N}"
            if wget -q -O install.sh https://raw.githubusercontent.com/carc3lt1/CARC3LT-PANEL/main/install.sh; then
                echo -e "${G}Actualización descargada. El panel se reiniciará para aplicar los cambios.${N}"
                sleep 2
                # 'exec' reemplaza el proceso actual. Es la forma más segura de actualizar.
                exec bash ./install.sh
            else
                echo -e "\n${R}[!] Error de conexión. Revisa tu conexión a internet o DNS.${N}"
                sleep 3
            fi
            ;;
        0) exit 0 ;;
        *) echo -e "\n${R}Opción no válida. Por favor, intenta de nuevo.${N}"; sleep 1 ;;
    esac
done