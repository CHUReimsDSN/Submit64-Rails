module Submit64

  class OnMetadataData < LifecycleData
      attr_accessor :form,
                    :resource_data

      def self.from
        instance = self.new()
        instance
      end
 
  end

end