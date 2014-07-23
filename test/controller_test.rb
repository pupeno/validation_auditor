# encoding: UTF-8
# Copyright © 2014, Watu

require_relative "test_helper"

# Controller setup
class AuditedRecordsController < ActionController::Base
  audit_validation_errors

  def create
    @audited_record = AuditedRecord.create(audited_record_params)
    render text: ""
  end

  def update
    @audited_record = AuditedRecord.find(params[:id])
    @audited_record.update_attributes(audited_record_params)
    render text: ""
  end

  private

  def audited_record_params
    if params.respond_to?(:permit) # strong_parameters is present.
      params.require(:audited_record).permit(:name, :email)
    else
      params[:audited_record]
    end
  end
end

class ControllerTest < ActionController::TestCase
  setup do
    @controller = AuditedRecordsController.new
    @request = ActionController::TestRequest.new
    @response = ActionController::TestResponse.new
    @routes = ActionDispatch::Routing::RouteSet.new
    @routes.draw { resources :audited_records }
    AuditedRecordsController.send(:include, @routes.url_helpers)
  end

  should "clean params" do
    cleaned_params = ValidationAuditor::Controller.clean_params({name: "John Doe", deep: {structure: {with: {file: ActionDispatch::Http::UploadedFile.new(tempfile: Tempfile.new("test.txt"))}}}})
    assert_equal "John Doe", cleaned_params[:name]
    assert cleaned_params[:deep][:structure][:with][:file].is_a? String
  end

  should "not create a validation audit due to no validation failing when creating a new record" do
    assert_difference "ValidationAuditor::ValidationAudit.count" => 0 do
      post :create, audited_record: {name: "John Doe", email: "john.doe@example.com"}
    end
  end

  should "create a validation audit when creating a new record" do
    assert_difference "ValidationAuditor::ValidationAudit.count" => +1 do
      post :create, audited_record: {name: "John Doe"} # Missing email
    end
    audit = ValidationAuditor::ValidationAudit.order(:id).last
    assert_nil audit.record # New records cannot be referenced because they don't exist...
    assert_equal "AuditedRecord", audit.record_type # but we still record the name.
    assert_equal audit.data["name"], "John Doe"
    assert_nil audit.data["email"]
    assert_equal ["can't be blank"], audit.failures[:email]
  end

  should "create a validation audit even when an uploaded file is in the params" do
    assert_difference "ValidationAuditor::ValidationAudit.count" => +1 do
      post :create, audited_record: {name: "John Doe"}, deep: {structure: {with: {file: ActionDispatch::Http::UploadedFile.new(tempfile: Tempfile.new("test.txt"))}}} # Missing email and a deep structure with a file in it.
    end
    audit = ValidationAuditor::ValidationAudit.order(:id).last
    assert_nil audit.record # New records cannot be referenced because they don't exist...
    assert_equal "AuditedRecord", audit.record_type # but we still record the name.
    assert_equal audit.data["name"], "John Doe"
    assert_nil audit.data["email"]
    assert_equal ["can't be blank"], audit.failures[:email]
  end

  context "With a record" do
    setup do
      @audited_record = AuditedRecord.create(name: "John Doe", email: "john.doe@example.com")
    end

    should "not create a validation audit due to no validation failing when updating an existing record" do
      assert_difference "ValidationAuditor::ValidationAudit.count" => 0 do
        put :update, id: @audited_record.id, audited_record: {name: "John Smith", email: "john.smith@example.com"}
      end
    end

    should "create a validation audit due to no validation failing when updating an existing record" do
      assert_difference "ValidationAuditor::ValidationAudit.count" => +1 do
        put :update, id: @audited_record.id, audited_record: {name: "John Smith", email: ""} # Missing email
      end
      @audited_record.reload
      audit = ValidationAuditor::ValidationAudit.order(:id).last
      assert_equal @audited_record, audit.record
      assert_equal audit.data["name"], "John Smith"
      assert audit.data["email"].blank?
      assert_equal ["can't be blank"], audit.failures[:email]
      assert_equal audit.params, @request.params
    end
  end
end
