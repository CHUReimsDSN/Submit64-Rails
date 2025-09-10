require 'active_record'

module Submit64

  module MetadataProvider
    def self.extended(base)
      unless base < ActiveRecord::Base
        raise Submit64Exception("#{base} must inherit from ActiveRecord::Base to extend Submit64::MetadataProvider", 400)
      end
    end

    def submit64_get_form_metadata_and_data(request_params)
      unless self < ActiveRecord::Base
        raise Submit64Exception("Method must be called from ActiveRecord::Base inherited class", 400)
      end
      context = request_params[:context]
      if context != nil
        context = context.to_h
      else
        context = {}
      end

      # First sructuration
      default_form_metadata = {
        sections: [],
        use_model_validations: true,
        has_global_custom_validation: false,
        backend_date_format: 'YYYY-MM-DD',
        backend_datetime_format: 'YYYY-MM-DDTHH:MM:SSZ',
        resource_name: self.to_s,
        css_class: ''
      }
      form_metadata = submit64_try_model_method_with_context(self, :submit64_form_builder, context)
      if form_metadata.nil?
        form_metadata = default_form_metadata
      else
        form_metadata = default_form_metadata.merge(form_metadata)
      end

      # Early projection for lazy definition
      form_metadata[:sections].each do |section_each|
        section_each[:fields] = section_each[:fields].map do |field_map|
          if field_map.class == Symbol
            {
              target: field_map
            }
          else
            field_map
          end
        end
      end

      # Filters
      section_index_to_purge = []
      form_metadata[:sections].each_with_index do |section, index_section|
        if section[:statement]
          result_section_statement = section[:statement].call(Submit64.current_user)
          if !result_section_statement
            section_index_to_purge << index_section
            next
          end
        end
        field_index_to_purge = []
        section[:fields].each_with_index do |field, index_field|
          if field[:statement]
            result_field_statement = field[:statement].call(Submit64.current_user)
            if !result_field_statement
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
        section[:fields] = section[:fields].select.with_index do |_field, index_select|
          field_index_to_purge.exclude?(index_select)
        end
      end
      form_metadata[:sections] = form_metadata[:sections].select do |section, index_section|
        section_index_to_purge.exclude?(index_section) && section[:fields].count > 0
      end

      # Projection
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
            field_name = association.foreign_key
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

      if request_params[:resourceId]
        resource_data, form_metadata = submit64_get_resource_data(form_metadata, request_params, context)
      else
        resource_data = {}
      end

      {
        form: form_metadata,
        resource_data: resource_data
      }
    end

    def submit64_get_association_data(request_params)
      unless self < ActiveRecord::Base
        raise Submit64Exception("Method must be called from ActiveRecord::Base inherited class", 400)
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
      custom_select_column = submit64_try_model_method_with_context(association_class, :submit64_association_select_columns, context)
      if custom_select_column != nil
        builder_rows = association_class.select(custom_select_column).all
      else
        builder_rows = association_class.all
      end
      custom_builder_row_filter = submit64_try_model_method_with_context(association_class, :submit64_association_filter_rows, context)
      if custom_builder_row_filter != nil
        builder_rows = builder_rows.and(custom_builder_row_filter)
      end
      label_filter = request_params[:labelFilter]
      if !label_filter.empty?
        columns_filter = [:label, :id]
        custom_columns_filter = submit64_try_model_method_with_context(association_class, :submit64_association_filter_columns, context)
        if custom_columns_filter != nil
          columns_filter = custom_columns_filter
        end
        label_filter_builder = builder_rows.none
        columns_filter.each do |column_filter|
          if association_class.columns_hash[column_filter.to_s].nil?
            next
          end
          builder_statement = association_class.where("#{association_class.table_name}.#{column_filter.to_s}::text ILIKE ?", "%#{label_filter}%")
          label_filter_builder = label_filter_builder.or(builder_statement)
        end
        builder_rows = builder_rows.and(label_filter_builder)
      end
      builder_row_count = builder_rows.count
      builder_rows = builder_rows.limit(limit).offset(offset).map do |row|
        label = submit64_association_default_label(row)
        custom_label = submit64_try_row_method_with_context(row, :submit64_association_label, context)
        if custom_label != nil
          label = custom_label
        end
        {
          label: label,
          value: row[self.primary_key.to_sym]
        }
      end

      {
        rows: builder_rows,
        row_count: builder_row_count
      }
    end

    def submit64_get_submit_data(request_params)
      unless self < ActiveRecord::Base
        raise Submit64Exception("Method must be called from ActiveRecord::Base inherited class", 400)
      end
      context = request_params[:context]
      if context != nil
        context = context.to_h
      else
        context = {}
      end
      edit_mode = request_params[:resourceId] != nil
      if !edit_mode
        resource_instance = self.new(request_params[:resourceData])
      else
        resource_instance = self.find(request_params[:resourceId])
      end
      if resource_instance.nil?
        raise Submit64Exception("Resource #{request_params[:resourceName]} with id #{request_params[:resourceId]} does not exist", 404)
      end
      resource_instance.assign_attributes(request_params[:resourceData])
      form = submit64_get_shallow_form_config(context)
      perform_validation = form[:use_model_validations] == true
      success = false
      errors = []
      resource_id = resource_instance.id || nil
      if !perform_validation || resource_instance.valid?
        resource_instance.save(validate: false) # Avoid double checks, .valid? already does it
        success = true
        resource_id = resource_instance.id
        params_for_form = {
          resourceName: request_params[:resourceName],
          resourceId: request_params[:resourceId],
          context: request_params[:context]
        }
        resource_data_renew = submit64_get_form_metadata_and_data(params_for_form)[:resource_data]
      else
        errors = resource_instance.errors.details.deep_dup

        # Replace key for belongs_to
        keys_to_rename = {}
        columns = self.column_names
        errors.keys.each do |key|
          if columns.exclude?(key.to_s)
            association = self.reflect_on_association(key)
            if association != nil && association.class.to_s.demodulize == "BelongsToReflection"
              keys_to_rename[key] = association.foreign_key.to_sym
            end
          end
        end
        keys_to_rename.each do |key_to_rename, renamed_key|
          errors[renamed_key] = errors[key_to_rename]
          errors.delete(key_to_rename)
        end

        # Project errors hash to string
        errors = errors.map do |error_key, error_value|
          error_string = error_value.map do |error_hash_map|
            error_hash_map[:error]
          end
          [error_key, error_string]
        end.to_h

      end
      {
        success: success,
        resource_id: resource_id,
        resource_data: resource_data_renew,
        errors: errors
      }
    end

    private

    def submit64_get_resource_data(form_metadata, request_params, context)
      relations_to_include = []
      columns_to_select = []
      form_metadata[:sections].each do |section|
        section[:fields].each do |field|
          if field[:field_association_name] != nil
            relations_to_include << field[:field_association_name]
          end
          columns_to_select << field[:field_name]
        end
      end
      resource_data = self.all
                          .select(columns_to_select)
                          .includes(relations_to_include)
                          .where({ self.primary_key.to_sym => request_params[:resourceId] })
                          .first

      form_metadata[:sections].each do |section|
        section[:fields].each do |field|
          relation = relations_to_include.find do |relation_name_find|
            relation_name_find == field[:field_association_name]
          end
          if relation.nil?
            next
          end
          row = resource_data.method(relation).call
          default_display_value = submit64_association_default_label(row)
          custom_display_value = submit64_try_row_method_with_context(row, :submit64_association_label, context)
          if custom_display_value != nil
            default_display_value = custom_display_value
          end
          field[:default_display_value] = default_display_value
        end
      end
      resource_data_final = resource_data.as_json
      [resource_data_final, form_metadata]
    end

    def submit64_get_column_type_by_sgbd_type(sql_type)
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
      else
        field_type = 'string'
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
        # when "HasManyReflection"
        #   return "selectHasMany"
      else
        return "???"
      end
    end

    def submit64_get_column_rules(field, field_type, form, context_name)
      rules = []

      if !form[:use_model_validations] || field[:ignore_validation]
        return rules
      end

      association = self.reflect_on_association(field[:target])
      if association != nil
        case association.class.to_s.demodulize
        when "BelongsToReflection"
          if association.options[:optional] == false
            rules << { type: 'required' }
          end
        else
          nil
        end
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
          rules < { type: 'allowBlank' }
        end

        case validator.class.name.demodulize
        when "AbsenceValidator"
          rules << { type: "absence" }

        when "AcceptanceValidator"
          rules << { type: "acceptance" }

        when "ConfirmationValidator"
          next # useless, too much MVC-ish, use comparison instead

        when "ComparisonValidator"
          operators = [:greater_than, :greater_than_or_equal_to, :equal_to, :less_than, :less_than_or_equal_to, :other_than]
          operators.each do |operator_key|
            operator_value = validator.options[operator_key]
            if operator_value.nil?
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
            else
              next
            end
          end

        when "FormatValidator"
          rules << { type: "backend", backend_hint: "Contrainte d'expression régulière" }

        when "InclusionValidator"
          if is_value_class_array
            rules << { type: 'inclusion', including: validator.options[:in] }
          else
            rules << { type: "backend", backend_hint: "Contrainte d'inclusion" }
          end

        when "ExclusionValidator"
          if is_value_class_array
            rules << { type: 'exclusion', including: validator.options[:in] }
          else
            rules << { type: "backend", backend_hint: "Contrainte d'exclusion" }
          end

        when "LengthValidator"
          operators = [:minimum, :maximum, :is] # :in is getting parsed into min and max
          operators.each do |operator_key|
            operator_value = validator.options[operator_key]
            if operator_value.nil?
              next
            end
            case operator_key
            when :minimum
              rules << { type: 'greaterThanOrEqualStringLength', greater_than: operator_value.to_i }
            when :maximum
              rules << { type: 'lessThanOrEqualStringLength', less_than: operator_value.to_i }
            when :is
              rules << { type: 'equalToStringLength', equal_to: operator_value.to_i }
            else
              nil
            end
          end

        when "NumericalityValidator"
          operators = [:only_integer, :only_numeric, :greater_than, :greater_than_or_equal_to, :equal_to, :less_than, :less_than_or_equal_to, :other_than, :minimum, :maximum, :odd, :even]
          operators.each do |operator_key|
            operator_value = validator.options[operator_key]
            if operator_value.nil? || operator_value == false
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
            else
              nil
            end
          end

        when "PresenceValidator"
          rules << { type: 'required' }

        when "UniquenessValidator"
          rules << { type: "backend", backend_hint: "Contrainte d'unicité" }

        when "BlockValidator"
          rules << { type: "backend", backend_hint: "Contrainte spécifique" }
        else
          nil
        end
      end
      rules
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

      []
    end

    def submit64_beautify_target(target)
      target.to_s.capitalize.gsub('_', ' ')
    end

    def submit64_association_default_label(row)
      if row.respond_to?(:label)
        return row.method(:label).call.to_s
      end
      if row.respond_to?(:to_string)
        return row.method(:to_string).call.to_s
      end
      if row.respond_to?(:to_s)
        return row.method(:to_s).call.to_s
      end
      row.method(self.primary_key.to_sym).call.to_s
    end

    def submit64_try_model_method_with_context(class_model, method_name, context)
      if class_model.respond_to?(method_name)
        method_found = class_model.method(method_name)
        if method_found.parameters.any?
          return method_found.call(context)
        else
          return method_found.call
        end
      end
      nil
    end

    def submit64_try_row_method_with_context(row, method_name, context)
      if row.respond_to?(method_name)
        method_found = row.method(method_name)
        if method_found.parameters.any?
          return method_found.call(context)
        else
          return method_found.call
        end
      end
      nil
    end

    def submit64_get_shallow_form_config(context)
      default_form = {
        use_model_validations: true,
        backend_date_format: 'YYYY-MM-DD',
        backend_datetime_format: 'YYYY-MM-DDTHH:MM:SSZ',
      }
      form = submit64_try_model_method_with_context(self, :submit64_form_builder, context)
      if form.nil?
        form = default_form
      else
        form = default_form.merge(form)
      end
      {
        backend_date_format: form[:backend_date_format],
        backend_datetime_format: form[:backend_datetime_format],
        use_model_validations: form[:use_model_validations],
      }
    end

  end

end
