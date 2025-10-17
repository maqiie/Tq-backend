module Admin
  class DebtorsController < ApplicationController
    before_action :authenticate_user!
    before_action :ensure_admin!

    def index
      # Get only debtors for agents owned by current user
      agent_ids = current_user.accessible_agents.pluck(:id)
      @debtors = Debtor.where(agent_id: agent_ids).includes(:agent)
      
      render json: @debtors.as_json(include: :agent)
    end
    
    def show
      agent_ids = current_user.accessible_agents.pluck(:id)
      @debtor = Debtor.where(agent_id: agent_ids).find(params[:id])
      
      render json: @debtor.as_json(include: :agent)
    end
    
    def create
      # Ensure the agent belongs to the current user
      agent = current_user.accessible_agents.find(debtor_params[:agent_id])
      @debtor = agent.debtors.new(debtor_params.except(:agent_id))
      
      if @debtor.save
        render json: @debtor, status: :created
      else
        render json: { errors: @debtor.errors.full_messages }, status: :unprocessable_entity
      end
    end
    
    def update
      agent_ids = current_user.accessible_agents.pluck(:id)
      @debtor = Debtor.where(agent_id: agent_ids).find(params[:id])
      
      if @debtor.update(debtor_params)
        render json: @debtor
      else
        render json: { errors: @debtor.errors.full_messages }, status: :unprocessable_entity
      end
    end
    
    def destroy
      agent_ids = current_user.accessible_agents.pluck(:id)
      @debtor = Debtor.where(agent_id: agent_ids).find(params[:id])
      
      if @debtor.destroy
        render json: { message: 'Debtor deleted successfully' }
      else
        render json: { errors: @debtor.errors.full_messages }, status: :unprocessable_entity
      end
    end

    private
    
    def debtor_params
      params.require(:debtor).permit(:agent_id, :name, :debt_amount, :notes)
    end

    def ensure_admin!
      render json: { error: "Unauthorized" }, status: :unauthorized unless current_user&.admin?
    end
  end
end
# module Admin
#     class DebtorsController < ApplicationController
#       before_action :authenticate_user!
#       before_action :ensure_admin!
  
#       def index
#         @debtors = Debtor.all.includes(:agent)
#         render json: @debtors.as_json(include: :agent)
#       end
  
#       private
  
#       def ensure_admin!
#         render json: { error: "Unauthorized" }, status: :unauthorized unless current_user&.admin?
#       end
#     end
#   end
  