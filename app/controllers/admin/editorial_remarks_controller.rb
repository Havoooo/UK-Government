class Admin::EditorialRemarksController < Admin::BaseController
  before_action :find_edition
  before_action :enforce_permissions!
  before_action :limit_edition_access!
  layout "design_system"

  def enforce_permissions!
    case action_name
    when "confirm_destroy", "destroy"
      enforce_permission!(:perform_administrative_tasks, @edition)
    else
      enforce_permission!(:make_editorial_remark, @edition)
    end
  end

  def new
    @editorial_remark = @edition.editorial_remarks.build
  end

  def create
    @editorial_remark = @edition.editorial_remarks.build(editorial_remark_params)
    if @editorial_remark.save
      redirect_to admin_edition_path(@edition)
    else
      render :new
    end
  end

  def confirm_destroy; end

  def destroy
    @editorial_remark.destroy!
    redirect_to admin_edition_path(@edition), notice: "Editorial remark deleted successfully"
  end

private

  def find_edition
    if params[:id]
      @editorial_remark = EditorialRemark.find(params[:id])
      @edition = @editorial_remark.edition
    else
      @edition = Edition.find(params[:edition_id])
    end
  end

  def editorial_remark_params
    params.require(:editorial_remark).permit(:body).merge(author: current_user)
  end
end
