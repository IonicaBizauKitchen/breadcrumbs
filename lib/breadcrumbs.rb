module Breadcrumbs

  module InstanceMethods

    protected

    # Append a breadcrumb to the end of the trail
    def add_crumb(name, url = nil)
      @breadcrumbs ||= []
      url = send(url) if url.is_a?(Symbol)
      url = polymorphic_path(url) if url.is_a?(ActiveRecord::Base) || url.is_a?(Array) # AR object or array was passed in
      name = send(name).to_s.titleize if name.is_a?(Symbol)
      @breadcrumbs << [name, url]
    end

  end

  module ClassMethods

    # Append a breadcrumb to the end of the trail by deferring evaluation 
    # until the filter processing.
    def add_crumb(name, url = nil, options = {})
      before_filter(options) do |controller|
        controller.send(:add_crumb, name, url)
      end
    end

  end

  module HelperMethods

    # Returns HTML markup for the breadcrumbs
    def breadcrumbs(*args)
      return if @breadcrumbs.blank?
      default_options = {:separator => "/", :wrap_separator => true}
      options = default_options.merge(args.extract_options!)
      
      # Wrap separator in a list item?
      if options[:separator] && options[:wrap_separator]
        options[:separator] = content_tag(:li, options[:separator], :class => "separator")
      end
      
      # Build an array of list items
      items = []
      @breadcrumbs.each do |name, url|
        css = []
        css << "first" if @breadcrumbs.first.first == name
        css << "last" if @breadcrumbs.last.first == name
        link = url.blank? ? name : link_to_unless_current(name, url) # Don't create link if URL is blank
        items << content_tag(:li, link, :class => css.join(" "))
        items << options[:separator] if (options[:separator] && (@breadcrumbs.last.first != name)) # No separator on the end
      end

      content_tag(:ul, items.join("\n"), :class => "breadcrumbs")
    end

  end

end

class ActionController::Base
  include Breadcrumbs::InstanceMethods
  helper_method :add_crumb
end

ActionController::Base.extend(Breadcrumbs::ClassMethods)
ActionView::Base.send(:include, Breadcrumbs::HelperMethods)