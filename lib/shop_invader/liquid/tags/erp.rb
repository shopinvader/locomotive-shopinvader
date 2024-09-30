module Locomotive
  module Steam
    module Liquid
      module Tags

        class Erp < ::Liquid::Tag

          include Concerns::AttributesParser

          Base = "(#{::Liquid::VariableSignature}+)\s*(#{::Liquid::QuotedString}|#{::Liquid::VariableSignature}+)"
          Syntax = /#{Base}/o
          SyntaxWith = /#{Base}\s*with\s*(.*)?/o
          SyntaxAs = /#{Base}\s*as\s*(#{::Liquid::VariableSignature}+)/o
          SyntaxAsWith = /#{Base}\s*as\s*(#{::Liquid::VariableSignature}+)\s*with\s*(.*)?/o
          attr_reader :attributes, :attributes_var_name

          def initialize(tag_name, markup, options)
            super

            syntax_error = false
            if markup =~ SyntaxAsWith
              @method_name, service_path, @to = $1, $2, $3
              @attributes = parse_markup($4)
            elsif markup =~ SyntaxWith
              @method_name, service_path = $1, $2
              @attributes = parse_markup($3)
            elsif markup =~ SyntaxAs
              @method_name, service_path, @to = $1, $2, $3
            elsif markup =~ Syntax
              @method_name, service_path = $1, $2
            else
              syntax_error = true
            end
            if @method_name
              @method_name.upcase!
            end

            unless ['GET', 'DELETE', 'POST', 'PUT'].include?(@method_name)
              syntax_error = true
            end

            if syntax_error
              raise ::Liquid::SyntaxError.new(
                  "Syntax Error in 'erp' - Valid syntax: erp [method: get/put/post/delete] \"service_path\" as [result] with [params]. Result and params are optional")
            end

            prepare_service_path(service_path)
            super
          end

          def render(context)
            @context = context
            context.stack do
              if @attributes
                attrs = evaluate_attributes(context)
              else
                attrs = nil
              end
              if instance_variable_defined?(:@variable_service_path)
                @service_path = context[@variable_service_path]
              end
              result = service.call(@method_name, @service_path, attrs)
              if @to
                context.scopes.last[@to] = result
              end
            end
            nil
          end

          private

          def prepare_service_path(token)
            if token.match(::Liquid::QuotedString)
              @service_path = token.gsub(/['"]/, '')
            else
              @variable_service_path = token
            end
          end

          def service
            @context.registers[:services].erp
          end

          ::Liquid::Template.register_tag('erp'.freeze, Erp)

        end
      end
    end
  end
end
