import json
import socket
import logging
import requests
from core.config import settings
from circuitbreaker import circuit, CircuitBreaker

logger = logging.getLogger(__name__)

class SIEMService:
    def __init__(self):
        self.enabled = settings.SIEM_ENABLED
        self.siem_type = settings.SIEM_TYPE
        self.hec_url = settings.SIEM_HEC_URL
        self.hec_token = settings.SIEM_HEC_TOKEN
        self.syslog_host = settings.SIEM_SYSLOG_HOST
        self.syslog_port = settings.SIEM_SYSLOG_PORT

    @circuit(failure_threshold=settings.CIRCUIT_BREAKER_FAIL_MAX, recovery_timeout=settings.CIRCUIT_BREAKER_RESET_TIMEOUT)
    def send_log(self, log_data: dict):
        if not self.enabled:
            return
        try:
            if self.siem_type == "splunk":
                self._send_splunk_hec(log_data)
            elif self.siem_type == "qradar":
                self._send_qradar_syslog(log_data)
        except Exception as e:
            logger.error(f"SIEM export failed: {e}")
            raise

    def _send_splunk_hec(self, log_data: dict):
        headers = {"Authorization": f"Splunk {self.hec_token}"}
        payload = {"event": log_data, "sourcetype": "spymanager_audit", "time": log_data.get("timestamp")}
        resp = requests.post(f"{self.hec_url}/services/collector", json=payload, headers=headers, timeout=5)
        resp.raise_for_status()

    def _send_qradar_syslog(self, log_data: dict):
        priority = 134  # local0.info
        timestamp = log_data.get("timestamp", "")
        message = json.dumps(log_data)
        syslog_msg = f"<{priority}>1 {timestamp} spymanager audit - {message}"
        with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
            s.settimeout(5)
            s.connect((self.syslog_host, self.syslog_port))
            s.sendall(syslog_msg.encode())

siem_service = SIEMService()
