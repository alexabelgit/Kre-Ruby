class Back::AbuseReportsController < BackController

  before_action :set_abuse_report, only: [ :show, :update ]
  before_action :set_abusable,     only: [ :create ]

  def index
    @status        = params[:status].present? ? params[:status] : :open
    @abuse_reports = current_store.abuse_reports.where(status: @status).latest.paginate(page: params[:page], per_page: 20)
    @counts        = AbuseReport.statuses.map { |s, e| [s, @store.abuse_reports.where(status: s).count ] }.to_h
    respond_to do |format|
      format.html
      format.js
    end
  end

  def new
    abusable_type = params[:type]
    abusable_id   = params[:id]

    if abusable_type.present? && abusable_id.present?
      @abusable = abusable_type.constantize.find(abusable_id)
    end

    not_found if @abusable.nil? || @abusable.store != current_store

    @abuse_report = AbuseReport.new()
  end

  def create
    if @abusable.present?
      @abuse_report          = @abusable.abuse_reports.new(abuse_report_params)
      @abuse_report.source   = :by_merchant
      @abuse_report.decision = :accepted

      respond_to do |format|
        if @abuse_report.save
          format.html do
            flash[:success] = "#{ @abusable.class.name } was successfully reported as inappropriate."
            redirect_to back_abuse_reports_path
          end
        else
          format.html { render :new }
        end
      end
    else
      not_found
    end

  end

  def show
  end

  def update
    return unless AbuseReport.decisions_updatable_to.any? { |s| s == abuse_report_params[:decision] }

    if @abuse_report.update_attributes(abuse_report_params)
      if @abuse_report.accepted?
        flash[:info] = "Report has been successfully resolved. Reported #{ @abuse_report.abusable_type.downcase } has been suppressed an unpublished from your website."
      elsif @abuse_report.rejected?
        flash[:info] = "Report has been successfully resolved. Reported #{ @abuse_report.abusable_type.downcase } was not affected."
      end

      redirect_to back_abuse_reports_path

    end

  end

  def filters
  end

  private

  def set_abuse_report
    @abuse_report = current_store.abuse_reports.find_by_hashid(params[:id])
  end

  def set_abusable
    if abuse_report_params[:abusable_type].present? && abuse_report_params[:abusable_id].present?
      @abusable = abuse_report_params[:abusable_type].constantize.find(abuse_report_params[:abusable_id])
      if @abusable.store != current_store
        @abusable = nil
      end
    end
  end

  def abuse_report_params
    params.require(:abuse_report).permit(:reason, :additional_info, :abusable_id, :abusable_type, :decision)
  end

end
