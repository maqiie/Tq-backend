module Admin
  class AgentsController < ApplicationController
    before_action :authenticate_user!  # Enable authentication

    # GET /admin/agents
    def index
      @agents = current_user.accessible_agents.includes(:transactions)
      
      # Include calculated balance and recent transactions
      agents_with_data = @agents.map do |agent|
        agent_data = agent.as_json
        
        # Calculate current balance from latest transaction
        latest_transaction = agent.transactions.order(created_at: :desc).first
        current_balance = latest_transaction&.closing_balance || 0
        
        # Get recent transactions (last 5)
        recent_transactions = agent.transactions
                                  .order(created_at: :desc)
                                  .limit(5)
                                  .map do |transaction|
          {
            id: transaction.id,
            opening_balance: transaction.opening_balance,
            closing_balance: transaction.closing_balance,
            amount: (transaction.closing_balance.to_f - transaction.opening_balance.to_f),
            date: transaction.date || transaction.created_at,
            created_at: transaction.created_at
          }
        end
        
        agent_data.merge({
          balance: current_balance,
          transactions: recent_transactions,
          total_transactions: agent.transactions.count
        })
      end
      
      render json: agents_with_data
    end
    
    # GET /admin/agents/:id
    def show
      @agent = current_user.accessible_agents.includes(:transactions).find(params[:id])
      
      # Calculate current balance
      latest_transaction = @agent.transactions.order(created_at: :desc).first
      current_balance = latest_transaction&.closing_balance || 0
      
      # Get all transactions for this agent
      all_transactions = @agent.transactions
                              .order(created_at: :desc)
                              .map do |transaction|
        {
          id: transaction.id,
          opening_balance: transaction.opening_balance,
          closing_balance: transaction.closing_balance,
          amount: (transaction.closing_balance.to_f - transaction.opening_balance.to_f),
          date: transaction.date || transaction.created_at,
          created_at: transaction.created_at
        }
      end
      
      agent_data = @agent.as_json.merge({
        balance: current_balance,
        transactions: all_transactions,
        total_transactions: @agent.transactions.count
      })
      
      render json: agent_data
    end

    # POST /admin/agents
    def create
      @agent = Agent.new(agent_params)
      @agent.user = current_user  # THIS IS THE CRITICAL LINE - assigns the logged-in user

      if @agent.save
        render json: { message: 'Agent created successfully', agent: @agent }, status: :created
      else
        render json: { errors: @agent.errors.full_messages }, status: :unprocessable_entity
      end
    end
    
    # PATCH/PUT /admin/agents/:id
    def update
      @agent = current_user.accessible_agents.find(params[:id])
      
      if @agent.update(agent_params)
        render json: { message: 'Agent updated successfully', agent: @agent }, status: :ok
      else
        render json: { errors: @agent.errors.full_messages }, status: :unprocessable_entity
      end
    end
    
    # DELETE /admin/agents/:id
    def destroy
      @agent = current_user.accessible_agents.find(params[:id])
      
      if @agent.destroy
        render json: { message: 'Agent deleted successfully' }, status: :ok
      else
        render json: { errors: @agent.errors.full_messages }, status: :unprocessable_entity
      end
    end
    
    # GET /admin/agents/:id/transactions
    def transactions
      @agent = current_user.accessible_agents.find(params[:id])
      @transactions = @agent.transactions.order(created_at: :desc)
      
      transactions_data = @transactions.map do |transaction|
        {
          id: transaction.id,
          opening_balance: transaction.opening_balance,
          closing_balance: transaction.closing_balance,
          amount: (transaction.closing_balance.to_f - transaction.opening_balance.to_f),
          date: transaction.date || transaction.created_at,
          created_at: transaction.created_at,
          notes: transaction.notes
        }
      end
      
      render json: transactions_data
    end

    # POST /admin/agents/:agent_id/transactions
    def add_transaction
      @agent = current_user.accessible_agents.find(params[:agent_id])
      @transaction = @agent.transactions.build(transaction_params)

      if @transaction.save
        render json: { message: 'Transaction added successfully', transaction: @transaction }, status: :created
      else
        render json: { errors: @transaction.errors.full_messages }, status: :unprocessable_entity
      end
    end

    private

    def agent_params
      params.require(:agent).permit(:name, :type_of_agent, :email, :phone)
    end

    def transaction_params
      params.require(:agent_transaction).permit(:closing_balance)  # opening_balance is set automatically
    end

    def authenticate_admin!
      render json: { error: 'You must be an admin to perform this action.' }, status: :forbidden unless current_user&.admin?
    end
  end
end

# module Admin
#   class AgentsController < ApplicationController
#     # before_action :authenticate_admin!

#     # GET /admin/agents
#     def index
#       @agents = Agent.all
#       @total_cashpoint = Agent.joins(:agent_transactions).sum(:closing_balance)
#       render json: { agents: @agents, total_cashpoint: @total_cashpoint }
#     end

#     # POST /admin/agents
#     def create
#       @agent = Agent.new(agent_params)
#       @agent.user = current_user

#       if @agent.save
#         render json: { message: 'Agent created successfully', agent: @agent }, status: :created
#       else
#         render json: { errors: @agent.errors.full_messages }, status: :unprocessable_entity
#       end
#     end

#     # POST /admin/agents/:agent_id/transactions
#     def add_transaction
#       @agent = Agent.find(params[:agent_id])
#       @transaction = @agent.agent_transactions.new(transaction_params)

#       if @transaction.save
#         render json: { message: 'Transaction added successfully', transaction: @transaction }, status: :created
#       else
#         render json: { errors: @transaction.errors.full_messages }, status: :unprocessable_entity
#       end
#     end
#     def index
#       @agents = Agent.includes(:transactions).all
      
#       # Include calculated balance and recent transactions
#       agents_with_data = @agents.map do |agent|
#         agent_data = agent.as_json
        
#         # Calculate current balance from latest transaction
#         latest_transaction = agent.transactions.order(created_at: :desc).first
#         current_balance = latest_transaction&.closing_balance || 0
        
#         # Get recent transactions (last 5)
#         recent_transactions = agent.transactions
#                                   .order(created_at: :desc)
#                                   .limit(5)
#                                   .map do |transaction|
#           {
#             id: transaction.id,
#             opening_balance: transaction.opening_balance,
#             closing_balance: transaction.closing_balance,
#             amount: (transaction.closing_balance.to_f - transaction.opening_balance.to_f),
#             date: transaction.date || transaction.created_at,
#             created_at: transaction.created_at
#           }
#         end
        
#         agent_data.merge({
#           balance: current_balance,
#           transactions: recent_transactions,
#           total_transactions: agent.transactions.count
#         })
#       end
      
#       render json: agents_with_data
#     end
    
#     def show
#       @agent = Agent.includes(:transactions).find(params[:id])
      
#       # Calculate current balance
#       latest_transaction = @agent.transactions.order(created_at: :desc).first
#       current_balance = latest_transaction&.closing_balance || 0
      
#       # Get all transactions for this agent
#       all_transactions = @agent.transactions
#                               .order(created_at: :desc)
#                               .map do |transaction|
#         {
#           id: transaction.id,
#           opening_balance: transaction.opening_balance,
#           closing_balance: transaction.closing_balance,
#           amount: (transaction.closing_balance.to_f - transaction.opening_balance.to_f),
#           date: transaction.date || transaction.created_at,
#           created_at: transaction.created_at
#         }
#       end
      
#       agent_data = @agent.as_json.merge({
#         balance: current_balance,
#         transactions: all_transactions,
#         total_transactions: @agent.transactions.count
#       })
      
#       render json: agent_data
#     end
    
#     def create
#       @agent = Agent.new(agent_params)
      
#       if @agent.save
#         render json: @agent, status: :created
#       else
#         render json: { errors: @agent.errors }, status: :unprocessable_entity
#       end
#     end
    
#     # New endpoint for agent transactions
#     def transactions
#       @agent = Agent.find(params[:id])
#       @transactions = @agent.transactions.order(created_at: :desc)
      
#       transactions_data = @transactions.map do |transaction|
#         {
#           id: transaction.id,
#           opening_balance: transaction.opening_balance,
#           closing_balance: transaction.closing_balance,
#           amount: (transaction.closing_balance.to_f - transaction.opening_balance.to_f),
#           date: transaction.date || transaction.created_at,
#           created_at: transaction.created_at,
#           notes: transaction.notes
#         }
#       end
      
#       render json: transactions_data
#     end
    
#     def add_transaction
#       @agent = Agent.find(params[:agent_id])
#       @transaction = @agent.transactions.build(transaction_params)
      
#       if @transaction.save
#         render json: @transaction, status: :created
#       else
#         render json: { errors: @transaction.errors }, status: :unprocessable_entity
#       end
#     end

#     private

#     def agent_params
#       params.require(:agent).permit(:name, :type_of_agent, :email, :phone, :user_id)
#     end
#     def transaction_params
#       params.require(:agent_transaction).permit(:closing_balance)  # opening_balance is set automatically
#     end

#     def authenticate_admin!
#       render json: { error: 'You must be an admin to perform this action.' }, status: :forbidden unless current_user&.admin?
#     end
#   end
# end
