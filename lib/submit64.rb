# frozen_string_literal: true

require_relative "submit64/metadata_provider"
require_relative "submit64/parameters"
require_relative "submit64/submit64_exception"
require_relative "submit64/utils"
require_relative "submit64/version"

module Submit64

  def self.get_metadata_and_data(params)
    safe_exec do
      resource_class = ensure_params_and_resource_are_valid(params)
      request_params = params[:submit64Params]
      resource_class.submit64_get_form_metadata_and_data(request_params)
    end
  end

  def self.get_association_data(params)
    safe_exec do
      resource_class = ensure_params_and_resource_are_valid(params)
      request_params = params[:submit64Params]
      resource_class.submit64_get_association_data(request_params)
    end
  end

  def self.submit_form(params)
    safe_exec do
      resource_class = ensure_params_and_resource_are_valid(params)
      request_params = params[:submit64Params]
      resource_class.submit64_get_submit_data(request_params)
    end
  end

  def self.ensure_params_and_resource_are_valid(params)
    if !params[:submit64Params]
      raise Submit64Exception.new("Invalid params", 400)
    end
    resource_name = params[:submit64Params][:resourceName]
    begin
      resource_class = resource_name.constantize
    rescue Exception
      raise Submit64Exception.new("This resource does not exist : #{resource_name}", 400)
    end
    if !resource_class.singleton_class.ancestors.include?(Submit64::MetadataProvider)
      raise Submit64Exception.new("This resource does not extend Submit64 : #{resource_name}", 400)
    end
    resource_class
  end

  private

  def self.safe_exec
    begin
      yield
    rescue => e
      if e.class == Submit64Exception
        http_status = e.http_status
      else
        http_status = 500
      end
      exception = Submit64Exception.new_with_prefix("An error has occured : #{e}", http_status)
      exception.set_backtrace(e.backtrace)
      raise exception
    end
  end

end
