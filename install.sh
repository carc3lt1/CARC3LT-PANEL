#!/bin/bash
# 🚀 INSTALADOR CARC 3LT V.2.0_Final - DUAL UDP SUPPORT 🚀
# ---------------------------------------------------------
if [ "$(id -u)" -ne 0 ]; then
  echo "📢 Elevando permisos a ROOT para iniciar instalación limpia..."
  sudo bash "$0" "$@"
  exit
fi

REPO="https://raw.githubusercontent.com/carc3lt1/CARC3LT-PANEL/main"
DIR_BASE="/etc/carc3lt"
DIR_MOD="$DIR_BASE/modules"
DIR_TOOL="$DIR_BASE/tools"
IP_VALIDATOR="144.24.181.165" # Tu servidor Python que envía el aviso

# Colores
P='\033[1;35m'; C='\033[1;36m'; W='\033[1;37m'; G='\033[1;32m'; Y='\033[1;33m'; R='\033[1;31m'; N='\033[0m'

# --- 1. PREVENCIÓN DE ERRORES ---
MY_PID=$$

kill_safe() {
    local pattern=$1
    pids=$(pgrep -f "$pattern" | grep -v "$MY_PID" | grep -v "grep" | grep -v "bash" | grep -v "sudo" | grep -v "install")
    if [[ -n "$pids" ]]; then
        echo -ne "    - Forzando cierre de $pattern... "
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
        if [[ "$name" == *"server"* ]]; then
             echo -e "    ${Y}(Verifica que el archivo esté en tu GitHub)${N}"
        fi
    fi
}

# --- INICIO ---
clear
echo -e "${P}======================================================${N}"
echo -e "      ${W}🚀 INSTALADOR OFICIAL CARC 3LT V.2.0 🚀${N}"
echo -e "${P}======================================================${N}"

# --- 2. REPARACIÓN CRÍTICA DE RED ---
echo -ne " ${Y}[*] Asegurando conectividad (DNS Fix)... ${N}"
chattr -i /etc/resolv.conf > /dev/null 2>&1
echo -e "nameserver 8.8.8.8\nnameserver 1.1.1.1" > /etc/resolv.conf
echo -e "${G}OK${N}"

# --- 3. VALIDACIÓN (REAL - ACTIVA EL BOT) ---
echo -ne " ${Y}Introduce tu Key de Acceso: ${N}" && read KEY
echo -e " ${C}[*] Conectando con servidor de validación...${N}"

# Obtenemos IP pública
MY_IP=$(curl -s ifconfig.me)

# Hacemos la petición REAL al servidor Python.
# Esto dispara el código de tu server.py que envía el mensaje a Telegram.
RES=$(curl -s --max-time 10 "http://${IP_VALIDATOR}:5000/validar/${KEY}/${MY_IP}")

# Verificamos respuesta (opcional: si quieres permitir instalación offline, quita el if)
if [[ "$RES" == *"AUTORIZADO"* ]] || [[ "$RES" == *"200"* ]]; then
    echo -e " ${G}✅ LICENCIA AUTORIZADA - NOTIFICACIÓN ENVIADA${N}"
    mkdir -p "$DIR_BASE" && echo "$KEY" > "$DIR_BASE/license.key"
else
    echo -e " ${R}⚠️  ADVERTENCIA: El servidor no respondió 'AUTORIZADO'${N}"
    echo -e " ${Y}   (Instalando en MODO FORZADO...)${N}" # Mantenemos tu lógica de instalar de todas formas
    mkdir -p "$DIR_BASE" && echo "$KEY" > "$DIR_BASE/license.key"
fi

# --- 4. PREPARACIÓN ---
msg_inst "Preparando Sistema"
export DEBIAN_FRONTEND=noninteractive
rm -f /var/lib/dpkg/lock* /var/lib/apt/lists/lock* >/dev/null 2>&1

echo -ne " -> Instalando dependencias básicas... "
apt-get update -y > /dev/null 2>&1
apt-get install wget curl unzip screen net-tools iptables-persistent netfilter-persistent socat psmisc coreutils -y > /dev/null 2>&1
echo -e "${G}OK${N}"

echo -ne " -> Creando directorios... "
mkdir -p "$DIR_MOD" "$DIR_TOOL" "$DIR_BASE/assets"
rm -f /usr/bin/menu
echo -e "${G}OK${N}"

# --- 5. LIMPIEZA PROFUNDA ---
msg_inst "Deteniendo Servicios Activos"
echo -ne "    - Desactivando servicios Systemd... "
systemctl disable --now udp-custom > /dev/null 2>&1
systemctl disable --now hysteria > /dev/null 2>&1
systemctl stop squid > /dev/null 2>&1
echo "OK"

kill_safe "badvpn-bin"; kill_safe "proxy.py"; kill_safe "stunnel4"; kill_safe "dnstt-server"
kill_safe "udp-server"; kill_safe "hysteria-server"; kill_safe "limitador_ssh"
echo -e " -> Limpieza completada. Archivos liberados."

# --- 6. DESCARGAS ---
msg_inst "Descargando Componentes"
descargar "$REPO/menu" "/usr/bin/menu" "Panel de Control"

modulos=("ssh-manager" "protocols" "badvpn" "badvpn-bin" "dropbear" "websockets" "squid" "slowdns" "dnstt-server" "udp-custom" "udp-server" "hysteria" "hysteria-server")
for mod in "${modulos[@]}"; do
    descargar "$REPO/modules/$mod" "$DIR_MOD/$mod" "Módulo $mod"
done

msg_inst "Descargando Herramientas"
herramientas=("rootpass" "firewall" "install-3xui")
for tool in "${herramientas[@]}"; do
    descargar "$REPO/tools/$tool" "$DIR_TOOL/$tool" "Herramienta $tool"
done

# --- ASSETS ADICIONALES ---
msg_inst "Descargando Assets Adicionales"
descargar "$REPO/assets/CheckUser" "$DIR_BASE/assets/CheckUser" "CheckUser API (Python)"
echo -ne " -> Descargando página de error para Squid... "
if wget -q --no-dns-cache -O "$DIR_BASE/squid_error.html" "$REPO/modules/squid_error.html"; then
    chmod 644 "$DIR_BASE/squid_error.html"; echo -e "${G}OK${N}"
else
    echo -e "${Y}ADVERTENCIA${N}"
fi

# --- 7. FIN ---
echo -e "\n${P}======================================================${N}"
echo -e "      ${G}✅ INSTALACIÓN COMPLETADA EXITOSAMENTE${N}"
echo -e "      ${W}Escribe ${Y}menu ${W}para iniciar.${N}"
echo -e "${P}======================================================${N}"

rm -f install.sh

echo -e " ${Y}Iniciando sesión Root permanente...${N}"
cd /root
exec sudo su -