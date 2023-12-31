Api::PagePresenter = Struct.new(:page, :context) do
  def as_json(_options = {})
    {
      results: page.map(&:as_json),
      previous_page_url:,
      next_page_url:,
      current_page: page.current_page,
      total: page.total_count,
      pages: page.total_pages,
      page_size: page.limit_value,
      start_index:,
    }.reject { |_k, v| v.nil? }
  end

  def links
    links = []
    links << [previous_page_url, { "rel" => "previous" }] if previous_page_url
    links << [next_page_url, { "rel" => "next" }] if next_page_url
    links << [url(page: page.current_page), { "rel" => "self" }]
    links
  end

  def previous_page_url
    unless page.first_page?
      url(page: page.current_page - 1)
    end
  end

  def next_page_url
    if !page.last_page? && !page.out_of_range?
      url(page: page.current_page + 1)
    end
  end

  def start_index
    # current_page and start_index start at 1, not 0
    (page.current_page - 1) * page.limit_value + 1
  end

private

  def url(override_params)
    context.url_for(context.params.permit(
      :controller,
      :format,
      :action,
      :world_location_id,
      :page,
    ).merge(
      override_params.merge(only_path: false),
    ))
  end
end
