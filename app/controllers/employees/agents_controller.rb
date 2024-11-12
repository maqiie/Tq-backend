class Employees::AgentsController < ApplicationController
  before_action :authenticate_employee!  # Ensure employee is authenticated

  def create_transaction
    @agent = Agent.find(params[:agent_id])
    @transaction = @agent.transactions.new(transaction_params)

    if @transaction.save
      render json: { message: 'Transaction created successfully', transaction: @transaction }, status: :created
    else
      render json: { errors: @transaction.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  def transaction_params
    params.require(:transaction).permit(:opening_balance, :closing_balance, :date)
  end
end
