
class Employees::AgentsController < ApplicationController
  before_action :authenticate_employee!
  
  # GET /employees/agents
  def index
    agents = current_user.accessible_agents  # ← FIXED
    render json: agents
  end
  
  def create
    # Employees cannot create agents - only admins can
    # But if you want employees to create agents for their admin:
    @agent = current_user.admin.agents.new(agent_params)
    if @agent.save
      render json: { message: 'Agent created successfully', agent: @agent }, status: :created
    else
      render json: { errors: @agent.errors.full_messages }, status: :unprocessable_entity
    end
  end
  
  def create_transaction
    # Find agent from accessible agents only
    @agent = current_user.accessible_agents.find(params[:id])  # ← FIXED
    
    yesterday_closing_balance = @agent.transactions.where(date: Date.yesterday).pluck(:closing_balance).last
    if yesterday_closing_balance && transaction_params[:opening_balance].to_f != yesterday_closing_balance
      render json: { errors: ["Opening balance must match the closing balance from yesterday"] }, status: :unprocessable_entity
      return
    end
    
    @transaction = @agent.transactions.new(transaction_params)
    @transaction.creator_id = current_user.id  # Track who created it
    
    if @transaction.save
      render json: { message: 'Transaction created successfully', transaction: @transaction }, status: :created
    else
      render json: { errors: @transaction.errors.full_messages }, status: :unprocessable_entity
    end
  end
  
  def transactions
    @agent = current_user.accessible_agents.find(params[:id])  # ← FIXED
    @transactions = @agent.transactions.order(date: :desc)
    render json: @transactions
  end
  
  def latest
    @agent = current_user.accessible_agents.find(params[:id])  # ← FIXED
    last_transaction = @agent.transactions.order(date: :desc).first
  
    if last_transaction
      render json: {
        id: last_transaction.id,
        opening_balance: last_transaction.opening_balance,
        closing_balance: last_transaction.closing_balance,
        date: last_transaction.date,
        notes: last_transaction.notes,
        creator_id: last_transaction.creator_id
      }
    else
      render json: { message: "No transactions found", closing_balance: 0.0 }
    end
  end
  
  private
  
  def agent_params
    params.require(:agent).permit(:name, :type_of_agent, :email, :phone)
  end
  
  def transaction_params
    params.require(:transaction).permit(:opening_balance, :closing_balance, :date, :notes)
  end
end
# class Employees::AgentsController < ApplicationController
#   before_action :authenticate_employee!  # Ensure employee is authenticated

  
#   # GET /employees/agents
#   def index
#     agents = Agent.all
#     render json: agents
#   end
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
#     # Make sure we use `params[:id]` since the route is defined to expect `:id`
#     @agent = current_employee.agents.find(params[:id])  # Ensure agent belongs to the authenticated employee
    
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

#   def transactions
#     @agent = current_employee.agents.find(params[:id])
#     @transactions = @agent.transactions.order(date: :desc)
#     render json: @transactions
#   end
  
#   def latest
#     @agent = current_employee.agents.find(params[:id]) # Ensure agent belongs to logged-in employee
#     last_transaction = @agent.transactions.order(date: :desc).first
  
#     if last_transaction
#       render json: {
#         id: last_transaction.id,
#         opening_balance: last_transaction.opening_balance,
#         closing_balance: last_transaction.closing_balance,
#         date: last_transaction.date,
#         notes: last_transaction.notes,
#         creator_id: last_transaction.creator_id
#       }
#     else
#       render json: { message: "No transactions found", closing_balance: 0.0 }
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
