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
                    :unlink_fields

      def self.from(resource_instance, edit_mode, bulk_mode, request_params, form, unlink_fields)
        instance = self.new()
        instance.resource_instance = resource_instance
        instance.edit_mode = edit_mode
        instance.bulk_mode = bulk_mode
        instance.request_params = request_params
        instance.form = form
        instance.unlink_fields = unlink_fields
        instance
      end
 
  end

end