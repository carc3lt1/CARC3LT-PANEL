from flask import Flask, request, jsonify
import subprocess
import datetime
import os

app = Flask(__name__)

# Rutas para Certbot (Actualizadas por el script de Bash)
CERT_FILE = '/etc/letsencrypt/live/DOMAIN_PLACEHOLDER/fullchain.pem'
KEY_FILE = '/etc/letsencrypt/live/DOMAIN_PLACEHOLDER/privkey.pem'

def get_days_remaining(username):
    try:
        # Extrae la fecha de expiración configurada por tu panel
        chage_out = subprocess.check_output(f"chage -l {username}", shell=True).decode()
        for line in chage_out.split('\n'):
            if "Account expires" in line or "La cuenta caduca" in line:
                expire_date_str = line.split(":")[1].strip()
                if expire_date_str in ["never", "nunca"]: return 999
                # Formato de fecha para el cálculo
                expire_date = datetime.datetime.strptime(expire_date_str, "%b %d, %Y")
                return max(0, (expire_date - datetime.datetime.now()).days)
    except: return 0

def get_online_connections(username):
    try:
        # Lógica de conteo de procesos SSH/Dropbear
        cmd = f"ps -u {username} | grep -E 'sshd|dropbear' | grep -v 'ptmx' | wc -l"
        return int(subprocess.check_output(cmd, shell=True).decode().strip())
    except: return 0

@app.route('/checkUser', methods=['GET'])
def check():
    user = request.args.get('user')
    if not user: return jsonify({"error": "no user"}), 400
    
    online = get_online_connections(user)
    days = get_days_remaining(user)
    
    # Formato JSON para la App
    return jsonify({
        "username": user,
        "online": online,
        "expiry": days,
        "status": "active" if days > 0 else "expired"
    })

if __name__ == '__main__':
    if os.path.exists(CERT_FILE):
        app.run(host='0.0.0.0', port=2095, ssl_context=(CERT_FILE, KEY_FILE))
    else:
        app.run(host='0.0.0.0', port=2095)