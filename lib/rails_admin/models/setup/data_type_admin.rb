module RailsAdmin
  module Models
    module Setup
      module DataTypeAdmin
        extend ActiveSupport::Concern

        included do
          rails_admin do
            navigation_label 'Definitions'
            weight 110
            label 'Data Type'
            object_label_method { :custom_title }
            visible true

            show_in_dashboard false

            configure :_type do
              pretty_value do
                value.split('::').last.to_title
              end
            end

            group :behavior do
              label 'Behavior'
              active false
            end

            configure :title do
              pretty_value do
                bindings[:object].custom_title
              end
            end

            configure :slug

            configure :storage_size, :decimal do
              pretty_value do
                if objects = bindings[:controller].instance_variable_get(:@objects)
                  unless max = bindings[:controller].instance_variable_get(:@max_storage_size)
                    bindings[:controller].instance_variable_set(:@max_storage_size, max = objects.collect { |data_type| data_type.storage_size }.max)
                  end
                  (bindings[:view].render partial: 'size_bar', locals: { max: max, value: bindings[:object].records_model.storage_size }).html_safe
                else
                  bindings[:view].number_to_human_size(value)
                end
              end
              read_only true
            end

            configure :before_save_callbacks do
              group :behavior
              inline_add false
              associated_collection_scope do
                Proc.new { |scope|
                  scope.where(:parameters.with_size => 1)
                }
              end
            end

            configure :records_methods do
              group :behavior
              inline_add false
            end

            configure :data_type_methods do
              group :behavior
              inline_add false
            end

            edit do
              field :title, :enum_edit, &RailsAdmin::Models::Setup::FieldsConfigAdmin.shared_non_editable
              field :slug
              field :before_save_callbacks, &RailsAdmin::Models::Setup::FieldsConfigAdmin.shared_non_editable
              field :records_methods, &RailsAdmin::Models::Setup::FieldsConfigAdmin.shared_non_editable
              field :data_type_methods, &RailsAdmin::Models::Setup::FieldsConfigAdmin.shared_non_editable
            end

            list do
              field :namespace
              field :name
              field :slug
              field :_type
              field :used_memory do
                visible { Cenit.dynamic_model_loading? }
                pretty_value do
                  unless max = bindings[:controller].instance_variable_get(:@max_used_memory)
                    bindings[:controller].instance_variable_set(:@max_used_memory, max = ::Setup::DataType.fields[:used_memory.to_s].type.new(Setup::DataType.max(:used_memory)))
                  end
                  (bindings[:view].render partial: 'used_memory_bar', locals: { max: max, value: ::Setup::DataType.fields[:used_memory.to_s].type.new(value) }).html_safe
                end
              end
              field :storage_size
              field :updated_at
            end

            show do
              field :namespace
              field :name
              field :title
              field :slug
              field :_type
              field :storage_size
              field :schema do
                pretty_value do
                  v =
                    if json = JSON.pretty_generate(value) rescue nil
                      "<code class='json'>#{json.gsub('<', '&lt;').gsub('>', '&gt;')}</code>"
                    else
                      value
                    end

                  "<pre>#{v}</pre>".html_safe
                end
              end

              field :_id
              field :created_at
              #field :creator
              field :updated_at
              #field :updater
            end
            fields :namespace, :name, :slug, :_type, :storage_size, :updated_at
          end
        end

      end
    end
  end
end
