require 'csv'

class Admin::CommissionsController < ApplicationController
  before_action :authenticate_admin!

  # POST /admin/agents/:agent_id/commissions
  def create
    @agent = Agent.find(params[:agent_id])
    @commission = @agent.commissions.new(commission_params)
    
    if @commission.save
      render json: { message: 'Commission created successfully', commission: @commission }, status: :created
    else
      render json: { errors: @commission.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # GET /admin/agents/:agent_id/commissions/download
  def download
    @agent = Agent.find(params[:agent_id])
    start_date = Date.parse(params[:start_date]) rescue nil
    end_date = Date.parse(params[:end_date]) rescue nil
    
    commissions = @agent.commissions
    commissions = commissions.where("created_at >= ?", start_date) if start_date
    commissions = commissions.where("created_at <= ?", end_date) if end_date

    csv_data = CSV.generate(headers: true) do |csv|
      csv << ['ID', 'Amount', 'Month', 'Year', 'Created At', 'Updated At']
      commissions.each do |commission|
        csv << [
          commission.id,
          commission.amount,
          commission.month,
          commission.year,
          commission.created_at,
          commission.updated_at
        ]
      end
    end

    send_data csv_data, filename: "commissions_#{@agent.id}_#{start_date}_to_#{end_date}.csv", type: 'text/csv'
  end

  # GET /admin/commissions or /admin/agents/:agent_id/commissions
  def index
    if params[:agent_id].present?
      agent = Agent.find_by(id: params[:agent_id])
      return render json: { error: 'Agent not found' }, status: :not_found unless agent

      commissions = agent.commissions
    else
      commissions = Commission.includes(:agent).all
    end

    render json: commissions, status: :ok
  end

  private

  def commission_params
    params.require(:commission).permit(:amount, :month, :year)
  end
end
