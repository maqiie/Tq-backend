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
  
    # Reject if a transaction already exists for this date
    if @employee.transactions.exists?(date: transaction_date)
      return render json: { errors: ["Transaction for this date already exists"] }, status: :unprocessable_entity
    end
  
    last_transaction_before = @employee.transactions
                                      .where("date < ?", transaction_date)
                                      .order(date: :desc)
                                      .first
  
    expected_opening_balance = last_transaction_before&.closing_balance
  
    warnings = []
    if expected_opening_balance && transaction_params[:opening_balance].to_f != expected_opening_balance.to_f
      warnings << "Opening balance does not match the previous closing balance (expected #{expected_opening_balance})"
    end
  
    @transaction = @employee.transactions.new(transaction_params)
    @transaction.creator = current_employee
  
    ActiveRecord::Base.transaction do
      if @transaction.save
        render json: { 
          message: 'Transaction created successfully',
          transaction: @transaction,
          warnings: warnings
        }, status: :created
      else
        render json: { errors: @transaction.errors.full_messages }, status: :unprocessable_entity
        raise ActiveRecord::Rollback
      end
    end
  end
  

 
  def latest
    last_transaction = @employee.transactions.order(date: :desc).first
  
    if last_transaction
      render json: {
        id: last_transaction.id,
        opening_balance: last_transaction.opening_balance,
        closing_balance: last_transaction.closing_balance,
        date: last_transaction.date,
        notes: last_transaction.notes,
        agent_id: last_transaction.agent_id
      }
    else
      render json: { message: "No transactions found", closing_balance: 0.0 }
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
