#!/bin/bash
# 🚀 INSTALADOR CARC 3LT V.2.0_Final - PROTECTED MODE 🚀
# ---------------------------------------------------------
if [ "$(id -u)" -ne 0 ]; then
  echo "📢 Elevando permisos a ROOT para iniciar instalación..."
  sudo bash "$0" "$@"
  exit
fi

REPO="https://raw.githubusercontent.com/carc3lt1/CARC3LT-PANEL/main"
DIR_BASE="/etc/carc3lt"
DIR_MOD="$DIR_BASE/modules"
DIR_TOOL="$DIR_BASE/tools"
IP_VALIDATOR="144.24.181.165" # Tu servidor Python

# Colores
P='\033[1;35m'; C='\033[1;36m'; W='\033[1;37m'; G='\033[1;32m'; Y='\033[1;33m'; R='\033[1;31m'; N='\033[0m'

# --- 1. VALIDACIÓN ESTRICTA (PRIMER PASO) ---
clear
echo -e "${P}======================================================${N}"
echo -e "      ${W}🛡️  SISTEMA DE SEGURIDAD CARC 3LT  🛡️${N}"
echo -e "${P}======================================================${N}"

echo -ne " ${Y}Introduce tu Key de Acceso: ${N}" && read KEY
echo -e " ${C}[*] Verificando licencia con el servidor...${N}"

# 1. Obtener IP
MY_IP=$(curl -s ifconfig.me)

# 2. PETICIÓN DE VALIDACIÓN
# Si la Key es correcta, tu servidor Python enviará la notificación a Telegram AHORA.
RES=$(curl -s --max-time 10 "http://${IP_VALIDATOR}:5000/validar/${KEY}/${MY_IP}")

# 3. FILTRO DE SEGURIDAD (KILL SWITCH)
if [[ "$RES" == *"AUTORIZADO"* ]] || [[ "$RES" == *"200"* ]]; then
    echo -e " ${G}✅ LICENCIA ACEPTADA. Iniciando instalación...${N}"
    # Creamos la carpeta de licencia solo si pasó la prueba
    mkdir -p "$DIR_BASE" && echo "$KEY" > "$DIR_BASE/license.key"
else
    # ⛔ BLOQUEO TOTAL ⛔
    echo -e "\n${R}⛔ ERROR CRÍTICO: Licencia Inválida o Expulsada.${N}"
    echo -e "${R}⛔ La instalación ha sido abortada por seguridad.${N}"
    # Este comando mata el script aquí mismo. No pasa nada más.
    exit 1
fi

# -------------------------------------------------------------------
# SI LLEGA AQUÍ, ES QUE LA KEY ES VÁLIDA. COMIENZA LA INSTALACIÓN.
# -------------------------------------------------------------------

# --- 2. PREVENCIÓN DE ERRORES ---
MY_PID=$$
kill_safe() {
    local pattern=$1
    pids=$(pgrep -f "$pattern" | grep -v "$MY_PID" | grep -v "grep" | grep -v "bash" | grep -v "sudo" | grep -v "install")
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
    if [[ -f "$dest" ]]; then rm -f "$dest" > /dev/null 2>&1; fi
    echo -ne " -> Descargando ${name}... "
    if wget -q --no-dns-cache -O "$dest" "$url"; then
        chmod 777 "$dest"
        echo -e "${G}OK${N}"
    else
        echo -e "${R}FALLÓ${N}"
    fi
}

# --- 3. REPARACIÓN DE RED ---
echo -ne " ${Y}[*] Ajustando DNS... ${N}"
chattr -i /etc/resolv.conf > /dev/null 2>&1
echo -e "nameserver 8.8.8.8\nnameserver 1.1.1.1" > /etc/resolv.conf
echo -e "${G}OK${N}"

# --- 4. PREPARACIÓN ---
msg_inst "Preparando Sistema"
export DEBIAN_FRONTEND=noninteractive
rm -f /var/lib/dpkg/lock* /var/lib/apt/lists/lock* >/dev/null 2>&1

echo -ne " -> Instalando dependencias... "
apt-get update -y > /dev/null 2>&1
apt-get install wget curl unzip screen net-tools iptables-persistent netfilter-persistent socat psmisc coreutils -y > /dev/null 2>&1
echo -e "${G}OK${N}"

echo -ne " -> Creando directorios... "
mkdir -p "$DIR_MOD" "$DIR_TOOL" "$DIR_BASE/assets"
rm -f /usr/bin/menu
echo -e "${G}OK${N}"

# --- 5. LIMPIEZA ---
msg_inst "Limpiando sistema anterior"
systemctl disable --now udp-custom > /dev/null 2>&1
systemctl disable --now hysteria > /dev/null 2>&1
systemctl stop squid > /dev/null 2>&1

kill_safe "badvpn-bin"; kill_safe "proxy.py"; kill_safe "stunnel4"; kill_safe "dnstt-server"
kill_safe "udp-server"; kill_safe "hysteria-server"; kill_safe "limitador_ssh"
echo -e " -> Limpieza completada."

# --- 6. DESCARGAS ---
msg_inst "Instalando Panel CARC 3LT"

descargar "$REPO/menu" "/usr/bin/menu" "Panel Principal"

modulos=("ssh-manager" "protocols" "badvpn" "badvpn-bin" "dropbear" "websockets" "squid" "slowdns" "dnstt-server" "udp-custom" "udp-server" "hysteria" "hysteria-server")
for mod in "${modulos[@]}"; do
    descargar "$REPO/modules/$mod" "$DIR_MOD/$mod" "$mod"
done

herramientas=("rootpass" "firewall" "install-3xui")
for tool in "${herramientas[@]}"; do
    descargar "$REPO/tools/$tool" "$DIR_TOOL/$tool" "$tool"
done

# --- ASSETS ---
descargar "$REPO/assets/CheckUser" "$DIR_BASE/assets/CheckUser" "CheckUser API"
wget -q -O "$DIR_BASE/squid_error.html" "$REPO/modules/squid_error.html" && chmod 644 "$DIR_BASE/squid_error.html"

# --- 7. FIN ---
echo -e "\n${P}======================================================${N}"
echo -e "      ${G}✅ INSTALACIÓN COMPLETADA EXITOSAMENTE${N}"
echo -e "      ${W}Escribe ${Y}menu ${W}para iniciar.${N}"
echo -e "${P}======================================================${N}"

rm -f install.sh

echo -e " ${Y}Entrando al sistema...${N}"
cd /root
exec sudo su -