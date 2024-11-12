class Employees::CommissionsController < ApplicationController
  before_action :authenticate_employee!  # Ensure employee is authenticated

  def create
    @agent = Agent.find(params[:agent_id])
    @commission = @agent.commissions.new(commission_params)

    if @commission.save
      render json: { message: 'Commission created successfully', commission: @commission }, status: :created
    else
      render json: { errors: @commission.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  def commission_params
    params.require(:commission).permit(:amount, :month, :year)
  end
end
