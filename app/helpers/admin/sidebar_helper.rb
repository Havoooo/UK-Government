module Admin::SidebarHelper
  def simple_formatting_sidebar(options = {})
    if current_user.has_permission? "Preview design system"
      sidebar_content = []
      sidebar_content << render("admin/editions/govspeak_help", options)
      sidebar_content << render("admin/editions/style_guidance", options)
      raw sidebar_content.join("\n")
    else
      sidebar_tabs govspeak_help: "Help" do |tabs|
        tabs.pane id: "govspeak_help", class: "govspeak_help" do
          tab_content = []
          tab_content << render("admin/editions/govspeak_help_legacy", options)
          tab_content << render("admin/editions/words_to_avoid_guidance")
          tab_content << tag.h3("Style", class: "style-title")
          tab_content << tag.p do
            raw %(For style, see the #{link_to('style guide', 'https://www.gov.uk/guidance/style-guide')})
          end
          raw tab_content.join("\n")
        end
      end
    end
  end

  def edition_tabs(edition, options = {})
    options = { editing: false, history_count: 0, remarks_count: 0 }.merge(options)
    {}.tap do |tabs|
      if options[:editing]
        tabs[:govspeak_help] = "Help"
      end
      tabs[:notes] = ["Notes", options[:remarks_count]]
      tabs[:history] = ["History", options[:history_count]]
      if edition.can_be_fact_checked?
        tabs[:fact_checking] = ["Fact checking", edition.all_completed_fact_check_requests.count]
      end
    end
  end

  def sidebar_tabs(tabs, options = {})
    tab_tags = tabs.map.with_index do |(id, tab_content), index|
      link_content = case tab_content
                     when String
                       tab_content
                     when Array
                       text = tab_content[0]
                       badge_content = tab_content[1]
                       badge_type = tab_content[2]
                       if badge_content
                         badge_class = badge_type ? "badge badge-#{badge_type}" : "badge"
                         "#{text} #{tag.span(badge_content, class: badge_class)}".html_safe
                       else
                         text
                       end
                     end
      link = tag.a(link_content, href: "##{id}", "data-toggle": "tab")
      tag.li(link, class: (index.zero? ? "active" : nil))
    end
    tag.div(class: ["sidebar tabbable", options[:class]].compact.join(" ")) do
      tag.ul(class: "nav nav-tabs add-bottom-margin") { tab_tags.join.html_safe } +
        tag.div(class: "tab-content") { yield TabPaneState.new(self) }
    end
  end
end
