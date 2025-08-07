require 'active_record'

module Submit64
        
  module MetadataProvider
    def self.extended(base)
      unless base < ActiveRecord::Base
        raise "#{base} must inherit from ActiveRecord::Base to extend Submit64::MetadataProvider"
      end
    end

    def submit64_get_form_metadata_and_data(context = nil)
      unless self < ActiveRecord::Base
        raise "Method must be called from ActiveRecord::Base inherited class"
      end

      # First sructuration
      form_metadata = {
        sections: [],
        use_model_validations: true,
        has_global_custom_validation: false
      }
      if self.respond_to?(:submit64_form_builder)
        method_column_builder = self.method(:submit64_form_builder)
        if method_column_builder.parameters.any?
          form_metadata = method_column_builder.call(context)
        else
          form_metadata = method_column_builder.call
        end
      end
      if context.nil?
        context = {}
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
          if !self.columns_hash[field_map[:target].to_s].nil?
            field_type = self.submit64_get_column_type_by_sql_type(columns_hash[field_map[:target].to_s].type)
            form_field_type = self.submit64_get_form_field_type_by_column_name(field_map, field_type)
            form_rules = self.submit64_get_column_rules(field_map, field_type, form_metadata, context[:name])
            form_select_options = self.submit64_get_column_select_options(field_map, field_map[:target])
            {
              field_name: field_map[:target],
              form_field_type: form_field_type,
              form_label: field_map[:label],
              form_hint: field_map[:hint],
              form_rules: form_rules,
              form_select_options: form_select_options,
              form_css_class: field_map[:css_class],
            }
          else
            # TODO association select
            {}
          end
        end
        {
          fields: fields,
          label: section_map[:label],
          icon: section_map[:icon],
          css_class: section_map[:css_class]
        }
      end

      return form_metadata
      # TODO get data
    end

    private
    def submit64_get_resource_data(form_metadata)
      # TODO get resource data, only the field from metadata
    end

    def submit64_get_column_type_by_sql_type(sql_type)
      field_type = 'string'
      case sql_type
        when :text
          field_type = 'text'
        when :integer
          field_type = 'number'
        when :datetime
          field_type = 'date'
        when :boolean
          field_type = 'boolean'
        when :jsonb
          field_type = 'object'
      end
      field_type.to_sym
    end

    def submit64_get_form_field_type_by_column_name(field, field_type)
      association = self.reflect_on_association(field[:target])
      if association.nil?
        case field_type.to_s
        when "text"
          return "text"
        when "string"
          return "string"
        when "number"
          return "number"
        when "date"
          return "date"
        when "boolean"
          return "checkbox"
        when "object"
          return "object"
        else
          return "string"
        end
      end
      case association.class.to_s.demodulize
      when "BelongsToReflection"
        return "selectBelongsto"
      when "HasManyReflection"
        return "selectHasMany"
      end
    end

    def submit64_get_column_rules(field, field_type, form, context_name)
      now = Time.now
      rules = []

      if !form[:use_model_validations] || field[:ignore_validation]
        return rules
      end

      if !self.reflect_on_association(field[:target]).nil?
        # TODO required sur les belongs_to
        return rules
      end

      self.validators_on(field[:target]).each do |validator|       
        is_value_symbol_and_column = -> (value) { return value.class == Symbol && resource_class.column_names.include?(value.to_s) }
        is_value_class_not_proc = -> (value) { return value.class != Proc }
        is_value_class_array = -> (value) { return value.class == Array }

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
              case [operator_key, field_type, value_symbol_and_column, value_class_not_proc]
                in [:greater_than, 'number', true, false]
                  rules << { type: 'greaterThanNumber', compare_to: operator_value.to_s }
                in [:greater_than, 'number', false, true]
                  rules << { type: 'greaterThanNumber', greater_than: operator_value.to_i }
                in [:greater_than, 'date', true, false]
                  rules << { type: 'greaterThanDate', compare_to: operator_value.to_s }
                in [:greater_than, 'date', false, true]
                  rules << { type: 'greaterThanDate', greater_than: operator_value.to_i }

                in [:greater_than_or_equal_to, 'number', true, false]
                  rules << { type: 'greaterThanOrEqualNumber', compare_to: operator_value.to_s }
                in [:greater_than_or_equal_to, 'number', false, true]
                  rules << { type: 'greaterThanOrEqualNumber', greater_than: operator_value.to_i }
                in [:greater_than_or_equal_to, 'date', true, false]
                  rules << { type: 'greaterThanOrEqualDate', compare_to: operator_value.to_s }
                in [:greater_than_or_equal_to, 'date', false, true]
                  rules << { type: 'greaterThanOrEqualDate', greater_than: operator_value.to_i }

                in [:equal_to, 'number', true, false]
                  rules << { type: 'equalToNumber', compare_to: operator_value.to_s }
                in [:equal_to, 'number', false, true]
                  rules << { type: 'equalToNumber', greater_than: operator_value.to_i }
                in [:equal_to, 'date', true, false]
                  rules << { type: 'equalToDate', compare_to: operator_value.to_s }
                in [:equal_to, 'date', false, true]
                  rules << { type: 'equalToDate', greater_than: operator_value.to_i }

                in [:less_than, 'number', true, false]
                  rules << { type: 'lessThanNumber', compare_to: operator_value.to_s }
                in [:less_than, 'number', false, true]
                  rules << { type: 'lessThanNumber', greater_than: operator_value.to_i }
                in [:less_than, 'date', true, false]
                  rules << { type: 'lessThanDate', compare_to: operator_value.to_s }
                in [:less_than, 'date', false, true]
                  rules << { type: 'lessThanDate', greater_than: operator_value.to_i }

                in [:less_than_or_equal_to, 'number', true, false]
                  rules << { type: 'lessThanOrEqualNumber', compare_to: operator_value.to_s }
                in [:less_than_or_equal_to, 'number', false, true]
                  rules << { type: 'lessThanOrEqualNumber', greater_than: operator_value.to_i }
                in [:less_than_or_equal_to, 'date', true, false]
                  rules << { type: 'lessThanOrEqualDate', compare_to: operator_value.to_s }
                in [:less_than_or_equal_to, 'date', false, true]
                  rules << { type: 'lessThanOrEqualDate', greater_than: operator_value.to_i }

                in [:other_than, 'number', true, false]
                  rules << { type: 'otherThanNumber', compare_to: operator_value.to_s }
                in [:other_than, 'number', false, true]
                  rules << { type: 'otherThanNumber', greater_than: operator_value.to_i }
                in [:other_than, 'date', true, false]
                  rules << { type: 'otherThanDate', compare_to: operator_value.to_s }
                in [:other_than, 'date', false, true]
                  rules << { type: 'otherThanDate', greater_than: operator_value.to_i }

                in [_, _, false, false]
                  rules << { type: 'backend', backend_hint: "Contrainte métier"}
              end
            end

          when "FormatValidator"
            # TODO à voir à l'avenir ?
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
        end
      end
      puts now - Time.now
      return rules
    end

    def submit64_get_column_select_options(field_def, column_name)
      if !field_def[:select_options].nil? && !field_def[:select_options].empty?
        if field_def[:select_options].first.class == 'string'
          return field_def[:select_options].map do |select_option_map|
            return {
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
          return {
            label: enum_key_map,
            value: enum_key_map
          }          
        end
      end

      return []
    end

  end

end
