module Admin
  class AgentsController < ApplicationController
    before_action :authenticate_admin!

    # GET /admin/agents
    def index
      @agents = Agent.all
      @total_cashpoint = Agent.joins(:agent_transactions).sum(:closing_balance)
      render json: { agents: @agents, total_cashpoint: @total_cashpoint }
    end

    # POST /admin/agents
    def create
      @agent = Agent.new(agent_params)
      @agent.user = current_user

      if @agent.save
        render json: { message: 'Agent created successfully', agent: @agent }, status: :created
      else
        render json: { errors: @agent.errors.full_messages }, status: :unprocessable_entity
      end
    end

    # POST /admin/agents/:agent_id/transactions
    def add_transaction
      @agent = Agent.find(params[:agent_id])
      @transaction = @agent.agent_transactions.new(transaction_params)

      if @transaction.save
        render json: { message: 'Transaction added successfully', transaction: @transaction }, status: :created
      else
        render json: { errors: @transaction.errors.full_messages }, status: :unprocessable_entity
      end
    end

    private

    def agent_params
      params.require(:agent).permit(:name, :type_of_agent)  # type_of_agent could be 'Bank' or 'Mobile Provider'
    end

    def transaction_params
      params.require(:agent_transaction).permit(:closing_balance)  # opening_balance is set automatically
    end

    def authenticate_admin!
      render json: { error: 'You must be an admin to perform this action.' }, status: :forbidden unless current_user&.admin?
    end
  end
end
