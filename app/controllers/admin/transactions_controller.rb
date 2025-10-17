require 'csv'

class Admin::TransactionsController < ApplicationController
  before_action :authenticate_user!
  
  def index
    # Get only transactions for agents owned by current user
    agent_ids = current_user.accessible_agents.pluck(:id)
    @transactions = Transaction.includes(:agent)
                               .where(agent_id: agent_ids)
                               .order(created_at: :desc)
    
    # Include agent information with each transaction
    transactions_with_agents = @transactions.map do |transaction|
      transaction_data = transaction.as_json
      
      if transaction.agent
        transaction_data['agent'] = {
          id: transaction.agent.id,
          name: transaction.agent.name,
          type_of_agent: transaction.agent.type_of_agent,
          email: transaction.agent.email,
          phone: transaction.agent.phone,
          code: "AGT#{transaction.agent.id.to_s.rjust(3, '0')}"
        }
      else
        transaction_data['agent'] = {
          id: transaction.agent_id,
          name: 'Unknown Agent',
          type_of_agent: 'Unknown',
          email: 'N/A',
          phone: 'N/A',
          code: "AGT#{transaction.agent_id.to_s.rjust(3, '0')}"
        }
      end
      
      transaction_data
    end
    
    render json: transactions_with_agents
  end
  
  def show
    agent_ids = current_user.accessible_agents.pluck(:id)
    @transaction = Transaction.where(agent_id: agent_ids).find(params[:id])
    render json: @transaction
  end
  
  def create
    # Ensure the agent belongs to the current user
    agent = current_user.accessible_agents.find(transaction_params[:agent_id])
    @transaction = agent.transactions.new(transaction_params.except(:agent_id))
    
    if @transaction.save
      render json: @transaction, status: :created
    else
      render json: { errors: @transaction.errors }, status: :unprocessable_entity
    end
  end
  
  def download
    # Get only transactions for agents owned by current user
    agent_ids = current_user.accessible_agents.pluck(:id)
    @transactions = Transaction.where(agent_id: agent_ids).includes(:agent)
    
    send_data generate_csv(@transactions), filename: "transactions-#{Date.today}.csv"
  end
  
  private
  
  def transaction_params
    params.require(:transaction).permit(:agent_id, :opening_balance, :closing_balance, :date, :notes, :balance_type)
  end
  
  def generate_csv(transactions)
    CSV.generate(headers: true) do |csv|
      csv << ['Agent ID', 'Agent Name', 'Opening Balance', 'Closing Balance', 'Date']
      transactions.each do |transaction|
        csv << [
          transaction.agent_id, 
          transaction.agent&.name || 'Unknown',
          transaction.opening_balance, 
          transaction.closing_balance, 
          transaction.date
        ]
      end
    end
  end
end
# class Admin::TransactionsController < ApplicationController
#   before_action :authenticate_admin!, except: [:index] # Allow index for API access
  
#   def index
#     @transactions = Transaction.includes(:agent).all.order(created_at: :desc)
    
#     # Include agent information with each transaction
#     transactions_with_agents = @transactions.map do |transaction|
#       transaction_data = transaction.as_json
      
#       if transaction.agent
#         transaction_data['agent'] = {
#           id: transaction.agent.id,
#           name: transaction.agent.name,
#           type_of_agent: transaction.agent.type_of_agent,
#           email: transaction.agent.email,
#           phone: transaction.agent.phone,
#           code: "AGT#{transaction.agent.id.to_s.rjust(3, '0')}" # Generate code from ID
#         }
#       else
#         transaction_data['agent'] = {
#           id: transaction.agent_id,
#           name: 'Unknown Agent',
#           type_of_agent: 'Unknown',
#           email: 'N/A',
#           phone: 'N/A',
#           code: "AGT#{transaction.agent_id.to_s.rjust(3, '0')}"
#         }
#       end
      
#       transaction_data
#     end
    
#     render json: transactions_with_agents
#   end
  
#   def show
#     @transaction = Transaction.find(params[:id])
#     render json: @transaction
#   end
  
#   def create
#     @transaction = Transaction.new(transaction_params)
    
#     if @transaction.save
#       render json: @transaction, status: :created
#     else
#       render json: { errors: @transaction.errors }, status: :unprocessable_entity
#     end
#   end
  
#   def download
#     # Here, you could generate a CSV or other format for transactions
#     @transactions = Transaction.all
#     send_data generate_csv(@transactions), filename: "transactions-#{Date.today}.csv"
#   end
  
#   private
  
#   def transaction_params
#     params.require(:transaction).permit(:agent_id, :opening_balance, :closing_balance, :date, :notes, :balance_type)
#   end
  
#   def generate_csv(transactions)
#     CSV.generate(headers: true) do |csv|
#       csv << ['Agent ID', 'Opening Balance', 'Closing Balance', 'Date']
#       transactions.each do |transaction|
#         csv << [transaction.agent_id, transaction.opening_balance, transaction.closing_balance, transaction.date]
#       end
#     end
#   end
# end