require 'active_record'

module Submit64
        
  module MetadataProvider
    def self.extended(base)
      unless base < ActiveRecord::Base
        raise "#{base} must inherit from ActiveRecord::Base to extend Submit64::MetadataProvider"
      end
    end

    def submit64_get_form_metadata_and_data(request_params)
      unless self < ActiveRecord::Base
        raise "Method must be called from ActiveRecord::Base inherited class"
      end
      context = request_params[:context]
      if context != nil
        context = context.to_h
      else
        context = {}
      end

      # First sructuration
      default_form_metadata = {
        sections: [],
        use_model_validations: true,
        has_global_custom_validation: false,
        backend_date_format: 'YYYY-MM-DD',
        bakcend_datetime_format: 'YYYY-MM-DDTHH:MM:SSZ',
        resource_name: self.to_s,
        css_class: ''
      }
      if self.respond_to?(:submit64_form_builder)
        method_column_builder = self.method(:submit64_form_builder)
        if method_column_builder.parameters.any?
          form_metadata = method_column_builder.call(context)
        else
          form_metadata = method_column_builder.call
        end
      end
      if form_metadata.nil?
        form_metadata = default_form_metadata
      else
        form_metadata = default_form_metadata.merge(form_metadata)
      end

      # Filters
      section_index_to_purge = []
      form_metadata[:sections].each_with_index do |section, index_section|
        if section[:policy]
          result_section_policy = section[:policy].call(Submit64.current_user)
          if !result_section_policy
            section_index_to_purge << index_section
            next
          end
        end
        field_index_to_purge = []
        section[:fields].each_with_index do |field, index_field|
          if field[:policy]
            result_field_policy = field[:policy].call(Submit64.current_user)
            if !result_field_policy
              field_index_to_purge << index_field
              next
            end
          end
          if !field[:target].nil?
            if self.columns_hash[field[:target].to_s].nil? && self.reflect_on_association(field[:target]).nil?
              field_index_to_purge << index_field              
            end
          else
            field_index_to_purge << index_field
          end
        end
        section[:fields] = section[:fields].select do |field, index_field|
          field_index_to_purge.exclude?(index_field)
        end
      end
      form_metadata[:sections] = form_metadata[:sections].select do |section, index_section|
        section_index_to_purge.exclude?(index_section) && section[:fields].count > 0
      end

      # Projection
      form_metadata[:sections] = form_metadata[:sections].map do |section_map|
        fields = section_map[:fields].map do |field_map|
          association = self.reflect_on_association(field_map[:target])
          if association.nil?
            field_type = self.submit64_get_column_type_by_sgbd_type(columns_hash[field_map[:target].to_s].type)
            form_field_type = self.submit64_get_form_field_type_by_column_type(field_type)
            form_rules = self.submit64_get_column_rules(field_map, field_type, form_metadata, context[:name])
            form_select_options = self.submit64_get_column_select_options(field_map, field_map[:target])
            field_name = field_map[:target]
            field_association_name = nil
            field_association_class = nil
          else
            field_name =  association.foreign_key
            form_field_type = self.submit64_get_form_field_type_by_association(association)
            field_type = self.submit64_get_column_type_by_sgbd_type(columns_hash[field_name.to_s].type)
            form_rules = self.submit64_get_column_rules(field_map, field_type, form_metadata, context[:name])
            form_select_options = self.submit64_get_column_select_options(field_map, field_map[:target])
            field_association_name = association.name
            field_association_class = association.klass.to_s
          end
            {
              field_name: field_name,
              field_type: form_field_type,
              label: field_map[:label] || self.submit64_beautify_target(field_map[:target]),
              field_association_name: field_association_name,
              field_association_class: field_association_class,
              hint: field_map[:hint],
              rules: form_rules,
              select_options: form_select_options,
              css_class: field_map[:css_class],
            }
        end
        {
          fields: fields,
          label: section_map[:label],
          icon: section_map[:icon],
          css_class: section_map[:css_class]
        }
      end

      return {
        form: form_metadata,
        resource_data: submit64_get_resource_data(form_metadata, request_params)
      }
    end

    def submit64_get_association_data(request_params)     
      unless self < ActiveRecord::Base
        raise "Method must be called from ActiveRecord::Base inherited class"
      end 
      context = request_params[:context]
      if context != nil
        context = context.to_h
      else
        context = {}
      end
      association = self.reflect_on_association(request_params[:associationName])
      if association.nil?
        raise Submit64Exception.new("Association not found : #{request_params[:associationName]}", 400)
      end

      association_class = association.klass
      default_limit = Submit64.get_association_data_pagination_limit
      limit = request_params[:limit] || default_limit
      if limit > default_limit
        limit = default_limit
      end
      offset = request_params[:offset] || 0
      builder_rows = association_class.all
      if self.respond_to?(:submit64_association_filter_rows)
        filter_row_method = self.method(:submit64_association_filter_rows)
        if filter_row_method.parameters.any?
          builder_rows = filter_row_method.call(context)
        else
          builder_rows = filter_row_method.call
        end
      end
      label_filter = request_params[:labelFilter]
      if !label_filter.empty?
        # TODO debug, returning empty list
        columns_filter = [:label]
        if self.respond_to?(:submit64_association_filter_columns)
          filter_column_method = self.method(:submit64_association_filter_columns)
          if filter_column_method.parameters.any?
            columns_filter = filter_column_method.call(context)
          else
            columns_filter = filter_column_method.call
          end
        end
        label_filter_builder = builder_rows.none
        columns_filter.each do |column_filter|
          if self.columns_hash[column_filter.to_s].nil?
            next
          end
          builder_statement = self.where("#{column_filter.to_s} ILIKE ?", label_filter)
          label_filter_builder = label_filter_builder.or(builder_statement)
        end
        builder_rows = builder_rows.and(label_filter_builder)
      end
      builder_row_count = builder_rows.count
      builder_rows = builder_rows.limit(limit).offset(offset).map do |row|
        label = submit64_association_default_label(row)
        if row.respond_to?(:submit64_association_label)
          label_method = row.method(:submit64_association_label)
          if label_method.parameters.any?
            label = row.method(:submit64_association_label).call(context)
          else
            label = row.method(:submit64_association_label).call
          end
        end
        {
          label: label,
          value: row[self.primary_key.to_sym]
        }
      end

      return {
        rows: builder_rows,
        row_count: builder_row_count
      }
    end

    private
    def submit64_get_resource_data(form_metadata, request_params)
      # TODO get resource data, only the field from metadata?
      self.find(request_params[:resourceId])
    end

    def submit64_get_column_type_by_sgbd_type(sql_type)
      field_type = 'string'
      case sql_type
        when :text
          field_type = 'text'
        when :integer
          field_type = 'number'
        when :date
          field_type = 'date'
        when :datetime
          field_type = 'datetime'
        when :boolean
          field_type = 'boolean'
        when :jsonb
          field_type = 'object'
      end
      field_type.to_sym
    end

    def submit64_get_form_field_type_by_column_type(column_type)
      case column_type.to_s
      when "text"
        return "text"
      when "string"
        return "string"
      when "number"
        return "number"
      when "date"
        return "date"
      when "datetime"
        return "datetime"
      when "boolean"
        return "checkbox"
      when "object"
        return "object"
      else
        return "string"
      end
    end

    def submit64_get_form_field_type_by_association(association)
      case association.class.to_s.demodulize
      when "BelongsToReflection"
        return "selectBelongsTo"
      when "HasManyReflection"
        return "selectHasMany"
      # TODO more case like trought ?
      else
        return "???"
      end
    end

    def submit64_get_column_rules(field, field_type, form, context_name)
      rules = []

      if !form[:use_model_validations] || field[:ignore_validation]
        return rules
      end

      if !self.reflect_on_association(field[:target]).nil?
        # TODO required sur les belongs_to
        return rules
      end

      is_value_symbol_and_column = -> (value) { return value.class == Symbol && column_names.include?(value.to_s) }
      is_value_class_not_proc = -> (value) { return value.class != Proc }
      is_value_class_array = -> (value) { return value.class == Array }
      get_date_to_iso_8601 = -> (value) { return value.as_json }
      self.validators_on(field[:target]).each do |validator|       
        validator_context = validator.options[:on]
        if !validator_context.nil? && validator_context != context_name
          next
        end

        if validator.options[:if].present? || validator.options[:unless].present?
          rules << { type: "backend", backend_hint: "Contrainte conditionnelle" }
          next
        end

        if validator.options[:allow_nil].present?
          rules << { type: 'allowNull' }
        end

        if validator.options[:allow_blank].present?
          rules <  { type: 'allowBlank' }
        end

        case validator.class.name.demodulize
          when "AbsenceValidator"
            rules << { type: "absence" }

          when "AcceptanceValidator"
            rules <<  { type: "acceptance" }

          when "ConfirmationValidator"
            next # useless, too much MVC-ish, use comarison instead

          when "ComparisonValidator"
            operators = [:greater_than, :greater_than_or_equal_to, :equal_to, :less_than, :less_than_or_equal_to, :other_than]
            operators.each do |operator_key|
              operator_value = validator.options[operator_key]
              if (operator_value.nil?)
                next
              end
              value_symbol_and_column = is_value_symbol_and_column.call(validator.options[operator_key])
              value_class_not_proc = is_value_class_not_proc.call(validator.options[operator_key])
              case [operator_key, field_type.to_s, value_symbol_and_column, value_class_not_proc]
                in [:greater_than, 'number', true, false]
                  rules << { type: 'greaterThanNumber', compare_to: operator_value.to_s }
                in [:greater_than, 'number', false, true]
                  rules << { type: 'greaterThanNumber', greater_than: operator_value.to_i }
                in [:greater_than, 'date', true, true]
                  rules << { type: 'greaterThanDate', compare_to: operator_value.to_s }
                in [:greater_than, 'date', false, true]
                  rules << { type: 'greaterThanDate', greater_than: get_date_to_iso_8601.call(operator_value) }

                in [:greater_than_or_equal_to, 'number', true, false]
                  rules << { type: 'greaterThanOrEqualNumber', compare_to: operator_value.to_s }
                in [:greater_than_or_equal_to, 'number', false, true]
                  rules << { type: 'greaterThanOrEqualNumber', greater_than: operator_value.to_i }
                in [:greater_than_or_equal_to, 'date', true, true]
                  rules << { type: 'greaterThanOrEqualDate', compare_to: operator_value.to_s }
                in [:greater_than_or_equal_to, 'date', false, true]
                  rules << { type: 'greaterThanOrEqualDate', greater_than: get_date_to_iso_8601.call(operator_value) }

                in [:equal_to, 'number', true, false]
                  rules << { type: 'equalToNumber', compare_to: operator_value.to_s }
                in [:equal_to, 'number', false, true]
                  rules << { type: 'equalToNumber', greater_than: operator_value.to_i }
                in [:equal_to, 'date', true, true]
                  rules << { type: 'equalToDate', compare_to: operator_value.to_s }
                in [:equal_to, 'date', false, true]
                  rules << { type: 'equalToDate', greater_than: get_date_to_iso_8601.call(operator_value) }

                in [:less_than, 'number', true, false]
                  rules << { type: 'lessThanNumber', compare_to: operator_value.to_s }
                in [:less_than, 'number', false, true]
                  rules << { type: 'lessThanNumber', greater_than: operator_value.to_i }
                in [:less_than, 'date', true, true]
                  rules << { type: 'lessThanDate', compare_to: operator_value.to_s }
                in [:less_than, 'date', false, true]
                  rules << { type: 'lessThanDate', greater_than: get_date_to_iso_8601.call(operator_value) }

                in [:less_than_or_equal_to, 'number', true, false]
                  rules << { type: 'lessThanOrEqualNumber', compare_to: operator_value.to_s }
                in [:less_than_or_equal_to, 'number', false, true]
                  rules << { type: 'lessThanOrEqualNumber', greater_than: operator_value.to_i }
                in [:less_than_or_equal_to, 'date', true, true]
                  rules << { type: 'lessThanOrEqualDate', compare_to: operator_value.to_s }
                in [:less_than_or_equal_to, 'date', false, true]
                  rules << { type: 'lessThanOrEqualDate', greater_than: get_date_to_iso_8601.call(operator_value) }

                in [:other_than, 'number', true, false]
                  rules << { type: 'otherThanNumber', compare_to: operator_value.to_s }
                in [:other_than, 'number', false, true]
                  rules << { type: 'otherThanNumber', greater_than: operator_value.to_i }
                in [:other_than, 'date', true, true]
                  rules << { type: 'otherThanDate', compare_to: operator_value.to_s }
                in [:other_than, 'date', false, true]
                  rules << { type: 'otherThanDate', greater_than: get_date_to_iso_8601.call(operator_value) }

              end
            end

          when "FormatValidator"
            rules << { type: "backend", backend_hint: "Contrainte d'expression régulière" }

          when "InclusionValidator"
            if is_value_class_array
              rules << { type: 'inclusion', including: validator.options[:in]}
            else
              rules << { type: "backend", backend_hint: "Contrainte d'inclusion" }
            end

          when "ExclusionValidator"
            if is_value_class_array
              rules << { type: 'exclusion', including: validator.options[:in]}
            else
              rules << { type: "backend", backend_hint: "Contrainte d'exclusion" }
            end
          
          when "LengthValidator"
            operators = [:minimum, :maximum, :is] # :in is getting parsed into min and max
            operators.each do |operator_key|
              operator_value = validator.options[operator_key]
              if operator_value.nil?
                next
              end
              case operator_key
              when :minimum
                  rules << { type: 'greaterThanOrEqualStringLength', greater_than: operator_value.to_i }
              when :maximum
                  rules << { type: 'lessThanOrEqualStringLength', less_than: operator_value.to_i}
              when :is
                  rules << { type: 'equalToStringLength', equal_to: operator_value.to_i}
              end
            end

          when "NumericalityValidator"
            operators = [:only_integer, :only_numeric, :greater_than, :greater_than_or_equal_to, :equal_to, :less_than, :less_than_or_equal_to, :other_than, :minimum, :maximum, :odd, :even]
            operators.each do |operator_key|
              operator_value = validator.options[operator_key]
              if (operator_value.nil? || operator_value == false)
                next
              end
              case operator_key
              when :only_integer
                  rules << { type: 'numberIntegerOnly' }
              when :only_numeric
                  rules << { type: 'numberNumericOnly' }
              when :greater_than
                  rules << { type: 'greaterThanNumber', greater_than: operator_value.to_i }
              when :greater_than_or_equal_to
                  rules << { type: 'greaterThanOrEqualNumber', greater_than: operator_value.to_i }
              when :equal_to
                  rules << { type: 'equalToNumber', equal_to: operator_value.to_i }
              when :less_than
                  rules << { type: 'lessThanNumber', less_than: operator_value.to_i }
              when :less_than_or_equal_to
                  rules << { type: 'lessThanOrEqualNumber', less_than: operator_value.to_i }
              when :other_than
                  rules << { type: 'otherThanNumber', less_than: operator_value.to_i }
              when :in
                  rules << { type: 'greaterThanOrEqualNumber', greater_than: operator_value.to_i }
                  rules << { type: 'lessThanOrEqualNumber', less_than: operator_value.to_i }
              when :odd
                  rules << { type: 'numberOddOnly', less_than: operator_value.to_i }
              when :even
                  rules << { type: 'numberEvenOnly', less_than: operator_value.to_i }
              end
            end

          when "PresenceValidator"
            rules << { type: 'required' }

          when "UniquenessValidator"
            rules << { type: "backend", backend_hint: "Contrainte d'unicité" }

          when "BlockValidator"
            rules << { type: "backend", backend_hint: "Contrainte spécifique" }
          else
            next
        end
      end
      return rules
    end

    def submit64_get_column_select_options(field_def, column_name)
      if !field_def[:select_options].nil? && !field_def[:select_options].empty?
        if field_def[:select_options].first.class == 'string'
          return field_def[:select_options].map do |select_option_map|
            {
              label: select_option_map,
              value: select_option_map,
            }
          end
        else
          return field_def[:select_options]
        end
      end

      defined_enum = self.defined_enums[column_name.to_s]
      if !defined_enum.nil?
        return defined_enum.keys.map do |enum_key_map|
          {
            label: enum_key_map,
            value: enum_key_map
          }          
        end
      end

      return []
    end

    def submit64_beautify_target(target)
      return target.to_s.capitalize.gsub('_', ' ')
    end

    def submit64_association_default_label(row)
      if row.respond_to?(:label)
        return row.method(:label).call
      end
      if row.respond_to?(:to_string)
        return row.method(:to_string).call
      end
      if row.respond_to?(:to_s)
        return row.method(:to_s).call
      end
      return row.method(self.primary_key.to_sym).call
    end

  end

end
