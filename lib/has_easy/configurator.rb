module Izzle
  module HasEasy
    class Configurator
      
      attr_accessor :definitions
      
      def initialize(klass, name)
        @klass = klass
        @name = name
        @definitions = {}
      end
      
      def define(name, options = {})
        name = Helpers.normalize(name)
        raise ArgumentError, "class #{@klass} has_easy('#{@name}') already defines '#{name}'" if @definitions.has_key?(name)
        @definitions[name] = Definition.new(name, options)
      end
      
      def do_metaprogramming_magic_aka_define_methods
        
        easy_accessors, object_accessors = [], []
        @definitions.values.each do |definition|
          easy_accessors << <<-end_eval
            def #{@name}_#{definition.name}=(value)
              set_has_easy_thing('#{@name}', '#{definition.name}', value)
            end
            def #{@name}_#{definition.name}
              get_has_easy_thing('#{@name}', '#{definition.name}')
            end
            def #{@name}_#{definition.name}?
              !!get_has_easy_thing('#{@name}', '#{definition.name}')
            end
          end_eval
          
          object_accessors << <<-end_eval
            def #{definition.name}=(value)
              proxy_owner.set_has_easy_thing('#{@name}', '#{definition.name}', value)
            end
            def #{definition.name}
              proxy_owner.get_has_easy_thing('#{@name}', '#{definition.name}')
            end
            def #{definition.name}?
              !!proxy_owner.get_has_easy_thing('#{@name}', '#{definition.name}')
            end
          end_eval
        end
        
        @klass.class_eval <<-end_eval
          # first define the has many relationship
          has_many :#{@name}, :class_name => 'HasEasyThing',
                              :as => :model,
                              :extend => AssocationExtension,
                              :dependent => :destroy do
            #{object_accessors.join("\n")}
          end
          # now define the easy accessors
          #{easy_accessors.join("\n")}
        end_eval
        
      end
      
    end
  end
end