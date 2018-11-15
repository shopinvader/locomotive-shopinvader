module Locomotive
  module Steam
    module Liquid
      module Tags

        class EsiSnippet < Snippet

          def render(context)
            @context = context
            @template_name = evaluate_snippet_name(context)
            if not defined?(Rails)
                # We are using wagon without varnish
                # esi_include is automatically processed like an include
                process_esi = ENV.fetch('WAGON_ESI', 'false').downcase == "true"
            else
                process_esi = !@context.registers[:live_editing]
            end
            if process_esi
              "<esi:include src=\"#{snippet_path}\"/>"
            else
              super
            end
          end

          private

          def snippet_path
            default_locale = site.default_locale.to_sym
            same_locale = locale == default_locale

            if site.prefix_default_locale || !same_locale
              "/#{locale}/snippet/#{@template_name}"
            else
              "/snippet/#{@template_name}"
            end
          end

          def locale
            @locale ||= @context.registers[:locale]
          end

          def site
            @site ||= @context.registers[:site]
          end

          ::Liquid::Template.register_tag('esi_include'.freeze, EsiSnippet)
        end

      end
    end
  end
end
