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
    context = params[:query64Params][:context]
    if context != nil
      context = context.to_h
    end
    resource_class.submit64_get_form_metadata_and_data(context)
  end

  def self.submit_form(params)
    # TODO
  end

  def self.todo
    # TODO paginated resource for select association ?
  end

end
