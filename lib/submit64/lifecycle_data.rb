module Submit64
  
  class LifecycleData

    def resync(**attrs)
      attrs.each do |key, value|
        if value.nil?
          next
        end
        method_name = "#{key}="
        if self.respond_to? method_name
          self.public_send(method_name, value)
        end
      end
    end
    
    private
    def initialize
    end

  end


  class OnMetadataData < LifecycleData
      attr_accessor :form,
                    :resource_data

      def self.from
        instance = self.new()
        instance
      end
  end

  class OnAssociationData < LifecycleData
    attr_accessor :limit,
                  :offset,
                  :from_class,
                  :association_class,
                  :rows,
                  :row_count


    def self.from(limit, offset, from_class, association_class)
      instance = self.new()
      instance.limit = limit
      instance.offset = offset
      instance.from_class = from_class
      instance.association_class = association_class
      instance
    end
  end

  class OnSubmitData < LifecycleData
    attr_accessor :resource_instance,
                  :resource_id,
                  :edit_mode,
                  :request_params,
                  :form,
                  :skip_validation,
                  :success,
                  :error_messages,
                  :unlink_fields,
                  :attachments

    def self.from(resource_instance, edit_mode, request_params, form, unlink_fields)
      instance = self.new()
      instance.resource_instance = resource_instance
      instance.edit_mode = edit_mode
      instance.request_params = request_params
      instance.form = form
      instance.unlink_fields = unlink_fields
      instance
    end

  end

end
