class Employees::TransactionsController < ApplicationController
  before_action :authenticate_employee!
  before_action :set_employee
  before_action :authorize_employee!

def index
  # Fetch transactions where creator_id matches the employee's id
  transactions = Transaction.where(creator_id: @employee.id).order(date: :asc)
  render json: transactions
end

  def create
    transaction_date = parse_date(transaction_params[:date])
    unless transaction_date
      return render json: { errors: ["Invalid or missing date"] }, status: :unprocessable_entity
    end

    if @employee.transactions.exists?(date: transaction_date)
      return render json: { errors: ["Transaction for this date already exists"] }, status: :unprocessable_entity
    end

    last_transaction = @employee.transactions.order(date: :desc).first
    yesterday_closing_balance = last_transaction&.closing_balance

    if last_transaction && transaction_date <= last_transaction.date
      return render json: { errors: ["Transaction date must be after the last transaction date"] }, status: :unprocessable_entity
    end

    if yesterday_closing_balance && transaction_params[:opening_balance].to_f != yesterday_closing_balance.to_f
      return render json: { errors: ["Opening balance must match the closing balance from yesterday"] }, status: :unprocessable_entity
    end

    # Build the transaction, associate to the employee and set the creator to current_employee
    @transaction = @employee.transactions.new(transaction_params)
    @transaction.creator = current_employee  # <-- set creator here

    ActiveRecord::Base.transaction do
      if @transaction.save
        render json: { message: 'Transaction created successfully', transaction: @transaction }, status: :created
      else
        render json: { errors: @transaction.errors.full_messages }, status: :unprocessable_entity
        raise ActiveRecord::Rollback
      end
    end
  end

  def latest
    last_transaction = @employee.transactions.order(date: :desc).first
    if last_transaction
      render json: { closing_balance: last_transaction.closing_balance }
    else
      render json: { closing_balance: 0.0 }
    end
  end

  private

  def set_employee
    @employee = User.find(params[:employee_id])
    unless @employee.employee?
      render json: { errors: ['User is not an employee'] }, status: :not_found
    end
  end

  def authorize_employee!
    unless @employee == current_employee
      render json: { errors: ['Not authorized'] }, status: :forbidden
    end
  end
  
  def transaction_params
    params.require(:transaction).permit(:opening_balance, :closing_balance, :notes, :date, :agent_id)
  end
  

  def parse_date(date_string)
    Date.parse(date_string) rescue nil
  end
end
