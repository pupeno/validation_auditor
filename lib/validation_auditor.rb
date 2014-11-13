# encoding: UTF-8
# Copyright © 2012, 2013, 2014, Watu

require "validation_auditor/version"
require "active_record"
require "action_controller"

module ValidationAuditor
  mattr_accessor :exception_handler

  class ValidationAudit < ActiveRecord::Base
    belongs_to :record, :polymorphic => true

    serialize :failures, Hash
    serialize :failure_messages, Array
    serialize :data, Hash
    serialize :params, Hash

    if respond_to? :attr_accessible # For Rails < 4 or Rails >= 4 with attr_accessible added by a third party library.
      begin
        attr_accessible
      rescue RuntimeError # Rails 4 raises a RuntimeError when you call attr_accessible, but we still want to call it in case you added attr_accessible gem.
      end
    end

    def add_controller
      if ValidationAuditor::Controller.request.present?
        request = ValidationAuditor::Controller.request
        self.params = ValidationAuditor::Controller.clean_params(request.filtered_parameters)
        self.url = request.url
        self.user_agent = request.env["HTTP_USER_AGENT"]
      end
    end
  end

  module Controller
    extend ActiveSupport::Concern

    module ClassMethods
      def audit_validation_errors
        before_filter :make_request_auditable
      end
    end

    private

    def make_request_auditable
      Thread.current[:validation_auditor_request] = self.request
    end

    def self.request
      Thread.current[:validation_auditor_request]
    end

    # Clean parameters before storing them in the database.
    def self.clean_params(param)
      if param.is_a? Hash
        cleaned_params = {}
        param.each do |k, v|
          cleaned_params[k] = clean_params(v) # clean each value
        end
        cleaned_params
      elsif param.is_a? Array
        param.map { |v| clean_params(v) } # clean each value
      elsif param.is_a? ActionDispatch::Http::UploadedFile
        param.inspect # UploadedFiles cannot be yaml-serialized, so, we replace them with a string.
      else
        param
      end
    end
  end

  module Model
    extend ActiveSupport::Concern

    module ClassMethods
      def audit_validation_errors
        after_rollback :audit_validation
      end
    end

    private

    def audit_validation
      return if errors.empty? # We don't use :valid? to avoid re-running validations
      validatio_audit = ValidationAudit.new
      validatio_audit.failures = self.errors.to_hash
      validatio_audit.failure_messages = self.errors.full_messages.to_a
      validatio_audit.data = self.attributes
      if self.new_record? # For new records
        validatio_audit.record_type = self.class.name # we only store the class's name.
      else
        validatio_audit.record = self
      end
      validatio_audit.add_controller
      validatio_audit.save!
    rescue Exception => e
      if ValidationAuditor.exception_handler.nil?
        raise # If there's no exception handler, just re-raise the exception.
      else
        ValidationAuditor.exception_handler.call(e, validatio_audit)
      end
    end
  end
end

ActionController::Base.send(:include, ValidationAuditor::Controller)
ActiveRecord::Base.send(:include, ValidationAuditor::Model)
