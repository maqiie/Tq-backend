# class Employees::AgentsController < ApplicationController
#   before_action :authenticate_employee!  # Ensure employee is authenticated

#   def create
#     # Ensure the agent is created by the current authenticated employee
#     @agent = current_employee.agents.new(agent_params)

#     if @agent.save
#       render json: { message: 'Agent created successfully', agent: @agent }, status: :created
#     else
#       render json: { errors: @agent.errors.full_messages }, status: :unprocessable_entity
#     end
#   end

#   def create_transaction
#     @agent = current_employee.agents.find(params[:agent_id])  # Ensure agent belongs to the authenticated employee
#     yesterday_closing_balance = @agent.transactions.where(date: Date.yesterday).pluck(:closing_balance).last

#     if yesterday_closing_balance && transaction_params[:opening_balance].to_f != yesterday_closing_balance
#       render json: { errors: ["Opening balance must match the closing balance from yesterday"] }, status: :unprocessable_entity
#       return
#     end

#     @transaction = @agent.transactions.new(transaction_params)

#     if @transaction.save
#       render json: { message: 'Transaction created successfully', transaction: @transaction }, status: :created
#     else
#       render json: { errors: @transaction.errors.full_messages }, status: :unprocessable_entity
#     end
#   end

#   private

#   def agent_params
#     params.require(:agent).permit(:name, :type_of_agent)
#   end

#   def transaction_params
#     params.require(:transaction).permit(:opening_balance, :closing_balance, :date)
#   end
# end


class Employees::AgentsController < ApplicationController
  before_action :authenticate_employee!  # Ensure employee is authenticated

  def create
    # Ensure the agent is created by the current authenticated employee
    @agent = current_employee.agents.new(agent_params)

    if @agent.save
      render json: { message: 'Agent created successfully', agent: @agent }, status: :created
    else
      render json: { errors: @agent.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def create_transaction
    # Make sure we use `params[:id]` since the route is defined to expect `:id`
    @agent = current_employee.agents.find(params[:id])  # Ensure agent belongs to the authenticated employee
    
    yesterday_closing_balance = @agent.transactions.where(date: Date.yesterday).pluck(:closing_balance).last

    if yesterday_closing_balance && transaction_params[:opening_balance].to_f != yesterday_closing_balance
      render json: { errors: ["Opening balance must match the closing balance from yesterday"] }, status: :unprocessable_entity
      return
    end

    @transaction = @agent.transactions.new(transaction_params)

    if @transaction.save
      render json: { message: 'Transaction created successfully', transaction: @transaction }, status: :created
    else
      render json: { errors: @transaction.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  def agent_params
    params.require(:agent).permit(:name, :type_of_agent)
  end

  def transaction_params
    params.require(:transaction).permit(:opening_balance, :closing_balance, :date)
  end
end
