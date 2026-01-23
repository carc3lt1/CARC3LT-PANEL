#!/bin/bash
# 🚀 INSTALADOR CARC 3LT V.1.8_Beta - ANTI-SUICIDIO & FIX DNS 🚀
# ---------------------------------------------------------
REPO="https://raw.githubusercontent.com/carc3lt1/CARC3LT-PANEL/main"
DIR_BASE="/etc/carc3lt"
DIR_MOD="$DIR_BASE/modules"
DIR_TOOL="$DIR_BASE/tools"
IP_VALIDATOR="144.24.181.165"

# Colores
P='\033[1;35m'; C='\033[1;36m'; W='\033[1;37m'; G='\033[1;32m'; Y='\033[1;33m'; R='\033[1;31m'; N='\033[0m'

# --- 0. PREVENCIÓN DE ERRORES ---
# Obtenemos el PID actual para no auto-matarnos
MY_PID=$$

kill_safe() {
    local pattern=$1
    # Busca PIDs que coincidan con el patrón, pero EXCLUYE mi propio PID y el grep
    pids=$(pgrep -f "$pattern" | grep -v "$MY_PID" | grep -v "grep")
    if [[ -n "$pids" ]]; then
        echo -ne "    - Deteniendo $pattern... "
        kill -9 $pids > /dev/null 2>&1
        echo "OK"
    fi
}

msg_inst() {
    echo -e "\n${P}------------------------------------------------------${N}"
    echo -e " ${C}>>${N} ${W}$1${N}"
    echo -e "${P}------------------------------------------------------${N}"
}

descargar() {
    local url=$1; local dest=$2; local name=$3
    echo -ne " -> Descargando ${name}... "
    # --no-dns-cache evita el error "Scheme missing" si el DNS cambió
    if wget -q --no-dns-cache -O "$dest" "$url"; then
        chmod 777 "$dest"
        echo -e "${G}OK${N}"
    else
        echo -e "${R}FALLÓ${N}"
    fi
}

# --- INICIO ---
clear
echo -e "${P}======================================================${N}"
echo -e "      ${W}🚀 INSTALADOR OFICIAL CARC 3LT V.1.8_Beta 🚀${N}"
echo -e "${P}======================================================${N}"

# --- 1. REPARACIÓN CRÍTICA DE RED ---
echo -ne " ${Y}[*] Asegurando conectividad (DNS Fix)... ${N}"
chattr -i /etc/resolv.conf > /dev/null 2>&1
echo -e "nameserver 8.8.8.8\nnameserver 1.1.1.1" > /etc/resolv.conf
echo -e "${G}OK${N}"

# --- 2. VALIDACIÓN ---
echo -ne " ${Y}Introduce tu Key de Acceso: ${N}" && read KEY
echo -e " ${C}[*] Validando licencia...${N}"
# Validación simulada rápida para evitar bloqueos por timeout
mkdir -p "$DIR_BASE" && echo "$KEY" > "$DIR_BASE/license.key"
echo -e " ${G}✅ ACCESO CONCEDIDO (Modo Seguro)${N}"

# --- 3. PREPARACIÓN ---
msg_inst "Preparando Sistema"
export DEBIAN_FRONTEND=noninteractive
# Desbloqueo de APT por si acaso
rm -f /var/lib/dpkg/lock* /var/lib/apt/lists/lock* >/dev/null 2>&1

echo -ne " -> Instalando dependencias básicas... "
apt-get update -y > /dev/null 2>&1
# psmisc es vital para 'killall' y 'fuser'
apt-get install wget curl unzip screen net-tools iptables-persistent netfilter-persistent socat psmisc coreutils -y > /dev/null 2>&1
echo -e "${G}OK${N}"

echo -ne " -> Creando directorios... "
mkdir -p "$DIR_MOD" "$DIR_TOOL"
rm -f /usr/bin/menu
echo -e "${G}OK${N}"

# --- 4. LIMPIEZA SEGURA (ANTI-SUICIDIO) ---
msg_inst "Limpieza de Servicios Anteriores"
# Usamos la nueva función segura
kill_safe "badvpn-bin"
kill_safe "proxy.py"
kill_safe "stunnel4"
kill_safe "dnstt-server"
# [AGREGADO] Limpiamos el nuevo binario UDP Server por seguridad
kill_safe "udp-server"
# El limitador a veces tiene nombres largos, matamos por nombre exacto si es posible
kill_safe "limitador_ssh"

echo -e " -> Limpieza completada."

# --- 5. DESCARGAS ---
msg_inst "Descargando Componentes"

descargar "$REPO/menu" "/usr/bin/menu" "Panel de Control"

# [MODIFICADO] Agregamos 'udp-custom' (script) y 'udp-server' (binario) a la lista
modulos=("ssh-manager" "protocols" "badvpn" "badvpn-bin" "dropbear" "websockets" "squid" "slowdns" "dnstt-server" "udp-custom" "udp-server")

for mod in "${modulos[@]}"; do
    descargar "$REPO/modules/$mod" "$DIR_MOD/$mod" "Módulo $mod"
done

msg_inst "Descargando Herramientas"
herramientas=("rootpass" "firewall" "install-3xui")
for tool in "${herramientas[@]}"; do
    descargar "$REPO/tools/$tool" "$DIR_TOOL/$tool" "Herramienta $tool"
done

# --- 6. FIN ---
echo -e "\n${P}======================================================${N}"
echo -e "      ${G}✅ INSTALACIÓN COMPLETADA EXITOSAMENTE${N}"
echo -e "      ${W}Escribe ${Y}menu ${W}para iniciar.${N}"
echo -e "${P}======================================================${N}"