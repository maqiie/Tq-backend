# class Employees::CommissionsController < ApplicationController
#   before_action :authenticate_employee!
#   before_action :set_commission, only: [:show, :update, :destroy]

#   # GET /employees/commissions?month=7&year=2025
#   def index
#     month = params[:month].to_i
#     year = params[:year].to_i

#     @commissions = Commission.includes(:agent).where(month: month, year: year)

#     render json: @commissions.map { |c|
#       {
#         id: c.id,
#         amount: c.amount,
#         description: c.description,
#         date: c.date,
#         agent_name: c.agent.name
#       }
#     }, status: :ok
#   end

#   # GET /employees/commissions/:id
#   def show
#     render json: {
#       id: @commission.id,
#       amount: @commission.amount,
#       month: @commission.month,
#       year: @commission.year,
#       description: @commission.description,
#       date: @commission.date,
#       agent_name: @commission.agent.name
#     }, status: :ok
#   end

#   # POST /employees/commissions
#   def create
#     # Extract agent_id from the commission parameters
#     agent_id = commission_params[:agent_id]

#     @agent = Agent.find_by(id: agent_id)

#     unless @agent
#       Rails.logger.error "Agent not found with id: #{agent_id}"
#       render json: { error: "Agent not found" }, status: :not_found
#       return
#     end

#     @commission = @agent.commissions.new(commission_params)

#     if @commission.save
#       Rails.logger.info "Commission created successfully: #{@commission.id}"
#       render json: { message: 'Commission created successfully', commission: @commission }, status: :created
#     else
#       Rails.logger.error "Failed to create commission: #{@commission.errors.full_messages}"
#       render json: { errors: @commission.errors.full_messages }, status: :unprocessable_entity
#     end
#   end

#   # PUT /employees/commissions/:id
#   def update
#     if @commission.update(commission_params)
#       render json: { message: 'Commission updated successfully', commission: @commission }, status: :ok
#     else
#       render json: { errors: @commission.errors.full_messages }, status: :unprocessable_entity
#     end
#   end

#   # DELETE /employees/commissions/:id
#   def destroy
#     @commission.destroy
#     render json: { message: 'Commission deleted successfully' }, status: :ok
#   end

#   private

#   def set_commission
#     @commission = Commission.find(params[:id])
#   end

#   def commission_params
#     params.require(:commission).permit(:agent_id, :amount, :month, :year)
#   end
# end
class Employees::CommissionsController < ApplicationController
  before_action :authenticate_employee!
  before_action :set_commission, only: [:show, :update, :destroy]

  # GET /employees/commissions?month=7&year=2025
  def index
    month = params[:month].to_i
    year = params[:year].to_i

    commissions = Commission.includes(:agent)
                            .where(month: month, year: year)

    render json: commissions.map { |c|
      {
        id: c.id,
        amount: c.amount,
        month: c.month,
        year: c.year,
        # Only include description and date if columns exist in your model
        # description: c.respond_to?(:description) ? c.description : nil,
        # date: c.respond_to?(:date) ? c.date : nil,
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
    @agent = Agent.find_by(id: commission_params[:agent_id])
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
    @commission = Commission.find(params[:id])
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
      # Only if description/date fields exist, otherwise comment/remove:
      # description: commission.respond_to?(:description) ? commission.description : nil,
      # date: commission.respond_to?(:date) ? commission.date : nil,
      agent_name: commission.agent&.name
    }
  end
end
