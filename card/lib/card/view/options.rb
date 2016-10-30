class Card
  class View
    module Options
      def self.keys
        @keys
      end

      @keys = {
        standard: ::Set.new(
          [
            :nest_name,   # name as used in nest
            :nest_syntax, # full nest syntax

            :structure,
            :type,
            :title,
            :variant,
            :params,
            :home_view,
            :size,

            :skip_permissions,
            :main
          ]
        ),
        non_standard: ::Set.new(
          [
            :items,
            :view,
            :hide,
            :show
          ]
        )
      }

      module ClassMethods
        def standard_inheritance_option_keys
          Options.keys[:standard] + [:items]
        end

        def option_keys
          @option_keys ||= Options.keys[:standard] + Options.keys[:non_standard]
        end

        def nest_option_keys
          @nest_option_keys ||= (option_keys - [:skip_permissions, :main])
        end
      end

      def options
        @options ||= standard_options_with_inheritance
      end

      def standard_options_with_inheritance
        @options = {}
        self.class.standard_inheritance_option_keys.each do |key|
          prep_or_parent_option key
        end
        @options
      end

      def prep_or_parent_option key
        value = prep_options[key]
        value ||= @parent.options[key] if @parent
        @options[key] = value if value.present?
      end

      def normalized_options
        @normalized_options ||= normalize_options
      end

      def normalize_options
        options = options_to_hash @raw_options.clone
        options.deep_symbolize_keys!
        options[:view] = original_view
        options[:main] = @format.main?
        options
      end

      def options_to_hash opts
        case opts
        when Hash  then opts
        when Array then opts[0].merge opts[1]
        when nil   then {}
        else raise Card::Error, "bad view options: #{opts}"
        end
      end

      def foreign_options
        @foreign_options ||= prep_options.reject do |key, _value|
          self.class.option_keys.member? key
        end
      end

      def prep_options
        @prep_options ||= default_options.merge(main_view_options)
      end

      def default_options
        @default_options ||= begin
          @default_options = normalized_options.clone
          process_default_options @default_options
          @default_options
        end
      end

      def main_view_options
        main_view? ? @format.main_nest_options : {}
      end

      def process_default_options opts
        @format.view_options_with_defaults original_view, opts
      end

      def slot_options
        slot_options = options.clone
        slot_options[:main_view] = true if main_view?
        # slot_visibility_options slot_options
        slot_options
      end

      def slot_visibility_options slot_options
        [:hide, :show].each do |setting|
          array = viz_hash.keys.select { |k| viz_hash[k] == setting }
          slot_options[setting] = array.join "," if array.any?
        end
      end

      def items
        options[:items] ||= {}
      end

      Options.keys[:standard].each do |option_key|
        define_method option_key do
          @prepared ? options[option_key] : default_options[option_key]
        end

        define_method "#{option_key}=" do |value|
          if @prepared
            options[option_key] = value
          else
            default_options[option_key] = value
          end
        end
      end
    end
  end
end
