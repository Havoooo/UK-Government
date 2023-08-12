class Admin::WorldLocationNewsController < Admin::BaseController
  before_action :load_world_location, only: %i[edit update show features]
  layout "design_system"

  def edit
    build_featured_link_if_none_present
  end

  def show; end

  def index
    @active_world_locations, @inactive_world_locations = WorldLocation.ordered_by_name.partition(&:active?)
  end

  def update
    if @world_location_news.update(world_location_news_params)
      redirect_to [:admin, @world_location_news], notice: "World location updated successfully"
    else
      build_featured_link_if_none_present
      render :edit
    end
  end

  def features
    @feature_list = @world_location.world_location_news.load_or_create_feature_list(params[:locale])
    @locale = Locale.new(params[:locale] || :en)

    filter_params = default_filter_params.merge(
      optional_filter_params,
      state: "published",
      per_page: preview_design_system?(next_release: false) ? Admin::EditionFilter::GOVUK_DESIGN_SYSTEM_PER_PAGE : nil,
    )

    @filter = Admin::EditionFilter.new(Edition, current_user, filter_params)
    @featurable_topical_events = TopicalEvent.active
    @featurable_offsite_links = @world_location.world_location_news.offsite_links

    if request.xhr?
      render partial: "admin/feature_lists/legacy_search_results", locals: { feature_list: @feature_list }
    else
      render :features
    end
  end

private

  def default_filter_params
    {
      world_location: @world_location.id,
    }
  end

  def optional_filter_params
    params.slice(:page, :type, :world_location, :title).permit!.to_h.symbolize_keys
  end

  def load_world_location
    @world_location = WorldLocation.friendly.find(params[:id])
    @world_location_news = @world_location.world_location_news
  end

  def world_location_news_params
    params.require(:world_location_news).permit(
      :mission_statement,
      :title,
      featured_links_attributes: %i[url title id _destroy],
      world_location_attributes: %i[active id world_location_type],
    )
  end

  def build_featured_link_if_none_present
    @world_location_news.featured_links.new if @world_location_news.featured_links.blank?
  end
end
