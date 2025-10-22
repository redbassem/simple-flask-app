# On LOCAL MACHINE - Create the app files
cd ~/Projects/simple-flask-app

# Create app.py
cat > app.py << 'EOF'
from flask import Flask, render_template, jsonify
import mysql.connector
import socket
import psutil
import platform
from datetime import datetime

app = Flask(__name__)

# Database configuration - Ansible will set the actual password
DB_CONFIG = {
    'host': 'localhost',
    'user': 'showcase_user',
    'password': 'SecureDBPassword123!',
    'database': 'showcase_db'
}

def get_db_connection():
    return mysql.connector.connect(**DB_CONFIG)

@app.route('/')
def index():
    return render_template('index.html')

@app.route('/health')
def health_check():
    """Endpoint to verify all components are working"""
    health_data = {
        'status': 'healthy',
        'timestamp': datetime.now().isoformat(),
        'components': {}
    }
    
    # Check database
    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        cursor.execute("SELECT NOW() as current_time, VERSION() as mysql_version")
        result = cursor.fetchone()
        health_data['components']['database'] = {
            'status': 'connected',
            'mysql_time': str(result[0]),
            'version': result[1]
        }
        cursor.close()
        conn.close()
    except Exception as e:
        health_data['components']['database'] = {'status': 'error', 'error': str(e)}
        health_data['status'] = 'degraded'

    # System info
    health_data['system'] = {
        'hostname': socket.gethostname(),
        'platform': platform.platform(),
        'cpu_usage': psutil.cpu_percent(interval=1),
        'memory_usage': psutil.virtual_memory().percent,
        'disk_usage': psutil.disk_usage('/').percent
    }
    
    return jsonify(health_data)

@app.route('/metrics')
def metrics():
    """Endpoint for Prometheus-style metrics"""
    metrics_data = []
    
    # System metrics
    metrics_data.append(f"system_cpu_usage{{host=\"{socket.gethostname()}\"}} {psutil.cpu_percent(interval=1)}")
    metrics_data.append(f"system_memory_usage{{host=\"{socket.gethostname()}\"}} {psutil.virtual_memory().percent}")
    metrics_data.append(f"system_disk_usage{{host=\"{socket.gethostname()}\"}} {psutil.disk_usage('/').percent}")
    
    return "\n".join(metrics_data), 200, {'Content-Type': 'text/plain'}

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8000)
EOF

# Create requirements.txt
cat > requirements.txt << 'EOF'
Flask==2.3.3
mysql-connector-python==8.1.0
psutil==5.9.5
gunicorn==21.2.0
EOF

# Create templates directory and index.html
mkdir templates
cat > templates/index.html << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>Linux System Engineer Showcase</title>
    <style>
        body { font-family: Arial, sans-serif; max-width: 800px; margin: 40px auto; padding: 20px; }
        .status { padding: 15px; border-radius: 5px; margin: 20px 0; }
        .healthy { background: #d4edda; border: 1px solid #c3e6cb; }
        .endpoint { margin: 10px 0; padding: 10px; background: #f8f9fa; border-left: 4px solid #007bff; }
    </style>
</head>
<body>
    <h1>🚀 Linux System Engineer Showcase</h1>
    <p>This demonstrates a fully automated infrastructure stack deployed via Ansible.</p>
    
    <div class="status healthy">
        <strong>Stack Status: Operational</strong>
        <p>All components managed via Ansible automation</p>
    </div>
    
    <div class="endpoints">
        <h3>Test Endpoints:</h3>
        <div class="endpoint">
            <strong><a href="/health">/health</a></strong> - Full system health check (DB connection, system metrics)
        </div>
        <div class="endpoint">
            <strong><a href="/metrics">/metrics</a></strong> - Prometheus-style metrics endpoint
        </div>
    </div>
    
    <div class="tech-stack">
        <h3>Technologies Demonstrated:</h3>
        <ul>
            <li>✅ Ubuntu 22.04 (Hardened)</li>
            <li>✅ Nginx Reverse Proxy</li>
            <li>✅ MariaDB Database</li>
            <li>✅ Flask/Gunicorn App Server</li>
            <li>✅ Ansible Automation</li>
            <li>✅ Prometheus Node Exporter</li>
            <li>✅ Grafana Dashboard</li>
            <li>✅ Security Hardening</li>
        </ul>
    </div>
</body>
</html>
EOF
