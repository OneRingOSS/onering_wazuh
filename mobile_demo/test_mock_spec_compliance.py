#!/usr/bin/env python3
"""
Test Mock AI-SOC Endpoint Spec Compliance

This script tests the mock endpoint against the Wazuh-Webhook-Payload-Spec.md
"""

import json
import requests
import sys

# Sample Wazuh alert (from actual Wazuh output)
VALID_ALERT = {
    "timestamp": "2026-03-21T21:17:27.771+0000",
    "rule": {
        "level": 15,
        "description": "Malicious Android app installed: com.test.spec",
        "id": "100006",
        "firedtimes": 1,
        "mail": True,
        "groups": ["android", "package", "installandroid_install"]
    },
    "agent": {"id": "000", "name": "wazuh.manager"},
    "manager": {"name": "wazuh.manager"},
    "id": "1774127847.484",
    "full_log": "emulator-5554: D/BackupManagerService( 1198): Received broadcast Intent { act=android.intent.action.PACKAGE_ADDED dat=package:com.test.spec flg=0x4000010 (has extras) }",
    "decoder": {"name": "android_decoder_03"},
    "data": {"package_name": "com.test.spec"},
    "location": "192.168.65.1"
}

# Invalid alert (wrong rule ID)
INVALID_RULE_ALERT = {
    **VALID_ALERT,
    "rule": {**VALID_ALERT["rule"], "id": "999999"}
}

# Invalid alert (missing required field)
MISSING_FIELD_ALERT = {
    k: v for k, v in VALID_ALERT.items() if k != "data"
}

# Invalid alert (wrong type for rule.level)
WRONG_TYPE_ALERT = {
    **VALID_ALERT,
    "rule": {**VALID_ALERT["rule"], "level": "15"}  # String instead of int
}

def test_valid_alert():
    """Test 1: Valid alert should return 202 Accepted"""
    print("Test 1: Valid Alert Acceptance")
    print("-" * 40)
    
    response = requests.post(
        "http://localhost:8000/api/threats/ingest/wazuh",
        json=VALID_ALERT,
        headers={"Content-Type": "application/json"}
    )
    
    print(f"  Status Code: {response.status_code}")
    assert response.status_code == 202, f"Expected 202, got {response.status_code}"
    
    data = response.json()
    print(f"  Response Keys: {list(data.keys())}")
    
    # Verify ThreatSignal structure
    assert "id" in data, "Missing 'id' in response"
    assert "threat_type" in data, "Missing 'threat_type' in response"
    assert data["threat_type"] == "device_compromise", f"Wrong threat_type: {data['threat_type']}"
    assert data["customer_name"] == "SeniorFraudShield", f"Wrong customer_name: {data['customer_name']}"
    assert "metadata" in data, "Missing 'metadata' in response"
    
    # Verify metadata
    metadata = data["metadata"]
    assert metadata["rule_id"] == "100006", f"Wrong rule_id: {metadata['rule_id']}"
    assert metadata["wazuh_rule_level"] == 15, f"Wrong wazuh_rule_level: {metadata['wazuh_rule_level']}"
    assert metadata["package_name"] == "com.test.spec", f"Wrong package_name: {metadata['package_name']}"
    assert metadata["source_ip"] == "192.168.65.1", f"Wrong source_ip: {metadata['source_ip']}"
    assert metadata["endpoint_name"] == "emulator-5554", f"Wrong endpoint_name: {metadata['endpoint_name']}"
    
    print("  ✅ PASS: Valid alert accepted with correct ThreatSignal response\n")

def test_invalid_rule():
    """Test 2: Invalid rule ID should return 422"""
    print("Test 2: Unsupported Rule Rejection")
    print("-" * 40)
    
    response = requests.post(
        "http://localhost:8000/api/threats/ingest/wazuh",
        json=INVALID_RULE_ALERT,
        headers={"Content-Type": "application/json"}
    )
    
    print(f"  Status Code: {response.status_code}")
    assert response.status_code == 422, f"Expected 422, got {response.status_code}"
    
    data = response.json()
    assert "detail" in data, "Missing 'detail' in error response"
    assert "message" in data["detail"], "Missing 'message' in detail"
    assert "100006" in data["detail"]["message"], "Error message should mention rule 100006"
    
    print(f"  Error Message: {data['detail']['message']}")
    print("  ✅ PASS: Invalid rule rejected with 422\n")

def test_missing_field():
    """Test 3: Missing required field should return 422"""
    print("Test 3: Missing Required Field Rejection")
    print("-" * 40)
    
    response = requests.post(
        "http://localhost:8000/api/threats/ingest/wazuh",
        json=MISSING_FIELD_ALERT,
        headers={"Content-Type": "application/json"}
    )
    
    print(f"  Status Code: {response.status_code}")
    assert response.status_code == 422, f"Expected 422, got {response.status_code}"
    
    data = response.json()
    assert "detail" in data, "Missing 'detail' in error response"
    print(f"  Error Message: {data['detail']['message']}")
    print("  ✅ PASS: Missing field rejected with 422\n")

def test_wrong_type():
    """Test 4: Wrong field type should return 422"""
    print("Test 4: Wrong Field Type Rejection")
    print("-" * 40)
    
    response = requests.post(
        "http://localhost:8000/api/threats/ingest/wazuh",
        json=WRONG_TYPE_ALERT,
        headers={"Content-Type": "application/json"}
    )
    
    print(f"  Status Code: {response.status_code}")
    assert response.status_code == 422, f"Expected 422, got {response.status_code}"
    
    data = response.json()
    print(f"  Error Message: {data['detail']['message']}")
    print("  ✅ PASS: Wrong type rejected with 422\n")

if __name__ == "__main__":
    print("=" * 50)
    print("Mock AI-SOC Endpoint Spec Compliance Tests")
    print("=" * 50)
    print()
    
    try:
        test_valid_alert()
        test_invalid_rule()
        test_missing_field()
        test_wrong_type()
        
        print("=" * 50)
        print("✅ ALL TESTS PASSED!")
        print("=" * 50)
        sys.exit(0)
        
    except AssertionError as e:
        print(f"\n❌ TEST FAILED: {e}")
        sys.exit(1)
    except requests.exceptions.ConnectionError:
        print("\n❌ ERROR: Could not connect to mock endpoint")
        print("   Make sure the mock endpoint is running on port 8000")
        sys.exit(1)

