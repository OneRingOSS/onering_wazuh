#!/usr/bin/env python3
"""
Mock AI-SOC Endpoint for Wave 3 Integration Testing

This script creates a simple HTTP server that mimics the AI-SOC webhook endpoint.
It receives POST requests from Wazuh's shuffle integration and validates them
according to the Wazuh-Webhook-Payload-Spec.md specification.

Usage:
    python3 mock_ai_soc_endpoint.py [port]

Default port: 8000
"""

import json
import sys
from http.server import HTTPServer, BaseHTTPRequestHandler
from datetime import datetime
import threading
import signal
import uuid

# Global variables
received_alerts = []
server_running = False
shutdown_event = threading.Event()

# Required fields per spec
REQUIRED_FIELDS = [
    'id', 'timestamp', 'location', 'full_log', 'rule',
    'agent', 'manager', 'decoder', 'data'
]

REQUIRED_RULE_FIELDS = ['id', 'level', 'description', 'groups', 'firedtimes']
REQUIRED_AGENT_FIELDS = ['id', 'name']
REQUIRED_MANAGER_FIELDS = ['name']
REQUIRED_DECODER_FIELDS = ['name']
REQUIRED_DATA_FIELDS = ['package_name']


class MockAISOCHandler(BaseHTTPRequestHandler):
    """HTTP request handler for mock AI-SOC endpoint"""

    def log_message(self, format, *args):
        """Override to customize logging"""
        timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        sys.stderr.write(f"[{timestamp}] {format % args}\n")

    def validate_alert(self, alert):
        """Validate alert payload according to spec"""
        # Check top-level required fields
        for field in REQUIRED_FIELDS:
            if field not in alert:
                return False, f"Missing required field: {field}"

        # Validate rule object
        rule = alert.get('rule', {})
        for field in REQUIRED_RULE_FIELDS:
            if field not in rule:
                return False, f"Missing required field: rule.{field}"

        # Validate rule.id must be "100006" for Wave 1
        if rule.get('id') != "100006":
            return False, f"Wave 1 Wazuh ingestion only supports rule.id=100006"

        # Validate rule.level is integer
        if not isinstance(rule.get('level'), int):
            return False, f"rule.level must be integer, got {type(rule.get('level')).__name__}"

        # Validate agent object
        agent = alert.get('agent', {})
        for field in REQUIRED_AGENT_FIELDS:
            if field not in agent:
                return False, f"Missing required field: agent.{field}"

        # Validate manager object
        manager = alert.get('manager', {})
        for field in REQUIRED_MANAGER_FIELDS:
            if field not in manager:
                return False, f"Missing required field: manager.{field}"

        # Validate decoder object
        decoder = alert.get('decoder', {})
        for field in REQUIRED_DECODER_FIELDS:
            if field not in decoder:
                return False, f"Missing required field: decoder.{field}"

        # Validate data object
        data = alert.get('data', {})
        for field in REQUIRED_DATA_FIELDS:
            if field not in data:
                return False, f"Missing required field: data.{field}"

        return True, None

    def extract_endpoint_name(self, full_log):
        """Extract endpoint name from full_log"""
        if ':' in full_log:
            endpoint = full_log.split(':', 1)[0].strip()
            # Reject if contains spaces
            if ' ' not in endpoint:
                return endpoint
        return None

    def create_threat_signal_response(self, alert):
        """Create ThreatSignal response per spec"""
        rule = alert['rule']
        data = alert['data']
        endpoint_name = self.extract_endpoint_name(alert['full_log'])

        # Map severity
        level = rule['level']
        if level >= 15:
            severity = "CRITICAL"
        elif level >= 12:
            severity = "HIGH"
        elif level >= 8:
            severity = "MEDIUM"
        else:
            severity = "LOW"

        # Parse groups (can be array or comma-separated string)
        groups = rule['groups']
        if isinstance(groups, str):
            groups = [g.strip() for g in groups.split(',')]

        return {
            "id": f"threat_{uuid.uuid4().hex[:16]}",
            "threat_type": "device_compromise",
            "customer_name": "SeniorFraudShield",
            "timestamp": alert['timestamp'],
            "metadata": {
                "external_alert_id": alert['id'],
                "rule_id": rule['id'],
                "wazuh_rule_level": rule['level'],
                "initial_severity_hint": severity,
                "alert_summary": rule['description'],
                "rule_groups": groups,
                "repeat_count": rule['firedtimes'],
                "wazuh_agent_id": alert['agent']['id'],
                "wazuh_agent_name": alert['agent']['name'],
                "wazuh_manager_name": alert['manager']['name'],
                "decoder_name": alert['decoder']['name'],
                "package_name": data['package_name'],
                "source_ip": alert['location'],
                "wazuh_location": alert['location'],
                "endpoint_name": endpoint_name,
                "log_message": alert['full_log']
            }
        }

    def do_POST(self):
        """Handle POST requests from Wazuh integration"""
        if self.path == '/api/threats/ingest/wazuh':
            content_length = int(self.headers.get('Content-Length', 0))
            post_data = self.rfile.read(content_length)

            try:
                # Parse the JSON alert
                alert = json.loads(post_data.decode('utf-8'))

                # Validate the alert
                valid, error_msg = self.validate_alert(alert)

                if not valid:
                    # Return 422 Unprocessable Entity
                    print(f"❌ Invalid alert: {error_msg}")
                    self.send_response(422)
                    self.send_header('Content-Type', 'application/json')
                    self.end_headers()
                    error_response = {
                        'detail': {
                            'message': error_msg
                        }
                    }
                    self.wfile.write(json.dumps(error_response).encode('utf-8'))
                    return

                # Create ThreatSignal response
                threat_signal = self.create_threat_signal_response(alert)

                # Store the alert
                received_alerts.append({
                    'timestamp': datetime.now().isoformat(),
                    'alert': alert,
                    'threat_signal': threat_signal
                })

                # Log receipt
                rule_id = alert['rule']['id']
                package_name = alert['data']['package_name']

                print(f"✅ Alert received: rule_id={rule_id}, package={package_name}")
                print(f"   Total alerts received: {len(received_alerts)}")

                # Send 202 Accepted response per spec
                self.send_response(202)
                self.send_header('Content-Type', 'application/json')
                self.end_headers()
                self.wfile.write(json.dumps(threat_signal, indent=2).encode('utf-8'))

            except json.JSONDecodeError as e:
                print(f"❌ Invalid JSON received: {e}")
                self.send_response(422)
                self.send_header('Content-Type', 'application/json')
                self.end_headers()
                error_response = {
                    'detail': {
                        'message': 'Invalid Wazuh alert payload'
                    }
                }
                self.wfile.write(json.dumps(error_response).encode('utf-8'))

        else:
            # Unknown endpoint
            self.send_response(404)
            self.send_header('Content-Type', 'application/json')
            self.end_headers()
            error_response = {'status': 'error', 'message': 'Endpoint not found'}
            self.wfile.write(json.dumps(error_response).encode('utf-8'))

    def do_GET(self):
        """Handle GET requests for health check and status"""
        if self.path == '/health':
            self.send_response(200)
            self.send_header('Content-Type', 'application/json')
            self.end_headers()
            response = {
                'status': 'healthy',
                'alerts_received': len(received_alerts)
            }
            self.wfile.write(json.dumps(response).encode('utf-8'))
            
        elif self.path == '/alerts':
            # Return all received alerts
            self.send_response(200)
            self.send_header('Content-Type', 'application/json')
            self.end_headers()
            response = {
                'count': len(received_alerts),
                'alerts': received_alerts
            }
            self.wfile.write(json.dumps(response, indent=2).encode('utf-8'))
            
        else:
            self.send_response(404)
            self.send_header('Content-Type', 'application/json')
            self.end_headers()
            error_response = {'status': 'error', 'message': 'Endpoint not found'}
            self.wfile.write(json.dumps(error_response).encode('utf-8'))


def run_server(port=8000):
    """Start the mock AI-SOC server"""
    global server_running
    
    server_address = ('', port)
    httpd = HTTPServer(server_address, MockAISOCHandler)
    
    print(f"🚀 Mock AI-SOC endpoint starting on port {port}")
    print(f"   Webhook URL: http://localhost:{port}/api/threats/ingest/wazuh")
    print(f"   Health check: http://localhost:{port}/health")
    print(f"   View alerts: http://localhost:{port}/alerts")
    print(f"   Press Ctrl+C to stop")
    print()
    
    server_running = True
    
    # Handle shutdown gracefully
    def signal_handler(sig, frame):
        global server_running
        print("\n🛑 Shutting down mock AI-SOC endpoint...")
        print(f"   Total alerts received: {len(received_alerts)}")
        server_running = False
        httpd.shutdown()
        shutdown_event.set()
    
    signal.signal(signal.SIGINT, signal_handler)
    signal.signal(signal.SIGTERM, signal_handler)
    
    # Start server
    httpd.serve_forever()


if __name__ == '__main__':
    port = 8000
    if len(sys.argv) > 1:
        try:
            port = int(sys.argv[1])
        except ValueError:
            print(f"Invalid port: {sys.argv[1]}")
            sys.exit(1)
    
    run_server(port)

