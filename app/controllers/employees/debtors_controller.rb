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

    if @debtor.update(debt_amount: 0)
      render json: { message: 'Debt paid off successfully' }, status: :ok
    else
      render json: { errors: 'Failed to update debtor' }, status: :unprocessable_entity
    end
  end

  private

  def debtor_params
    params.require(:debtor).permit(:name, :debt_amount, :agent_id)
  end
end
