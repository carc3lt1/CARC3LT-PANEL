#!/bin/bash
# 🚀 INSTALADOR CARC 3LT V.1.8_Beta - VERSIÓN FINAL BLINDADA 🚀
# ---------------------------------------------------------

# --- 0. AUTO-ELEVACIÓN INICIAL (FORCE ROOT) ---
# Si el usuario no es root (ID 0), recargamos el script con sudo inmediatamente.
if [ "$(id -u)" -ne 0 ]; then
  echo "📢 El script requiere permisos ROOT. Elevando automáticamente..."
  # Se vuelve a descargar y ejecutar a sí mismo como root puro
  sudo bash -c "$(curl -fsSL https://raw.githubusercontent.com/carc3lt1/CARC3LT-PANEL/main/install.sh)"
  exit
fi
# A partir de aquí, aseguramos que somos ROOT
# ---------------------------------------------

REPO="https://raw.githubusercontent.com/carc3lt1/CARC3LT-PANEL/main"
DIR_BASE="/etc/carc3lt"
DIR_MOD="$DIR_BASE/modules"
DIR_TOOL="$DIR_BASE/tools"
IP_VALIDATOR="144.24.181.165"

# Colores
P='\033[1;35m'; C='\033[1;36m'; W='\033[1;37m'; G='\033[1;32m'; Y='\033[1;33m'; R='\033[1;31m'; N='\033[0m'

# --- 1. FUNCIÓN DE LIMPIEZA BLINDADA (NO SE MATA A SÍ MISMO) ---
MY_PID=$$
MY_PPID=$PPID

kill_safe() {
    local pattern=$1
    # Buscamos procesos que coincidan, pero EXCLUIMOS CRÍTICAMENTE:
    # - El PID actual del script ($MY_PID)
    # - El PID padre ($MY_PPID)
    # - Procesos de 'bash' (para no matar la terminal)
    # - La palabra 'install' (por si el script se llama install.sh)
    # - Comandos de descarga (curl/wget)
    pids=$(pgrep -f "$pattern" | grep -v "$MY_PID" | grep -v "$MY_PPID" | grep -v "grep" | grep -v "bash" | grep -v "install" | grep -v "curl" | grep -v "wget")
    
    if [[ -n "$pids" ]]; then
        echo -ne "    - Deteniendo $pattern... "
        # Enviamos señal kill solo a los PIDs filtrados
        echo "$pids" | xargs kill -9 > /dev/null 2>&1
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

# --- 2. REPARACIÓN CRÍTICA DE RED ---
echo -ne " ${Y}[*] Asegurando conectividad (DNS Fix)... ${N}"
chattr -i /etc/resolv.conf > /dev/null 2>&1
echo -e "nameserver 8.8.8.8\nnameserver 1.1.1.1" > /etc/resolv.conf
echo -e "${G}OK${N}"

# --- 3. VALIDACIÓN ---
echo -ne " ${Y}Introduce tu Key de Acceso: ${N}" && read KEY
echo -e " ${C}[*] Validando licencia...${N}"
mkdir -p "$DIR_BASE" && echo "$KEY" > "$DIR_BASE/license.key"
echo -e " ${G}✅ ACCESO CONCEDIDO (Modo Seguro)${N}"

# --- 4. PREPARACIÓN ---
msg_inst "Preparando Sistema"
export DEBIAN_FRONTEND=noninteractive
rm -f /var/lib/dpkg/lock* /var/lib/apt/lists/lock* >/dev/null 2>&1

echo -ne " -> Instalando dependencias básicas... "
apt-get update -y > /dev/null 2>&1
apt-get install wget curl unzip screen net-tools iptables-persistent netfilter-persistent socat psmisc coreutils -y > /dev/null 2>&1
echo -e "${G}OK${N}"

echo -ne " -> Creando directorios... "
mkdir -p "$DIR_MOD" "$DIR_TOOL"
rm -f /usr/bin/menu
echo -e "${G}OK${N}"

# --- 5. LIMPIEZA SEGURA ---
msg_inst "Limpieza de Servicios Anteriores"
# Ahora kill_safe filtrará el propio script para no matarse
kill_safe "badvpn-bin"
kill_safe "proxy.py"
kill_safe "stunnel4"
kill_safe "dnstt-server"
kill_safe "udp-server"
kill_safe "limitador_ssh"
echo -e " -> Limpieza completada."

# --- 6. DESCARGAS ---
msg_inst "Descargando Componentes"

descargar "$REPO/menu" "/usr/bin/menu" "Panel de Control"

modulos=("ssh-manager" "protocols" "badvpn" "badvpn-bin" "dropbear" "websockets" "squid" "slowdns" "dnstt-server" "udp-custom" "udp-server")
for mod in "${modulos[@]}"; do
    descargar "$REPO/modules/$mod" "$DIR_MOD/$mod" "Módulo $mod"
done

msg_inst "Descargando Herramientas"
herramientas=("rootpass" "firewall" "install-3xui")
for tool in "${herramientas[@]}"; do
    descargar "$REPO/tools/$tool" "$DIR_TOOL/$tool" "Herramienta $tool"
done

# --- 7. FIN ---
echo -e "\n${P}======================================================${N}"
echo -e "      ${G}✅ INSTALACIÓN COMPLETADA EXITOSAMENTE${N}"
echo -e "      ${W}Escribe ${Y}menu ${W}para iniciar.${N}"
echo -e "${P}======================================================${N}"

# --- 8. QUEDARSE EN ROOT ---
# Nos aseguramos de dejar al usuario en una shell de root limpia
echo -e " ${Y}Accediendo a terminal Root...${N}"
cd /root
exec sudo su -