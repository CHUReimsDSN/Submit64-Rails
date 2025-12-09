module Submit64

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

end