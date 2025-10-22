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
        cursor.execute("SELECT NOW(), VERSION()")
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
