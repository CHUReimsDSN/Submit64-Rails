module Submit64

  class OnSubmitData < LifecycleData
      attr_accessor :resource_instance,
                    :resource_id,
                    :edit_mode,
                    :bulk_mode,
                    :request_params,
                    :form,
                    :skip_validation,
                    :success,
                    :error_messages,
                    :bulk_data,

      def self.from(resource_instance, edit_mode, bulk_mode, request_params, form)
        instance = self.new()
        instance.resource_instance = resource_instance
        instance.edit_mode = edit_mode
        instance.bulk_mode = bulk_mode
        instance.request_params = request_params
        instance.form = form
        instance
      end
 
  end

end