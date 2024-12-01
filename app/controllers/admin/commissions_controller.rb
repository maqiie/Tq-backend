require 'csv'

class Admin::CommissionsController < ApplicationController
  before_action :authenticate_admin!

  # Existing create action
  def create
    @agent = Agent.find(params[:agent_id])
    @commission = @agent.commissions.new(commission_params)
    
    if @commission.save
      render json: { message: 'Commission created successfully', commission: @commission }, status: :created
    else
      render json: { errors: @commission.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # New download action
  def download
    @agent = Agent.find(params[:agent_id])
    start_date = Date.parse(params[:start_date]) rescue nil
    end_date = Date.parse(params[:end_date]) rescue nil
    
    # Filter commissions based on date range
    commissions = @agent.commissions
    commissions = commissions.where("created_at >= ?", start_date) if start_date
    commissions = commissions.where("created_at <= ?", end_date) if end_date

    # Generate CSV
    csv_data = CSV.generate(headers: true) do |csv|
      csv << ['ID', 'Amount', 'Month', 'Year', 'Created At', 'Updated At']
      commissions.each do |commission|
        csv << [commission.id, commission.amount, commission.month, commission.year, commission.created_at, commission.updated_at]
      end
    end

    # Send CSV as a file download
    send_data csv_data, filename: "commissions_#{@agent.id}_#{start_date}_to_#{end_date}.csv", type: 'text/csv'
  end

  # New index action to get all commissions for an agent
  def index
    @agent = Agent.find(params[:agent_id])
    @commissions = @agent.commissions

    render json: @commissions, status: :ok
  end

  private

  def commission_params
    params.require(:commission).permit(:amount, :month, :year)
  end
end
