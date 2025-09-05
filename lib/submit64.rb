# frozen_string_literal: true

require_relative "submit64/metadata_provider"
require_relative "submit64/parameters"
require_relative "submit64/submit64_exception"
require_relative "submit64/utils"
require_relative "submit64/version"

module Submit64

  def self.get_metadata_and_data(params)
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
    request_params = params[:submit64Params]
    resource_class.submit64_get_form_metadata_and_data(request_params)
  end

  def self.get_association_data(params)
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
    request_params = params[:submit64Params]
    resource_class.submit64_get_association_data(request_params)
  end

  def self.submit_form(params)
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
    request_params = params[:submit64Params]
    resource_class.submit64_get_submit_data(request_params)
  end

end
