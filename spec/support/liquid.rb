def render_template(source, context = nil, options = {})
  context ||= ::Liquid::Context.new
  context.exception_handler = ->(e) { true }
  Locomotive::Steam::Liquid::Template.parse(source, options).render(context)
end
