class Employees::Dashboard::StatsController < ApplicationController
  before_action :authenticate_employee!

  rescue_from ActiveRecord::RecordNotFound, with: :handle_record_not_found
  rescue_from StandardError, with: :handle_general_error

  def index
    render json: {
      daily_stats: daily_statistics,
      recent_activity: recent_activities,
      quick_stats: quick_statistics,
      agents_summary: agents_summary,
      debtors_summary: debtors_summary,
      last_updated: Time.current.iso8601
    }
  end

  def weekly
    render json: weekly_statistics
  end

  def monthly
    render json: monthly_statistics
  end

  def agents_performance
    render json: {
      agents_summary: agents_performance_data,
      summary_stats: performance_summary
    }
  end

  private

  def current_employee
    @current_employee ||= current_user
  end

  def agent_ids
    @agent_ids ||= current_employee.agents.pluck(:id)
  end

  def daily_statistics
    today = Date.current
    today_transaction = current_employee.transactions.find_by(date: today)
    latest_transaction = current_employee.transactions.order(date: :desc).first

    opening_balance = today_transaction&.opening_balance || latest_transaction&.closing_balance || 0.0
    closing_balance = today_transaction&.closing_balance || opening_balance

    today_commissions = Commission.where(agent_id: agent_ids)
                                  .where(created_at: today.beginning_of_day..today.end_of_day)
                                  .sum(:amount)

    active_debtors_count = Debtor.where(agent_id: agent_ids).where('debt_amount > 0').count

    agent_transactions_today = AgentTransaction.where(agent_id: agent_ids)
                                               .where(created_at: today.beginning_of_day..today.end_of_day)
                                               .count

    {
      opening_balance: opening_balance.to_f,
      closing_balance: closing_balance.to_f,
      employee_transactions: current_employee.transactions.where(date: today).count,
      agent_transactions: agent_transactions_today,
      total_commissions: today_commissions.to_f,
      active_debtors: active_debtors_count,
      net_change: closing_balance.to_f - opening_balance.to_f,
      has_today_transaction: today_transaction.present?
    }
  end

  def recent_activities
    activities = []
    activities += fetch_recent_employee_transactions
    activities += fetch_recent_agent_transactions
    activities += fetch_recent_commissions
    activities += fetch_recent_debtor_payments

    activities.sort_by { |a| a[:timestamp] }.reverse.first(5)
  end

  def fetch_recent_employee_transactions
    current_employee.transactions
      .where(created_at: 24.hours.ago..Time.current)
      .order(created_at: :desc)
      .limit(3)
      .map do |transaction|
        {
          id: "emp_trans_#{transaction.id}",
          type: 'employee_transaction',
          title: transaction.type&.humanize || 'Daily Transaction',
          description: transaction.description || "Balance: #{format_currency(transaction.opening_balance)} → #{format_currency(transaction.closing_balance)}",
          amount: transaction.amount.to_f,
          time: transaction.created_at.strftime('%I:%M %p'),
          date: transaction.date.strftime('%b %d'),
          icon: 'account-balance-wallet',
          color: transaction.amount >= 0 ? '#48BB78' : '#F56565',
          timestamp: transaction.created_at.to_i
        }
      end
  rescue => e
    Rails.logger.error "Error fetching recent employee transactions: #{e.message}"
    []
  end

  def fetch_recent_agent_transactions
    
    AgentTransaction.where(agent_id: agent_ids)
      .where(created_at: 24.hours.ago..Time.current)
      .includes(:agent)
      .order(created_at: :desc)
      .limit(2)
      .map do |transaction|
        amount = transaction.closing_balance.to_f - transaction.opening_balance.to_f
        {
          id: "agent_trans_#{transaction.id}",
          type: 'agent_transaction',
          title: "#{transaction.agent.name} Transaction",
          description: 'Agent daily balance update',
          amount: amount,
          time: transaction.created_at.strftime('%I:%M %p'),
          date: transaction.date.strftime('%b %d'),
          icon: 'people',
          color: amount >= 0 ? '#48BB78' : '#F56565',
          timestamp: transaction.created_at.to_i
        }
      end
  rescue => e
    Rails.logger.error "Error fetching recent agent transactions: #{e.message}"
    []
  end

  def fetch_recent_commissions
    Commission.where(agent_id: agent_ids)
      .where(created_at: 24.hours.ago..Time.current)
      .includes(:agent)
      .order(created_at: :desc)
      .limit(2)
      .map do |commission|
        {
          id: "commission_#{commission.id}",
          type: 'commission',
          title: 'Commission Earned',
          description: "From #{commission.agent.name} - #{Date.new(commission.year, commission.month).strftime('%b %Y')}",
          amount: commission.amount.to_f,
          time: commission.created_at.strftime('%I:%M %p'),
          date: commission.created_at.strftime('%b %d'),
          icon: 'attach-money',
          color: '#48BB78',
          timestamp: commission.created_at.to_i
        }
      end
  rescue => e
    Rails.logger.error "Error fetching recent commissions: #{e.message}"
    []
  end

  def fetch_recent_debtor_payments
    Debtor.where(agent_id: agent_ids)
      .where('updated_at >= ? AND total_paid > 0', 24.hours.ago)
      .order(updated_at: :desc)
      .limit(2)
      .map do |debtor|
        {
          id: "debtor_#{debtor.id}",
          type: 'debtor_payment',
          title: 'Debt Payment',
          description: "Payment from #{debtor.name}",
          amount: debtor.total_paid.to_f,
          time: debtor.updated_at.strftime('%I:%M %p'),
          date: debtor.updated_at.strftime('%b %d'),
          icon: 'money-off',
          color: '#4299E1',
          timestamp: debtor.updated_at.to_i
        }
      end
  rescue => e
    Rails.logger.error "Error fetching recent debtor payments: #{e.message}"
    []
  end

  def quick_statistics
    today = Date.current
    this_month = today.beginning_of_month..today.end_of_month
    this_week = today.beginning_of_week..today.end_of_week

    {
      total_agents: current_employee.agents.count,
      active_debtors: Debtor.where(agent_id: agent_ids).where('debt_amount > 0').count,
      monthly_commissions: Commission.where(agent_id: agent_ids)
                                    .where(created_at: this_month)
                                    .sum(:amount).to_f,
      weekly_transactions: current_employee.transactions.where(date: this_week).count +
                           AgentTransaction.where(agent_id: agent_ids).where(date: this_week).count,
      total_debt_outstanding: Debtor.where(agent_id: agent_ids).sum(:debt_amount).to_f,
      total_debt_collected: Debtor.where(agent_id: agent_ids).sum(:total_paid).to_f
    }
  end

  def agents_summary
    agents_data = current_employee.agents.includes(:transactions, :commissions, :debtors).map do |agent|
      latest_transaction = agent.transactions.order(date: :desc).first
      total_commissions = agent.commissions.sum(:amount)
      active_debtors = agent.debtors.where('debt_amount > 0').count
      total_debt = agent.debtors.sum(:debt_amount)

      {
        id: agent.id,
        name: agent.name,
        type: agent.type_of_agent,
        latest_balance: latest_transaction&.closing_balance&.to_f || 0.0,
        last_transaction_date: latest_transaction&.date,
        total_commissions: total_commissions.to_f,
        active_debtors: active_debtors,
        total_debt_managed: total_debt.to_f,
        status: latest_transaction&.date == Date.current ? 'updated_today' : 'needs_update'
      }
    end

    {
      agents: agents_data,
      summary: {
        total_agents: agents_data.count,
        agents_with_updates_today: agents_data.count { |a| a[:status] == 'updated_today' },
        total_active_debtors: agents_data.sum { |a| a[:active_debtors] },
        total_debt_managed: agents_data.sum { |a| a[:total_debt_managed] }
      }
    }
  end

  def debtors_summary
    debtors = Debtor.where(agent_id: agent_ids)
                    .where('debt_amount > 0')
                    .order(debt_amount: :desc)
                    .limit(10)
                    .map do |debtor|
      {
        id: debtor.id,
        name: debtor.name,
        phone: debtor.phone,
        total_debt: debtor.debt_amount.to_f,
        total_paid: debtor.total_paid.to_f,
        status: debtor.debt_amount > 0 ? 'active' : 'paid_off'
      }
    end
    { debtors: debtors }
  end

  def weekly_statistics
    start_date = 7.days.ago.to_date
    end_date = Date.current

    transactions_count = current_employee.transactions.where(date: start_date..end_date).count
    commissions_sum = Commission.where(agent_id: agent_ids, created_at: start_date.beginning_of_day..end_date.end_of_day).sum(:amount)

    {
      transactions_last_7_days: transactions_count,
      commissions_last_7_days: commissions_sum.to_f
    }
  end

  def monthly_statistics
    start_date = Date.current.beginning_of_month
    end_date = Date.current.end_of_month

    transactions_count = current_employee.transactions.where(date: start_date..end_date).count
    commissions_sum = Commission.where(agent_id: agent_ids, created_at: start_date.beginning_of_day..end_date.end_of_day).sum(:amount)

    {
      transactions_this_month: transactions_count,
      commissions_this_month: commissions_sum.to_f
    }
  end

  def agents_performance_data
    current_employee.agents.map do |agent|
      monthly_commission = agent.commissions.where(created_at: Date.current.beginning_of_month..Date.current.end_of_month).sum(:amount).to_f
      active_debtors_count = agent.debtors.where('debt_amount > 0').count

      {
        agent_id: agent.id,
        agent_name: agent.name,
        monthly_commission: monthly_commission,
        active_debtors: active_debtors_count
      }
    end
  end

  def performance_summary
    agents = current_employee.agents
    {
      total_agents: agents.count,
      total_commissions_monthly: agents.sum { |a| a.commissions.where(created_at: Date.current.beginning_of_month..Date.current.end_of_month).sum(:amount) },
      total_active_debtors: agents.sum { |a| a.debtors.where('debt_amount > 0').count }
    }
  end

  def format_currency(amount)
    ActiveSupport::NumberHelper.number_to_currency(amount, unit: '₦', precision: 2)
  end

  def handle_record_not_found(error)
    render json: { error: 'Record not found' }, status: :not_found
  end

  def handle_general_error(error)
    render json: { error: 'An error occurred', details: error.message }, status: :internal_server_error
  end
end
