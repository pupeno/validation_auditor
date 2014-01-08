# encoding: UTF-8
# Copyright © 2014, Watu

require_relative "test_helper"

class ModelTest < ActiveSupport::TestCase
  should "not create a validation audit when no errors occurs" do
    assert_difference "ValidationAuditor::ValidationAudit.count" => 0 do
      AuditedRecord.create!(name: "John Doe", email: "john.doe@example.com")
    end
  end

  should "create a validation audit when an errors occur for a new record" do
    assert_difference "ValidationAuditor::ValidationAudit.count" => +1 do
      AuditedRecord.create(name: "John Doe") # Missing email.
    end
    audit = ValidationAuditor::ValidationAudit.order(:id).last
    assert_nil audit.record # New records cannot be referenced because they don't exist...
    assert_equal "AuditedRecord", audit.record_type # but we still record the name.
    assert_equal audit.data["name"], "John Doe"
    assert_nil audit.data["email"]
    assert_equal ["can't be blank"], audit.failures[:email]
  end

  should "create a validation audit when an errors occur for an existing record" do
    audited_record = AuditedRecord.create!(name: "John Doe", email: "john.doe@example.com")
    assert_difference "ValidationAuditor::ValidationAudit.count" => +1 do
      audited_record.name = "John Smith"
      audited_record.email = nil # Missing email.
      audited_record.save
    end
    audit = ValidationAuditor::ValidationAudit.order(:id).last
    assert_equal audited_record, audit.record
    assert_equal audit.data["name"], "John Smith"
    assert_nil audit.data["email"]
    assert_equal ["can't be blank"], audit.failures[:email]
  end

  should "not create a validation audit when no errors occurs for an existing record" do
    audited_record = AuditedRecord.create!(name: "John Doe", email: "john.doe@example.com")
    assert_difference "ValidationAuditor::ValidationAudit.count" => 0 do
      audited_record.name = "John Smith"
      audited_record.email = "john.smith@example.com"
      audited_record.save!
    end
  end

  should "not create a validation audit for non audited models" do
    assert_difference "ValidationAuditor::ValidationAudit.count" => 0 do
      NonAuditedRecord.create(name: "John Doe") # Missing email.
    end
  end
end




