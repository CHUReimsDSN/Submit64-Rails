require "base64"
require "tempfile"

module Submit64

  module MetadataProvider
    def self.extended(base)
      unless base < ActiveRecord::Base
        raise Submit64Exception.new("#{base} must inherit from ActiveRecord::Base to extend Submit64::MetadataProvider", 400)
      end
    end

    def submit64_get_form_metadata_and_data(request_params)
      unless self < ActiveRecord::Base
        raise Submit64Exception.new("Method must be called from ActiveRecord::Base inherited class", 400)
      end
      context = request_params[:context]
      if context != nil
        context = context.to_h
      else
        context = {}
      end
      lifecycle_callbacks = submit64_try_object_method_with_args(self, :submit64_lifecycle_events, context) || {}
      on_metadata_data = OnMetadataData.from
      submit64_try_lifecycle_callback(lifecycle_callbacks[:on_metadata_start], on_metadata_data, context)

      resource_instance = self.all
                          .where({ self.primary_key.to_sym => request_params[:resourceId] })
                          .first
      form_metadata = self.submit64_get_form_for_interop(resource_instance, context)

      if resource_instance.nil? && request_params[:resourceId] != nil
        raise Submit64Exception.new("Resource #{request_params[:resou0rceName]} with primary key '#{request_params[:resourceId]}' does not exist", 404)
      end

      if !resource_instance.nil?
        resource_data, form_metadata = submit64_get_resource_data(resource_instance, form_metadata, request_params, context)
      else
        resource_data, form_metadata = submit64_get_default_value_data(form_metadata, context)
      end

      on_metadata_data.resync(form: form_metadata, resource_data: resource_data)
      submit64_try_lifecycle_callback(lifecycle_callbacks[:on_metadata_end], on_metadata_data, context)
      
      {
        form: form_metadata,
        resource_data: resource_data
      }
    end

    def submit64_get_association_data(request_params)
      unless self < ActiveRecord::Base
        raise Submit64Exception.new("Method must be called from ActiveRecord::Base inherited class", 400)
      end
      context = request_params[:context]
      if context != nil
        context = context.to_h
      else
        context = {}
      end
      lifecycle_callbacks = submit64_try_object_method_with_args(self, :submit64_lifecycle_events, context) || {}
      association = self.reflect_on_association(request_params[:associationName])
      if association.nil?
        raise Submit64Exception.new("Association not found : #{request_params[:associationName]}", 400)
      end
      from_class = self.to_s
      association_class = association.klass
      default_limit = Submit64.get_association_data_pagination_limit
      limit = request_params[:limit] || default_limit
      if limit > default_limit
        limit = default_limit
      end
      offset = request_params[:offset] || 0
      on_association_data = OnAssociationData.from(limit, offset, from_class, association_class)
      submit64_try_lifecycle_callback(lifecycle_callbacks[:on_get_association_start], on_association_data, context)

      custom_select_column = submit64_try_object_method_with_args(association_class, :submit64_association_select_columns, from_class, context)
      if custom_select_column != nil
        builder_rows = association_class.select([*custom_select_column, association_class.primary_key.to_sym]).all
      else
        builder_rows = association_class.all
      end
      custom_builder_row_filter = submit64_try_object_method_with_args(association_class, :submit64_association_filter_rows, from_class, context)
      if custom_builder_row_filter != nil
        builder_rows = builder_rows.and(custom_builder_row_filter)
      end
      label_filter = request_params[:labelFilter]
      if !label_filter.empty? || label_filter.nil?
        columns_filter = [:label, :id]
        custom_columns_filter = submit64_try_object_method_with_args(association_class, :submit64_association_filter_columns, from_class, context)
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
      association_scope = association.scope
      if association_scope
        if !request_params[:resourceId].nil? && request_params[:resourceId] != ""
          resource_instance = self.where({ self.primary_key => request_params[:resourceId]}).first
        else
          resource_instance = nil
        end
        builder_rows = builder_rows.and(association_class.instance_exec(resource_instance, &association_scope))
      end
      builder_row_count = builder_rows.reselect(association_class.primary_key.to_sym).count
      builder_rows = builder_rows.limit(limit).offset(offset).map do |row|
        label = ""
        custom_label = submit64_try_object_method_with_args(row, :submit64_association_label, from_class, context)
        if custom_label != nil
          label = custom_label
        else
          label = submit64_association_default_label(row)
        end
        {
          label: label,
          value: row[self.primary_key.to_sym],
          data: row
        }
      end
      on_association_data.resync(rows: builder_rows, row_count: builder_row_count)
      submit64_try_lifecycle_callback(lifecycle_callbacks[:on_get_association_end], on_association_data, context)
      {
        rows: builder_rows,
        row_count: builder_row_count
      }
    end

    def submit64_get_submit_data(request_params)
      unless self < ActiveRecord::Base
        raise Submit64Exception.new("Method must be called from ActiveRecord::Base inherited class", 400)
      end
      context = request_params[:context]
      if context != nil
        context = context.to_h
      else
        context = {}
      end
      lifecycle_callbacks = submit64_try_object_method_with_args(self, :submit64_lifecycle_events, context) || {}
      edit_mode = !request_params[:resourceId].nil? && request_params[:resourceId] != ""
      if !edit_mode
        resource_instance = self.new
      else
        resource_instance = self.where({ self.primary_key => request_params[:resourceId] }).first
        if resource_instance.nil?
          raise Submit64Exception.new("Resource #{request_params[:resourceName]} with primary key '#{request_params[:resourceId]}' does not exist", 404)
        end
      end
      bulk_mode = request_params[:bulkCount] != nil && request_params[:bulkCount].to_i > 0
      form = self.submit64_get_form(resource_instance, context)
      if (!form[:allow_bulk] && bulk_mode) || (bulk_mode && edit_mode)
        raise Submit64Exception.new("You are not allowed to submit bulk", 401)
      end
      unlink_fields = {}
      form[:sections].each do |section|
        section[:fields].each_with_index do |field, field_index|
          if field[:unlinked] == true
            unlink_fields[field[:field_name].to_sym] = request_params[:resourceData][field[:field_name].to_s]
            request_params[:resourceData].delete(field[:field_name].to_s)
          end
        end
      end

      # Check for not allowed attribute
      flatten_fields = []
      form[:sections].each do |section|
        section[:fields].each do |field|
          flatten_fields << field[:field_name].to_s
        end
      end
      request_params[:resourceData].keys.each do |resource_key|
        if flatten_fields.exclude? resource_key
          raise Submit64Exception.new("You are not allowed to edit this attribut: #{resource_key}", 401)
        end
      end

      # Start
      on_submit_data = OnSubmitData.from(resource_instance, edit_mode, bulk_mode, request_params, form, unlink_fields)
      submit64_try_lifecycle_callback(lifecycle_callbacks[:on_submit_start], on_submit_data, context)
      success = false
      error_messages = {}
      resource_id = resource_instance.id || nil

      # Detach attachment from params
      attachments = {}
      all_attachments = self.reflect_on_all_attachments.map do |attachment|
        type = submit64_get_form_field_type_by_attachment(attachment)
        {
          name: attachment.name,
          type: type,
        }
      end
      request_params[:resourceData].each do |key, value|
        attachment_found = all_attachments.find do |attachment_find|
          attachment_find[:name] == key.to_sym
        end
        if attachment_found.nil?
          next
        end
        base64_attachments = value["add"].map do |file_pending|
          base64_to_uploaded_file(file_pending["base64"], file_pending["filename"])
        end
        attachments[key] = request_params[:resourceData][key]
        if attachment_found[:type] == "attachmentHasOne"
          request_params[:resourceData][key] = base64_attachments.first
        else
          request_params[:resourceData][key] = base64_attachments
        end
      end

      # Compute row ids from association to instance
      all_associations = self.reflect_on_all_associations.filter do |association|
        association.options[:polymorphic] != true
      end.map do |association|
        type = submit64_get_form_field_type_by_association(association)
        association_class =  association.klass
        {
          name: association.name,
          klass: association_class,
          type: type,
        }
      end
      request_params[:resourceData].each do |key, value|
        association_found = all_associations.find do |asso_find|
          asso_find[:name] == key.to_sym
        end
        if association_found.nil?
          next
        end
        association_class = association_found[:klass]
        from_class = self.to_s
        custom_select_column = submit64_try_object_method_with_args(association_class, :submit64_association_select_columns, from_class, context)
        if custom_select_column != nil
          builder_rows = association_class.select([*custom_select_column, association_class.primary_key.to_sym]).all
        else
          builder_rows = association_class.all
        end
        custom_builder_row_filter = submit64_try_object_method_with_args(association_class, :submit64_association_filter_rows, from_class, context)
        if custom_builder_row_filter != nil
          builder_rows = builder_rows.and(custom_builder_row_filter)
        end
        builder_rows = builder_rows.and(association_class.where({ association_class.primary_key.to_sym => value }))
        association_scope = self.reflect_on_association(association_found[:name])&.scope
        if association_scope
          builder_rows = builder_rows.and(association_class.instance_exec(nil, &association_scope))
        end 

        if ['selectBelongsTo', 'selectHasOne'].include? association_found[:type]
          request_params[:resourceData][key] = builder_rows.first           
        else
          request_params[:resourceData][key] = builder_rows
        end
      end
      
      # Assign attributs
      skip_validation = form[:skip_validation] == true
      on_submit_data.resync(skip_validation: skip_validation, error_messages: error_messages, resource_id: resource_id, request_params: request_params)
      submit64_try_lifecycle_callback(lifecycle_callbacks[:on_submit_before_assignation], on_submit_data, context)
      begin
        resource_instance.assign_attributes(request_params[:resourceData])
      rescue => exception
        if exception.class == ActiveRecord::RecordNotSaved
          if exception.message.include? "because one or more of the new records could not be saved"
            error_messages["backend"] = ["Association impossible car un/une des '#{exception.message.split("replace").second.split(" ").first}' n'est pas valide'"]
            return {
              success: false,
              resource_id: resource_id,
              errors: error_messages
            }
          end
        end
      end

      # Save
      bulk_data = nil
      if skip_validation || resource_instance.valid?
        on_submit_data.resync(is_valid: true, resource_instance: resource_instance, error_messages: error_messages)
        submit64_try_lifecycle_callback(lifecycle_callbacks[:on_submit_valid_before_save], on_submit_data, context)

        resource_instance.save!(validate: false)
        success = true
        resource_id = resource_instance.id
        params_for_form = {
          resourceName: request_params[:resourceName],
          resourceId: resource_id,
          context: request_params[:context]
        }
        resource_data_renew = submit64_get_form_metadata_and_data(params_for_form)
        form = resource_data_renew[:form]
        if request_params[:bulkCount] != nil && request_params[:bulkCount].to_i > 1
          bulk_data = [resource_data_renew[:resource_data]]
          (request_params[:bulkCount].to_i - 1).times do
            clone = self.new
            clone.assign_attributes(request_params[:resourceData])
            clone.save!(validate: false)
            clone_data = resource_data_renew[:resource_data].deep_dup
            clone_data[self.primary_key.to_s] = clone.method(self.primary_key.to_sym).call
            bulk_data << clone_data
          end
          bulk_data = bulk_data
        end

        on_submit_data.resync(success: success, resource_id: resource_id, resource_instance: resource_instance, bulk_data: bulk_data, form: form)
        if bulk_mode
          submit64_try_lifecycle_callback(lifecycle_callbacks[:on_bulk_submit_success], on_submit_data, context)
        else
          submit64_try_lifecycle_callback(lifecycle_callbacks[:on_submit_success], on_submit_data, context)
        end
      else
        error_messages = resource_instance.errors.messages.deep_dup
        resource_data_renew = { 
          form: nil,
          resource_data: nil
        }
        on_submit_data.resync(success: success, error_messages: error_messages)
        if bulk_mode
          submit64_try_lifecycle_callback(lifecycle_callbacks[:on_bulk_submit_fail], on_submit_data, context)
        else
          submit64_try_lifecycle_callback(lifecycle_callbacks[:on_submit_fail], on_submit_data, context)
        end
      end
      {
        success: success,
        resource_id: resource_id,
        form: form,
        resource_data: resource_data_renew[:resource_data],
        bulk_data: bulk_data,
        errors: error_messages
      }
    end

    private
    def submit64_get_resource_data(resource_instance, form_metadata, request_params, context)
      from_class = self.to_s
      columns_to_select = [self.primary_key.to_sym]
      unlink_default_values = {}
      form_metadata[:sections].each do |section|
        section[:fields].each do |field|
          if field[:unlinked] 
            if field[:default_value]
              unlink_default_values[field[:field_name]] = field[:default_value]
            end
            next
          end
          field.delete(:default_value)
          if field[:field_association_name] != nil
            relation_data = self.reflect_on_association(field[:field_association_name])
            if relation_data.class.to_s.demodulize == "BelongsToReflection"
              columns_to_select << relation_data.foreign_key
            end
          else
            columns_to_select << field[:field_name]
          end
        end
      end
      resource_data = resource_instance.slice(columns_to_select)
      resource_data_json = resource_data.as_json

      form_metadata[:sections].each do |section|
        section[:fields].each do |field|
          if (field[:field_association_name] != nil)
            association_class = field[:field_association_class]
            relation = self.reflect_on_association(field[:field_association_name])
            custom_select_column = submit64_try_object_method_with_args(association_class, :submit64_association_select_columns, from_class, context)
            custom_builder_row_filter = submit64_try_object_method_with_args(association_class, :submit64_association_filter_rows, from_class, context)
            case field[:field_type]
              when "selectBelongsTo", "selectHasOne"
                if custom_select_column != nil
                  builder_rows = association_class.select([*custom_select_column, association_class.primary_key.to_sym])
                                                  .where({ association_class.primary_key.to_sym => resource_instance[relation.join_foreign_key] })
                else
                  builder_rows = association_class.where({ association_class.primary_key.to_sym => resource_instance[relation.join_foreign_key] })
                end
                if custom_builder_row_filter != nil
                  builder_rows = builder_rows.and(custom_builder_row_filter)
                end
                if relation.scope
                  builder_rows = builder_rows.and(association_class.instance_exec(resource_instance, &relation.scope))
                end 
                row = builder_rows.first
                if row.nil?
                  next
                end
                association_data = {
                  label: nil,
                  data: row
                }
                custom_display_value = submit64_try_object_method_with_args(row, :submit64_association_label, from_class, context)
                if custom_display_value != nil
                  association_data[:label] = custom_display_value
                else
                  association_data[:label] = submit64_association_default_label(row)
                end
                field[:field_association_data] = [association_data]
                resource_data_json[field[:field_name]] = row[association_class.primary_key.to_sym]
              when "selectHasMany", "selectHasAndBelongsToMany"
                if custom_select_column != nil
                  builder_rows = resource_instance.public_send(field[:field_association_name]).select([*custom_select_column, association_class.primary_key.to_sym])
                else
                  builder_rows = resource_instance.public_send(field[:field_association_name])
                end
                if custom_builder_row_filter != nil
                  builder_rows = builder_rows.and(custom_builder_row_filter)
                end
                resource_data_json[field[:field_name]] = []
                association_data = []
                builder_rows.each do |row|
                  association_data_entry = {
                    label: nil,
                    data: nil
                  }
                  custom_display_value = submit64_try_object_method_with_args(row, :submit64_association_label, from_class, context)
                  if custom_display_value != nil
                    association_data_entry[:label] = custom_display_value
                  else
                    association_data_entry[:label] = submit64_association_default_label(row)
                  end
                  association_data_entry[:data] = row
                  resource_data_json[field[:field_name]] << row[association_class.primary_key.to_sym]
                  association_data << association_data_entry
                end
                field[:field_association_data] = association_data
            end
          elsif (field[:field_type].include? "attachment")
            case field[:field_type]
              when "attachmentHasOne"
                blob = resource_instance.public_send(field[:field_name]).blob
                if blob.nil?
                  next
                end
                attachment_data = {
                  id: blob.id,
                  filename: blob.filename,
                  size: blob.byte_size,
                }
                field[:field_attachment_data] = [attachment_data]
              when "attachmentHasMany"
                blobs = resource_instance.public_send(field[:field_name]).blobs
                attachment_data = []
                blobs.each do |blob|
                  attachment_data_entry = {
                    id: blob.id,
                    filename: blob.filename,
                    size: blob.byte_size,
                  }
                  attachment_data << attachment_data_entry
                end
                field[:field_attachment_data] = attachment_data
            end
          end
        end
      end

      unlink_default_values.each do |key, value|
        resource_data_json[key.to_s] = value
      end

      [resource_data_json, form_metadata]
    end

    def submit64_get_default_value_data(form_metadata, context)
      resource_data_final = {}
      from_class = self.to_s
      form_metadata[:sections].each do |section|
        section[:fields].each do |field|
          if field[:default_value] == nil
            next
          end
          default_value = nil
          case field[:field_type]
          when 'string'
            default_value = field[:default_value].to_s
          when 'text'
            default_value = field[:default_value].to_s
          when 'date'
            default_value = field[:default_value].to_s
          when 'datetime'
            default_value = field[:default_value].to_s            
          when 'selectString'
            default_value = field[:default_value].to_s
          when 'selectBelongsTo', 'selectHasMany', 'selectHasOne', 'selectHasAndBelongsToMany'
            association_class = field[:field_association_class]
            custom_select_column = submit64_try_object_method_with_args(association_class, :submit64_association_select_columns, from_class, context)
            if custom_select_column != nil
              builder_rows = association_class.select([*custom_select_column, association_class.primary_key.to_sym]).all
            else
              builder_rows = association_class.all
            end
            custom_builder_row_filter = submit64_try_object_method_with_args(association_class, :submit64_association_filter_rows, from_class, context)
            if custom_builder_row_filter != nil
              builder_rows = builder_rows.and(custom_builder_row_filter)
            end
            builder_rows = builder_rows.and(association_class.where({ association_class.primary_key.to_sym => field[:default_value] }))
            association_scope = self.reflect_on_association(field[:field_association_name])&.scope
            if association_scope
              builder_rows = builder_rows.and(association_class.instance_exec(nil, &association_scope))
            end 
            if field[:field_type] == 'selectBelongsTo' || field[:field_type] == 'selectHasOne'
                row = builder_rows.first
              if row.nil?
                next
              end
              association_data = {
                label: [],
                data: [row]
              }
              custom_display_value = submit64_try_object_method_with_args(row, :submit64_association_label, from_class, context)
              if custom_display_value != nil
                association_data[:label] << custom_display_value
              else
                association_data[:label] << submit64_association_default_label(row)
              end
              default_value = row[association_class.primary_key]
              field[:field_association_data] = association_data
            elsif field[:field_type] == 'selectHasMany' || field[:field_type] == 'selectHasAndBelongsToMany'
              rows = builder_rows
              association_data = {
                label: [],
                data: []
              }
              default_value = []
              rows.each do |row|
                custom_display_value = submit64_try_object_method_with_args(row, :submit64_association_label, from_class, context)
                if custom_display_value != nil
                  association_data[:label] << custom_display_value
                else
                  association_data[:label] << submit64_association_default_label(row)
                end
                association_data[:data] << row
                default_value << row[association_class.primary_key]
              end
              field[:field_association_data] = association_data
            end
          when 'checkbox'
            default_value = field[:default_value].to_s == "true"
          when 'number'
            field_default_value = field[:default_value]
            default_value = field_default_value % 1 == 0 ? field_default_value.to_f : field_default_value.to_i
          when 'object'
            default_value = field[:default_value]
          end
          resource_data_final[field[:field_name]] = default_value
          field.delete(:default_value)
        end
      end
      [resource_data_final, form_metadata]
    end

    def submit64_get_column_type_by_sgbd_type(sql_type)
      case sql_type
      when :text
        field_type = 'text'
      when :decimal
        field_type = 'number'
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

    def submit64_get_form_field_type_by_column_type(column_type, form_select_options)
      if form_select_options.count > 0
        return "select"
      end
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
      when "HasOneReflection"
        return "selectHasOne"
      when "HasAndBelongsToManyReflection"
        return "selectHasAndBelongsToMany"
      when "ThroughReflection"
        return nil
      else
        return nil
      end
    end

    def submit64_get_form_field_type_by_attachment(attachment)
      case attachment.class.to_s.demodulize
      when "HasOneAttachedReflection"
        return "attachmentHasOne"
      when "HasManyAttachedReflection"
        return "attachmentHasMany"
      else 
        return nil
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
          if association.options[:optional] != true
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

        # File
        when "ContentTypeValidator"
          rules << { type: "allowFileContentType", including: validator.options[:in] }
        when "SizeValidator"
          operators = [:less_than, :greater_than, :between, :equal_to]
          operators.each do |operator_key|
            operator_value = validator.options[operator_key]
            if operator_value.nil?
              next
            end
            case operator_key
            when :less_than
              rules << { type: 'lessThanOrEqualFileLength', less_than: operator_value.to_i }
            when :greater_than
              rules << { type: 'greaterThanOrEqualFileLength', greater_than: operator_value.to_i }
            when :between
              rules << { type: 'greaterThanOrEqualFileLength', greater_than: operator_value.first.to_i }
              rules << { type: 'lessThanOrEqualFileLength', less_than: operator_value.last.to_i }
            when :equal_to
              rules << { type: 'equalToFileLength', equal_to: operator_value.to_i }
            else
              nil
            end
          end
        when "AttachedValidator"
          rules << { type: 'required' }
        when "LimitValidator"
          operators = [:min, :max]
          operators.each do |operator_key|
            operator_value = validator.options[operator_key]
            if operator_value.nil?
              next
            end
            case operator_key
            when :min
              rules << { type: 'lessThanOrEqualFileCount', less_than: operator_value.to_i }
            when :max
              rules << { type: 'greaterThanOrEqualFileCount', greater_than: operator_value.to_i }
            else
              nil
            end
          end
        when "TotalSizeValidator"
          operators = [:less_than, :greater_than, :equal_to, :between]
          operators.each do |operator_key|
            operator_value = validator.options[operator_key]
            if operator_value.nil?
              next
            end
            case operator_key
            when :less_than
              rules << { type: 'lessThanOrEqualTotalFileSize', less_than: operator_value.to_i }
            when :greater_than
              rules << { type: 'greaterThanOrEqualTotalFileSize', greater_than: operator_value.to_i }
            when :equal_to
              rules << { type: 'equalToTotalFileSize', equal_to: operator_value.to_i }
            when :between
              rules << { type: 'greaterThanOrEqualTotalFileSize', greater_than: operator_value.first.to_i }
              rules << { type: 'lessThanOrEqualTotalFileSize', less_than: operator_value.last.to_i }
            else
              nil
            end
          end

        else
          nil
        end
      end
      rules
    end

    def submit64_get_column_select_options(field_def, column_name = nil)
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

      if !column_name.nil?
        defined_enum = self.defined_enums[column_name.to_s]
        if !defined_enum.nil?
          return defined_enum.entries.map do |enum_entry|
            {
              label: enum_entry[0],
              value: enum_entry[1]
            }
          end
        end
      end
      []
    end

    def submit64_beautify_target(target)
      target.to_s.capitalize.gsub('_', ' ')
    end

    def submit64_association_default_label(row)
      if row.respond_to?(:label, true)
        return row.method(:label).call.to_s
      end
      if row.respond_to?(:id, true)
        return row.method(:id).call.to_s
      end
      row.method(self.primary_key.to_sym).call.to_s
    end

    def submit64_try_object_method_with_args(object, method_name, *args)
      if object.respond_to?(method_name, true)
        method_found = object.method(method_name)
        return submit64_try_method_with_args(method_found, *args)
      end
      nil
    end

    def submit64_try_method_with_args(callback, *args)
      if callback.parameters.any?
        return callback.call(*args)
      else
        return callback.call
      end
    end

    def submit64_get_default_form
      {
        sections: [],
        use_model_validations: true,
        backend_date_format: 'YYYY-MM-DD',
        backend_datetime_format: 'YYYY-MM-DDTHH:mm:ss.SSSZ',
        resource_name: self.to_s,
        css_class: '',
        resetable: true,
        clearable: true
      }
    end

    def submit64_get_form(resource_instance, context)
      # First structuration
      default_form_metadata = self.submit64_get_default_form
      form_metadata = submit64_try_object_method_with_args(self, :submit64_form_builder, resource_instance, context)
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
          result_section_statement = section[:statement].call
          if !result_section_statement
            section_index_to_purge << index_section
            next
          end
        end
        field_index_to_purge = []
        section[:fields].each_with_index do |field, index_field|
          if field[:statement]
            result_field_statement = field[:statement].call
            if !result_field_statement
              field_index_to_purge << index_field
              next
            end
          end
          if field[:target] != nil
            if self.columns_hash[field[:target].to_s].nil? 
              association = self.reflect_on_association(field[:target])
              if association.nil? || association.options[:polymorphic] == true
                attachment = self.reflect_on_attachment(field[:target])
                if attachment.nil?
                  field_index_to_purge << index_field
                end
              end
            end
          else
            if field[:unlink_target].nil?
              field_index_to_purge << index_field
            end
          end
        end
        section[:fields] = section[:fields].filter.with_index do |_field, index_select|
          field_index_to_purge.exclude?(index_select)
        end
      end
      form_metadata[:sections] = form_metadata[:sections].filter.with_index do |section, index_section|
        section_index_to_purge.exclude?(index_section) && section[:fields].count > 0
      end

      # Projection
      form_metadata[:sections] = form_metadata[:sections].map do |section_map|
        fields = section_map[:fields].map do |field_map|
          if field_map[:unlink_target]
            form_select_options = self.submit64_get_column_select_options(field_map) # TODO test si enum possible sans column
            form_field_type = field_map[:unlink_type]
            form_rules = [] # TODO test validation sans column
            field_name = field_map[:unlink_target]
            label = field_map[:label] || self.submit64_beautify_target(field_map[:unlink_target])
            field_association_name = nil
            field_association_class = nil
            unlinked = true
          else
            unlinked = false
            if self.columns_hash[field_map[:target].to_s] != nil
              field_type = self.submit64_get_column_type_by_sgbd_type(columns_hash[field_map[:target].to_s].type)
              form_select_options = self.submit64_get_column_select_options(field_map, field_map[:target])
              form_field_type = self.submit64_get_form_field_type_by_column_type(field_type, form_select_options)
              form_rules = self.submit64_get_column_rules(field_map, field_type, form_metadata, context[:name])
              field_name = field_map[:target]
              label = field_map[:label] || self.submit64_beautify_target(field_map[:target])
              field_association_name = nil
              field_association_class = nil
            else
              association = self.reflect_on_association(field_map[:target])
              if association != nil
                field_name = field_map[:target]
                form_field_type = self.submit64_get_form_field_type_by_association(association)
                form_rules = self.submit64_get_column_rules(field_map, nil, form_metadata, context[:name])
                form_select_options = self.submit64_get_column_select_options(field_map, field_map[:target])
                label = field_map[:label] || self.submit64_beautify_target(field_map[:target])
                field_association_name = association.name
                field_association_class =  association.klass
              else
                attachment = self.reflect_on_attachment(field_map[:target])
                if attachment != nil
                  field_name = field_map[:target]
                  form_field_type = self.submit64_get_form_field_type_by_attachment(attachment)
                  form_rules = self.submit64_get_column_rules(field_map, nil, form_metadata, context[:name])
                  form_select_options = []
                  label = field_map[:label] || self.submit64_beautify_target(field_map[:target])
                  field_association_name = nil
                  field_association_class = nil
                end
              end
            end
          end
          {
            field_name: field_name,
            field_type: form_field_type,
            field_extra_type: field_map[:extra_type],
            label: label,
            field_association_name: field_association_name,
            field_association_class: field_association_class,
            hint: field_map[:hint],
            prefix: field_map[:prefix],
            suffix: field_map[:suffix],
            readonly: field_map[:readonly],
            rules: form_rules,
            static_select_options: form_select_options,
            css_class: field_map[:css_class],
            default_value: field_map[:default_value],
            unlinked: unlinked
          }
        end.filter do |field_filter|
          !field_filter[:field_type].nil?
        end
        {
          fields: fields,
          name: section_map[:name],
          label: section_map[:label],
          icon: section_map[:icon],
          readonly: section_map[:readonly],
          css_class: section_map[:css_class],
        }
      end
      {
        sections: form_metadata[:sections],
        resource_name: form_metadata[:resource_name],
        use_model_validations: form_metadata[:use_model_validations],
        backend_date_format: form_metadata[:backend_date_format],
        backend_datetime_format: form_metadata[:backend_datetime_format],
        css_class: form_metadata[:css_class],
        resetable: form_metadata[:resetable],
        clearable: form_metadata[:clearable],
        allow_bulk: form_metadata[:allow_bulk],
        readonly: form_metadata[:readonly],
    }
    end

    def submit64_get_form_for_interop(resource_instance, context)
      form = submit64_get_form(resource_instance, context)
      [].each do |key_to_exclude|
        form.delete key_to_exclude
      end
      form
    end

    def submit64_try_lifecycle_callback(proc, *args)
      if proc.nil? || proc.class != Proc
        return nil
      end
      submit64_try_method_with_args(proc, *args)
    end

    def base64_to_uploaded_file(base64, filename)
      if base64 =~ /^data:(.*?);base64,/
        content_type = Regexp.last_match(1)
        base64 = base64.split(",", 2).last
      end
      decoded = Base64.decode64(base64)
      tempfile = Tempfile.new(filename)
      tempfile.binmode
      tempfile.write(decoded)
      tempfile.rewind
      ActionDispatch::Http::UploadedFile.new(
        tempfile: tempfile,
        filename: filename,
        type: content_type
      )
    end

  end

end
