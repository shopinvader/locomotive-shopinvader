def render_template(source, context = nil, options = {})
  context ||= ::Liquid::Context.new
  context.exception_renderer = ->(e) do
    # puts e.message # UN-COMMENT IT FOR DEBUGGING
    raise e
  end
  Locomotive::Steam::Liquid::Template.parse(source, options).render(context)
end
