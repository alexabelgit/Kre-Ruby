class Admin::AbuseReportsController < AdminController
  before_action :set_abuse_report, only: [ :show ]

  add_breadcrumb "Admin",        :admin_root_path
  add_breadcrumb "ContentGuard", :admin_abuse_reports_path

  def index
    @status        = params[:status].present? ? params[:status] : :open
    @abuse_reports = AbuseReport.where(status: @status).order(created_at: :desc).paginate(page: params[:page], per_page: 100)
    @counts        = AbuseReport.statuses.map { |s, e| [s, AbuseReport.where(status: s).count ] }.to_h
  end

  def show
    add_breadcrumb @abuse_report.hashid, admin_abuse_report_path(@abuse_report)
  end

  private

  def set_abuse_report
    @abuse_report = AbuseReport.find_by_hashid(params[:id])
  end
end
