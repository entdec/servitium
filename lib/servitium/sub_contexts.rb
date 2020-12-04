# frozen_string_literal: true

module Servitium
  module SubContexts
    def sub_context(name)
      if name.to_s.singularize == name.to_s
        define_method("#{name}_attributes=") do |attributes|
          klass = "#{self.class.name}::#{name.to_s.camelize}".safe_constantize

          writer = "#{name}="
          inst = klass.new(attributes)
          inst.supercontext = self

          send writer, inst if respond_to? writer

          @subcontexts ||= {}
          @subcontexts[name] = inst

          inst
        end

        define_method("#{name}=") do |attributes|
          klass = "#{self.class.name}::#{name.to_s.camelize}".safe_constantize
          inst = if attributes.is_a? klass
                   attributes
                 else
                   inst = klass.new(attributes)
                   inst.supercontext = self
                   inst
                 end

          instance_variable_set("@#{name}".to_sym, inst)

          @subcontexts ||= {}
          @subcontexts[name] = inst

          inst
        end
      else
        define_method("#{name}_attributes=") do |attributes|
          klass = "#{self.class.name}::#{name.to_s.singularize.camelize}".safe_constantize

          if attributes.is_a? Hash
            keys = attributes.keys
            attributes = (attributes.values if keys.all? { |k| k.to_i.to_s == k })
          end

          result = []
          attributes.each do |params|
            inst = klass.new(params)
            inst.supercontext = self
            result.push(inst)
          end
          writer = "#{name}="
          send writer, result if respond_to? writer

          @subcontexts ||= {}
          @subcontexts[name] = result

          result
        end
        define_method("#{name}=") do |attributes|
          klass = "#{self.class.name}::#{name.to_s.singularize.camelize}".safe_constantize
          result = if attributes.is_a?(Array) && attributes.all? { |a| a.instance_of?(klass) }
                     attributes
                   else
                     if attributes.is_a? Hash
                       attributes = (attributes.values if attributes.keys.all? { |k| k.to_i.to_s == k })
                     end

                     result = []
                     attributes.each do |params|
                       inst = klass.new(params)
                       inst.supercontext = self
                       result.push(inst)
                     end
                     result
                   end

          instance_variable_set("@#{name}".to_sym, result)

          @subcontexts ||= {}
          @subcontexts[name] = result

          result
        end
      end

      define_method(name.to_s) do
        instance_variable_get("@#{name}".to_sym)
      end

      @attributes[name.to_s] = ActiveAttr::AttributeDefinition.new(name, {})
    end
  end
end
