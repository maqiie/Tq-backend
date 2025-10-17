
class Employees::CommissionsController < ApplicationController
  before_action :authenticate_employee!
  before_action :set_commission, only: [:show, :update, :destroy]
  
  # GET /employees/commissions?month=7&year=2025
  def index
    month = params[:month].to_i
    year = params[:year].to_i
    agent_ids = current_user.accessible_agents.pluck(:id)  # ← FIXED
    
    commissions = Commission.includes(:agent)
                            .where(agent_id: agent_ids)  # ← FIXED
                            .where(month: month, year: year)
    
    render json: commissions.map { |c|
      {
        id: c.id,
        amount: c.amount,
        month: c.month,
        year: c.year,
        agent_name: c.agent.name
      }
    }, status: :ok
  end
  
  # GET /employees/commissions/:id
  def show
    render json: commission_json(@commission), status: :ok
  end
  
  # POST /employees/commissions
  def create
    @agent = current_user.accessible_agents.find_by(id: commission_params[:agent_id])  # ← FIXED
    return render json: { error: 'Agent not found' }, status: :not_found unless @agent
    
    @commission = @agent.commissions.new(commission_params.except(:agent_id))
    
    if @commission.save
      render json: commission_json(@commission), status: :created
    else
      render json: { errors: @commission.errors.full_messages }, status: :unprocessable_entity
    end
  end
  
  # PUT /employees/commissions/:id
  def update
    if @commission.update(commission_params.except(:agent_id))
      render json: commission_json(@commission), status: :ok
    else
      render json: { errors: @commission.errors.full_messages }, status: :unprocessable_entity
    end
  end
  
  # DELETE /employees/commissions/:id
  def destroy
    @commission.destroy
    head :no_content
  end
  
  private
  
  def set_commission
    agent_ids = current_user.accessible_agents.pluck(:id)  # ← FIXED
    @commission = Commission.where(agent_id: agent_ids).find(params[:id])  # ← FIXED
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Commission not found' }, status: :not_found
  end
  
  def commission_params
    params.require(:commission).permit(:agent_id, :amount, :month, :year)
  end
  
  def commission_json(commission)
    {
      id: commission.id,
      amount: commission.amount,
      month: commission.month,
      year: commission.year,
      agent_name: commission.agent&.name
    }
  end
end

# class Employees::CommissionsController < ApplicationController
#   before_action :authenticate_employee!
#   before_action :set_commission, only: [:show, :update, :destroy]

#   # GET /employees/commissions?month=7&year=2025
#   def index
#     month = params[:month].to_i
#     year = params[:year].to_i

#     commissions = Commission.includes(:agent)
#                             .where(month: month, year: year)

#     render json: commissions.map { |c|
#       {
#         id: c.id,
#         amount: c.amount,
#         month: c.month,
#         year: c.year,
#         # Only include description and date if columns exist in your model
#         # description: c.respond_to?(:description) ? c.description : nil,
#         # date: c.respond_to?(:date) ? c.date : nil,
#         agent_name: c.agent.name
#       }
#     }, status: :ok
#   end

#   # GET /employees/commissions/:id
#   def show
#     render json: commission_json(@commission), status: :ok
#   end

#   # POST /employees/commissions
#   def create
#     @agent = Agent.find_by(id: commission_params[:agent_id])
#     return render json: { error: 'Agent not found' }, status: :not_found unless @agent

#     @commission = @agent.commissions.new(commission_params.except(:agent_id))

#     if @commission.save
#       render json: commission_json(@commission), status: :created
#     else
#       render json: { errors: @commission.errors.full_messages }, status: :unprocessable_entity
#     end
#   end

#   # PUT /employees/commissions/:id
#   def update
#     if @commission.update(commission_params.except(:agent_id))
#       render json: commission_json(@commission), status: :ok
#     else
#       render json: { errors: @commission.errors.full_messages }, status: :unprocessable_entity
#     end
#   end

#   # DELETE /employees/commissions/:id
#   def destroy
#     @commission.destroy
#     head :no_content
#   end

#   private

#   def set_commission
#     @commission = Commission.find(params[:id])
#   rescue ActiveRecord::RecordNotFound
#     render json: { error: 'Commission not found' }, status: :not_found
#   end

#   def commission_params
#     params.require(:commission).permit(:agent_id, :amount, :month, :year)
#   end

#   def commission_json(commission)
#     {
#       id: commission.id,
#       amount: commission.amount,
#       month: commission.month,
#       year: commission.year,
#       # Only if description/date fields exist, otherwise comment/remove:
#       # description: commission.respond_to?(:description) ? commission.description : nil,
#       # date: commission.respond_to?(:date) ? commission.date : nil,
#       agent_name: commission.agent&.name
#     }
#   end
# end
