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

    # If available, add controller data to this validation audit. This will include:
    # - params
    # - url
    # - user_agent
    #
    # @see ValidationAuditor::Controller::ClassMethods#audit_validation_errors
    def add_controller
      if ValidationAuditor::Controller.request.present?
        request = ValidationAuditor::Controller.request
        self.params = ValidationAuditor::Controller.clean_params(request.filtered_parameters)
        self.url = request.url
        self.user_agent = request.env["HTTP_USER_AGENT"]
      end
    end
  end

  # Controller side of audit validations.
  #
  # @see ValidationAuditor::Controller::ClassMethods#audit_validation_errors
  module Controller
    extend ActiveSupport::Concern

    # Class methods accessible in controllers (classes inheriting from ActionController::Base).
    module ClassMethods
      # Enable validation audits for this controller. This is not essential to be able to audit validations, but it
      # enhances the reports with:
      # - params
      # - url
      # - user_agent
      #
      # For example:
      #
      #   class BlogsController < ApplicationController
      #     audit_validation_errors
      #   end
      #
      # @see ValidationAuditor::Model::ClassMethods#audit_validation_errors
      def audit_validation_errors
        before_filter :make_request_auditable
      end
    end

    private

    # Make the request available for later adding some of its details to the validation audit. This method is
    # automatically called as before_filter when you enable validation audits for a controller.
    #
    # @see ValidationAuditor::Controller::ClassMethods#audit_validation_errors
    def make_request_auditable
      Thread.current[:validation_auditor_request] = self.request
    end

    # Getter for the request for the audit.
    #
    # @see ValidationAuditor::Controller::ClassMethods#audit_validation_errors
    def self.request
      Thread.current[:validation_auditor_request]
    end

    # Clean parameters before storing them in the database.
    #
    # This method gets sure we don't have unserializable values, like UploadedFiles.
    # @param param [Hash] Hash of params as created by Rails
    # @return [Hash] A hash without those problematic values.
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

  # Model side of audit validations.
  #
  # @see ValidationAuditor::Model::ClassMethods#audit_validation_errors
  module Model
    extend ActiveSupport::Concern

    # Class methods accessible in models (classes inheriting from ActiveRecord::Base).
    module ClassMethods
      # Enable validation audits for a model. For example:
      #
      #   class Blog < ActiveRecord::Base
      #     audit_validation_errors
      #   end
      #
      # @see ValidationAuditor::Controller::ClassMethods#audit_validation_errors
      def audit_validation_errors
        after_rollback :audit_validation
      end
    end

    private

    # Perform the actual audit validation. This method is automatically called on rollback when you enable validation on
    # a model.
    #
    # @see ValidationAuditor::Model::ClassMethods#audit_validation_errors
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
