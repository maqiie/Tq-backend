

class Employees::DebtorsController < ApplicationController
  before_action :authenticate_employee!

  # Fetch all debtors (and debts) for the employee
  def index
    @debtors = Debtor.all  # This will fetch all debtors, along with their debt details

    render json: { debtors: @debtors }, status: :ok
  end

  def overview
    @debtors = Debtor.all
  
    total_debt = @debtors.sum(:debt_amount)
    total_paid = @debtors.sum(:total_paid)
  
    debt_summary = @debtors.map do |debtor|
      {
        debtor_name: debtor.name,
        debt_amount: debtor.debt_amount,
        total_paid: debtor.total_paid,
        balance_due: debtor.debt_amount - debtor.total_paid,
        payment_status: debtor.debt_amount == 0 ? 'Paid Off' : 'Outstanding'
      }
    end
  
    render json: { debt_summary: debt_summary, total_debt: total_debt, total_paid: total_paid }, status: :ok
  end
  
  # Create a new debtor (and their debt)
  def create
    @debtor = Debtor.new(debtor_params)

    if @debtor.save
      render json: { message: 'Debtor created successfully', debtor: @debtor }, status: :created
    else
      render json: { errors: @debtor.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # Mark debt as paid (Partial or Full payment)
  def pay_debt
    @debtor = Debtor.find(params[:debtor_id])

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
  end

  # Show a specific debtor's debt details
  def show
    @debtor = Debtor.find(params[:debtor_id])

    if @debtor
      render json: { debtor: @debtor }, status: :ok
    else
      render json: { errors: 'Debtor not found' }, status: :not_found
    end
  end

  private

  # Permit necessary parameters
  def debtor_params
    params.require(:debtor).permit(:name, :debt_amount, :agent_id)
  end
end
