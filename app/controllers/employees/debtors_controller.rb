class Employees::DebtorsController < ApplicationController
  before_action :authenticate_employee!  # Ensure employee is authenticated

  def create
    @debtor = Debtor.new(debtor_params)

    if @debtor.save
      render json: { message: 'Debtor created successfully', debtor: @debtor }, status: :created
    else
      render json: { errors: @debtor.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def pay_debt
    @debtor = Debtor.find(params[:debtor_id])

    # Check if debtor exists
    if @debtor.nil?
      render json: { errors: 'Debtor not found' }, status: :not_found
      return
    end

    # Get the payment amount from the request body
    payment_amount = params[:payment_amount].to_f

    # Check if the payment amount is valid
    if payment_amount <= 0
      render json: { errors: 'Payment amount must be greater than zero' }, status: :unprocessable_entity
      return
    end

    # Case 1: Full payment (if the debtor pays off the entire debt)
    if payment_amount >= @debtor.debt_amount
      if @debtor.update(total_paid: @debtor.debt_amount, debt_amount: 0)
        render json: { message: 'Debt paid off in full', debtor: @debtor }, status: :ok
      else
        render json: { errors: 'Failed to update debtor' }, status: :unprocessable_entity
      end

    # Case 2: Partial payment (if the debtor is paying a portion of the debt)
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

  private

  def debtor_params
    params.require(:debtor).permit(:name, :debt_amount, :agent_id)
  end
end
