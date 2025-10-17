class Employees::DebtorsController < ApplicationController
  before_action :authenticate_employee!
  
  # Fetch all debtors for accessible agents
  def index
    agent_ids = current_user.accessible_agents.pluck(:id)  # ← FIXED
    @debtors = Debtor.where(agent_id: agent_ids)  # ← FIXED
    render json: { debtors: @debtors }, status: :ok
  rescue StandardError => e
    Rails.logger.error "Error in index: #{e.message}"
    render json: { error: 'Failed to fetch debtors' }, status: :internal_server_error
  end
  
  # Get overview of debtors
  def overview
    agent_ids = current_user.accessible_agents.pluck(:id)  # ← FIXED
    @debtors = Debtor.where(agent_id: agent_ids)  # ← FIXED
    
    total_debt = @debtors.sum(:debt_amount)
    total_paid = @debtors.sum(:total_paid)
    
    debt_summary = @debtors.map do |debtor|
      {
        id: debtor.id,
        debtor_name: debtor.name,
        debt_amount: debtor.debt_amount,
        total_paid: debtor.total_paid,
        balance_due: debtor.debt_amount - debtor.total_paid,
        payment_status: debtor.debt_amount == debtor.total_paid ? 'Paid Off' : 'Outstanding'
      }
    end
    
    render json: {
      debt_summary: debt_summary,
      total_debt: total_debt,
      total_paid: total_paid
    }, status: :ok
  rescue StandardError => e
    Rails.logger.error "Error in overview: #{e.message}"
    render json: { error: 'Failed to generate debt overview' }, status: :internal_server_error
  end
  
  # Create a new debtor
  def create
    # Make sure the agent belongs to accessible agents
    @agent = current_user.accessible_agents.find_by(id: debtor_params[:agent_id])  # ← FIXED
    return render json: { errors: 'Agent not found or not accessible' }, status: :not_found unless @agent
    
    @debtor = @agent.debtors.new(debtor_params.except(:agent_id))  # ← FIXED
    
    if @debtor.save
      render json: { message: 'Debtor created successfully', debtor: @debtor }, status: :created
    else
      render json: { errors: @debtor.errors.full_messages }, status: :unprocessable_entity
    end
  rescue StandardError => e
    Rails.logger.error "Error in create: #{e.message}"
    render json: { error: 'Failed to create debtor' }, status: :internal_server_error
  end
  
  # Mark debt as paid
  def pay_debt
    agent_ids = current_user.accessible_agents.pluck(:id)  # ← FIXED
    @debtor = Debtor.where(agent_id: agent_ids).find_by(id: params[:debtor_id])  # ← FIXED
    
    if @debtor.nil?
      render json: { errors: 'Debtor not found' }, status: :not_found
      return
    end
    
    payment_amount = params[:payment_amount].to_f
    
    if payment_amount <= 0
      render json: { errors: 'Payment amount must be greater than zero' }, status: :unprocessable_entity
      return
    end
    
    if payment_amount >= @debtor.debt_amount
      if @debtor.update(total_paid: @debtor.debt_amount, debt_amount: 0)
        render json: { message: 'Debt paid off in full', debtor: @debtor }, status: :ok
      else
        render json: { errors: 'Failed to update debtor' }, status: :unprocessable_entity
      end
    else
      new_total_paid = @debtor.total_paid + payment_amount
      new_debt_amount = @debtor.debt_amount - payment_amount
      
      if @debtor.update(total_paid: new_total_paid, debt_amount: new_debt_amount)
        render json: { message: 'Partial payment made successfully', debtor: @debtor }, status: :ok
      else
        render json: { errors: 'Failed to update debtor' }, status: :unprocessable_entity
      end
    end
  rescue StandardError => e
    Rails.logger.error "Error in pay_debt: #{e.message}"
    render json: { error: 'Failed to process payment' }, status: :internal_server_error
  end
  
  # Show a specific debtor
  def show
    agent_ids = current_user.accessible_agents.pluck(:id)  # ← FIXED
    @debtor = Debtor.where(agent_id: agent_ids).find_by(id: params[:debtor_id])  # ← FIXED
    
    if @debtor
      render json: { debtor: @debtor }, status: :ok
    else
      render json: { errors: 'Debtor not found' }, status: :not_found
    end
  rescue StandardError => e
    Rails.logger.error "Error in show: #{e.message}"
    render json: { error: 'Failed to fetch debtor details' }, status: :internal_server_error
  end
  
  private
  
  def debtor_params
    params.require(:debtor).permit(:name, :debt_amount, :agent_id, :phone)
  end
end

# class Employees::DebtorsController < ApplicationController
#   before_action :authenticate_employee!

#   # Fetch all debtors (and debts) for the employee
#   def index
#     @debtors = Debtor.all

#     render json: { debtors: @debtors }, status: :ok
#   rescue StandardError => e
#     Rails.logger.error "Error in index: #{e.message}"
#     render json: { error: 'Failed to fetch debtors' }, status: :internal_server_error
#   end

#   # Get overview of debtors for the current authenticated employee
#   def overview
#     @debtors = Debtor.all
#     total_debt = @debtors.sum(:debt_amount)
#     total_paid = @debtors.sum(:total_paid)

#     debt_summary = @debtors.map do |debtor|
#       {
#         id: debtor.id,
#         debtor_name: debtor.name,
#         debt_amount: debtor.debt_amount,
#         total_paid: debtor.total_paid,
#         balance_due: debtor.debt_amount - debtor.total_paid,
#         payment_status: debtor.debt_amount == debtor.total_paid ? 'Paid Off' : 'Outstanding'
#       }
#     end

#     render json: {
#       debt_summary: debt_summary,
#       total_debt: total_debt,
#       total_paid: total_paid
#     }, status: :ok
#   rescue StandardError => e
#     Rails.logger.error "Error in overview: #{e.message}"
#     render json: { error: 'Failed to generate debt overview' }, status: :internal_server_error
#   end

#   # Create a new debtor (and their debt)
#   def create
#     @debtor = Debtor.new(debtor_params)

#     if @debtor.save
#       render json: { message: 'Debtor created successfully', debtor: @debtor }, status: :created
#     else
#       render json: { errors: @debtor.errors.full_messages }, status: :unprocessable_entity
#     end
#   rescue StandardError => e
#     Rails.logger.error "Error in create: #{e.message}"
#     render json: { error: 'Failed to create debtor' }, status: :internal_server_error
#   end

#   # Mark debt as paid (Partial or Full payment)
#   def pay_debt
#     @debtor = Debtor.find_by(id: params[:debtor_id])

#     if @debtor.nil?
#       render json: { errors: 'Debtor not found' }, status: :not_found
#       return
#     end

#     payment_amount = params[:payment_amount].to_f

#     if payment_amount <= 0
#       render json: { errors: 'Payment amount must be greater than zero' }, status: :unprocessable_entity
#       return
#     end

#     if payment_amount >= @debtor.debt_amount
#       if @debtor.update(total_paid: @debtor.debt_amount, debt_amount: 0)
#         render json: { message: 'Debt paid off in full', debtor: @debtor }, status: :ok
#       else
#         render json: { errors: 'Failed to update debtor' }, status: :unprocessable_entity
#       end
#     else
#       new_total_paid = @debtor.total_paid + payment_amount
#       new_debt_amount = @debtor.debt_amount - payment_amount

#       if @debtor.update(total_paid: new_total_paid, debt_amount: new_debt_amount)
#         render json: { message: 'Partial payment made successfully', debtor: @debtor }, status: :ok
#       else
#         render json: { errors: 'Failed to update debtor' }, status: :unprocessable_entity
#       end
#     end
#   rescue StandardError => e
#     Rails.logger.error "Error in pay_debt: #{e.message}"
#     render json: { error: 'Failed to process payment' }, status: :internal_server_error
#   end

#   # Show a specific debtor's debt details
#   def show
#     @debtor = Debtor.find_by(id: params[:debtor_id])

#     if @debtor
#       render json: { debtor: @debtor }, status: :ok
#     else
#       render json: { errors: 'Debtor not found' }, status: :not_found
#     end
#   rescue StandardError => e
#     Rails.logger.error "Error in show: #{e.message}"
#     render json: { error: 'Failed to fetch debtor details' }, status: :internal_server_error
#   end

#   private

#   # Permit necessary parameters
#   def debtor_params
#     params.require(:debtor).permit(:name, :debt_amount, :agent_id)
#   end
# end
