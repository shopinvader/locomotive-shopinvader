module Locomotive
  module Steam
    module Liquid
      module Tags

        class Erp < ::Liquid::Tag
          Base = "(#{::Liquid::VariableSignature}+)\s*(#{::Liquid::QuotedString}|#{::Liquid::VariableSignature}+)"
          Syntax = /#{Base}/o
          SyntaxWith = /#{Base}\s*with\s*(.*)?/o
          SyntaxAs = /#{Base}\s*as\s*(#{::Liquid::VariableSignature}+)/o
          SyntaxAsWith = /#{Base}\s*as\s*(#{::Liquid::VariableSignature}+)\s*with\s*(.*)?/o
          def initialize(tag_name, markup, options)
            syntax_error = false

            if markup =~ SyntaxAsWith
              @method_name, service_path, @to = $1, $2, $3
              @params = parse_options_from_string($4)
            elsif markup =~ SyntaxWith
              @method_name, service_path = $1, $2
              @params = parse_options_from_string($3)
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
            if instance_variable_defined?(:@variable_service_path)
              @service_path = context[@variable_service_path]
            end
            if @params
              @params = interpolate_options(@params, context)
            end
            result = service.call(@method_name, @service_path, @params)
            if @to
              context.scopes.last[@to] = result
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
