require "active_support/core_ext/string"

module Sequel
  module Plugins
    module Enum
      def self.apply(model, opts = OPTS)
      end

      module ClassMethods
        def enums
          @enums ||= {}
        end

        def enum(column, values)
          klass = self
          enum_values = {}

          if values.is_a? Hash
            values.each do |key,val|
              raise ArgumentError, "index should be a symbol, #{key} provided which it's a #{key.class}" unless key.is_a? Symbol
              raise ArgumentError, "value should be an integer, #{val} provided which it's a #{val.class}" unless val.is_a? Integer
              enum_values[key] = val
            end
          elsif values.is_a? Array
            values.each_with_index { |name, i| enum_values[name] = i }
          else
            raise ArgumentError, "#enum expects the second argument to be an array of symbols or a hash like { :symbol => integer }"
          end

          detect_enum_conflict!(column, column.to_s.pluralize)
          klass.singleton_class.send(:define_method, column.to_s.pluralize) { enum_values }

          define_method "#{column}=" do |value|
            val = self.class.enums[column].assoc(value.to_sym)
            self[column] = val && val.last
          end

          define_method "#{column}" do
            val = self.class.enums[column].rassoc(self[column])
            val && val.first
          end

          enum_values.each do |key, value|
            define_method "#{key}?" do
              self.send(column) == key
            end
          end

          self.enums[column] = enum_values
        end

        private

        ENUM_CONFLICT_MESSAGE = \
          "You tried to define an enum named \"%{enum}\" on the model \"%{klass}\", but " \
          "this will generate a %{type} method \"%{method}\", which is already defined."

        def detect_enum_conflict!(column, method_name)
          if self.respond_to?(method_name, true)
            raise_conflict_error(column, method_name, type: "class")
          end
        end

        def raise_conflict_error(column, method_name, type: "instance")
          raise ArgumentError, ENUM_CONFLICT_MESSAGE % {
            enum: column,
            klass: name,
            type: type,
            method: method_name
          }
        end
      end
    end
  end
end
