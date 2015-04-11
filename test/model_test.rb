# encoding: UTF-8
# Copyright © 2014, 2015 Carousel Apps

require_relative "test_helper"
require "rails/version" # Required to access Rails::VERSION::MAJOR

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

  if Rails::VERSION::MAJOR >= 4 # Prior to Rails 4, it seems exceptions in after_rollback were silently swallowed: https://rails.lighthouseapp.com/projects/8994-ruby-on-rails/tickets/6064-exceptions-from-after_commit-and-after_rollback-from-observers-are-quietly-swallowed
    should "let exceptions propagate if no handler has been set up" do
      ValidationAuditor::ValidationAudit.any_instance.expects(:save!).raises(Exception, "Something went wrong saving the audit")
      assert_raises Exception do
        AuditedRecord.create(name: "John Doe")
      end
    end
  end

  should "not let exceptions propagate when a handler has been set up" do
    exception_message = "Something went wrong saving the audit"
    exception_handler_called = false
    ValidationAuditor.exception_handler = lambda do |e, va|
      assert e.is_a?(Exception)
      assert_equal e.message, exception_message
      assert va.is_a?(ValidationAuditor::ValidationAudit)
      exception_handler_called = true
    end
    ValidationAuditor::ValidationAudit.any_instance.stubs(:save!).raises(Exception, exception_message)

    AuditedRecord.create(name: "John Doe")

    assert exception_handler_called

    # teardown
    ValidationAuditor.exception_handler = nil
  end

  should "add controller information if possible" do
    params = {"hello" => "world", "universe" => "42"}
    url = "https://example.com/hello/world"
    env = {"HTTP_USER_AGENT" => "NCSA_Mosaic/2.0"}
    request = mock("request") do
      stubs(:present?).returns(true)
      stubs(:filtered_parameters).returns(params)
      stubs(:url).returns(url)
      stubs(:env).returns(env)
    end
    ValidationAuditor::Controller.stubs(:request).returns(request)
    assert_difference "ValidationAuditor::ValidationAudit.count" => +1 do
      AuditedRecord.create(name: "John Doe") # Missing email.
    end
    audit = ValidationAuditor::ValidationAudit.order(:id).last
    assert_equal params, audit.params
    assert_equal url, audit.url
    assert_equal env["HTTP_USER_AGENT"], audit.user_agent
  end
end




