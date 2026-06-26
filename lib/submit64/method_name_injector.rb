module Submit64
  
  class MethodNameInjector

    attr_reader :lifecycle_events,
                :association_select_columns,
                :association_filter_rows,
                :association_filter_columns,
                :association_label,
                :form_builder

    def initialize(method_definition=nil)
        definition = get_default_definition
        if method_definition != nil && method_definition.class == Hash
            definition = definition.merge(method_definition)
        end
        @lifecycle_events = definition[:lifecycle_events]
        @association_select_columns = definition[:association_select_columns]
        @association_filter_rows = definition[:association_filter_rows]
        @association_filter_columns = definition[:association_filter_columns]
        @association_label = definition[:association_label]
        @form_builder = definition[:form_builder]
    end

    def get_default_definition
        {
            lifecycle_events: :submit64_lifecycle_events,
            association_select_columns: :submit64_association_select_columns,
            association_filter_rows: :submit64_association_filter_rows,
            association_filter_columns: :submit64_association_filter_columns,
            association_label: :submit64_association_label,
            form_builder: :submit64_form_builder
        }
    end

  end

end
