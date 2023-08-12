class Admin::LinkCheckReportsController < Admin::BaseController
  before_action :find_reportable

  def create
    @report = LinkCheckerApiService.check_links(
      @reportable,
      admin_link_checker_api_callback_url,
      checked_within: 1.second,
    )

    respond_to do |format|
      format.js
      format.html { redirect_to [:admin, @reportable] }
      format.json { render :show }
    end
  end

  def show
    @report = LinkCheckerApiReport.find(params[:id])
    @allow_new_report = params[:allow_new_report] || false

    respond_to do |format|
      format.js
      format.html { redirect_to [:admin, @reportable] }
      format.json
    end
  end

private

  def find_reportable
    @reportable = Edition.find(params[:edition_id])
  end
end
