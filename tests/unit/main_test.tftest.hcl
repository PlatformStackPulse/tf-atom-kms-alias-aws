# Unit Tests for tf-atom-kms-alias-aws
#
# These tests use a mock AWS provider — no real AWS calls are made.
# Run with:         terraform test -test-directory=tests/unit
# Run verbose:      terraform test -test-directory=tests/unit -verbose
# Run specific:     terraform test -test-directory=tests/unit -run "creates_when_enabled"
#
# Assertions target PLAN-KNOWN values only (the tf-label id string, resource
# count, input pass-throughs). Computed attributes such as the alias ARN are
# unknown under a mock provider and are therefore NOT asserted here.

mock_provider "aws" {}

variables {
  # tf-label context
  namespace = "eg"
  stage     = "test"
  name      = "thing"

  # Module-specific required input
  target_key_id = "arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012"
}

# ---------------------------------------------------------------------------
# Test: Module creates the alias when enabled (default)
# ---------------------------------------------------------------------------
run "creates_when_enabled" {
  command = plan

  assert {
    condition     = module.this.id == "eg-test-thing"
    error_message = "tf-label id should be 'eg-test-thing' for namespace=eg stage=test name=thing"
  }

  assert {
    condition     = length(aws_kms_alias.this) == 1
    error_message = "Exactly one aws_kms_alias should be planned when enabled"
  }

  assert {
    condition     = aws_kms_alias.this[0].name == "alias/eg-test-thing"
    error_message = "Alias name should be derived from the tf-label id"
  }

  assert {
    condition     = output.enabled == true
    error_message = "enabled output should be true by default"
  }
}

# ---------------------------------------------------------------------------
# Test: Alias targets the supplied key id (input pass-through)
# ---------------------------------------------------------------------------
run "targets_supplied_key" {
  command = plan

  assert {
    condition     = aws_kms_alias.this[0].target_key_id == var.target_key_id
    error_message = "target_key_id should be passed through to the alias resource"
  }
}

# ---------------------------------------------------------------------------
# Test: Disabled module creates nothing
# ---------------------------------------------------------------------------
run "disabled_creates_nothing" {
  command = plan

  variables {
    enabled = false
  }

  assert {
    condition     = length(aws_kms_alias.this) == 0
    error_message = "No aws_kms_alias should be planned when enabled = false"
  }

  assert {
    condition     = output.alias_arn == null
    error_message = "alias_arn output should be null when the module is disabled"
  }

  assert {
    condition     = output.enabled == false
    error_message = "enabled output should be false when enabled = false"
  }
}
