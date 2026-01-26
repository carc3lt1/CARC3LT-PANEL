from flask import Flask, request, jsonify
import subprocess
import datetime
import os

app = Flask(__name__)

# Rutas SSL (Se actualizan solas con el script bash)
CERT_FILE = '/etc/letsencrypt/live/DOMAIN_PLACE_HOLDER/fullchain.pem'
KEY_FILE = '/etc/letsencrypt/live/DOMAIN_PLACE_HOLDER/privkey.pem'

def find_real_user(query):
    """
    Busca el usuario real en el sistema.
    1. Primero intenta buscar por nombre de usuario (Token o User).
    2. Si falla, busca dentro de los comentarios (Nombre del Cliente).
    """
    try:
        # Intento 1: Busqueda directa
        subprocess.check_output(f"id '{query}'", shell=True, stderr=subprocess.DEVNULL)
        return query
    except:
        pass

    try:
        # Intento 2: Busqueda por Alias (Comentario)
        # Lee el archivo de usuarios para encontrar si el 'query' es el nombre de un cliente
        with open('/etc/passwd', 'r') as f:
            for line in f:
                parts = line.strip().split(':')
                if len(parts) > 4:
                    real_user = parts[0]       # Este es el Token/User del sistema
                    comment = parts[4].split(',')[0] # Este es el Nombre del Cliente
                    if query == comment:
                        return real_user
    except:
        pass
    
    return None

def get_days_remaining(username):
    try:
        real_user = find_real_user(username)
        if not real_user: return 0

        chage_out = subprocess.check_output(f"chage -l {real_user}", shell=True).decode()
        for line in chage_out.split('\n'):
            if "Account expires" in line or "La cuenta caduca" in line:
                expire_date_str = line.split(":")[1].strip()
                if expire_date_str in ["never", "nunca"]: return 999
                expire_date = datetime.datetime.strptime(expire_date_str, "%b %d, %Y")
                return max(0, (expire_date - datetime.datetime.now()).days)
    except: return 0

def get_online_connections(username):
    try:
        real_user = find_real_user(username)
        if not real_user: return 0
        
        cmd = f"ps -u {real_user} | grep -E 'sshd|dropbear' | grep -v 'ptmx' | wc -l"
        return int(subprocess.check_output(cmd, shell=True).decode().strip())
    except: return 0

@app.route('/checkUser', methods=['GET'])
def check():
    user = request.args.get('user')
    if not user: return jsonify({"error": "no user"}), 400
    
    online = get_online_connections(user)
    days = get_days_remaining(user)
    
    status = "active" if days > 0 else "expired"
    if days == 0 and online == 0: status = "expired"

    return jsonify({
        "username": user,
        "online": online,
        "expiry": days,
        "status": status
    })

if __name__ == '__main__':
    if os.path.exists(CERT_FILE):
        app.run(host='0.0.0.0', port=2095, ssl_context=(CERT_FILE, KEY_FILE))
    else:
        app.run(host='0.0.0.0', port=2095)