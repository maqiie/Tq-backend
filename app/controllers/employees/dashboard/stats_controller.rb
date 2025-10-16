class Employees::Dashboard::StatsController < ApplicationController
  before_action :authenticate_user!
  before_action :ensure_employee!
  
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

  # def employee_agents
  #   @employee_agents ||= current_employee.agents
  # end

  def employee_agents
    @employee_agents ||= if current_user.role == 'employee'
      # Employees see ALL agents from ALL admins
      admin_ids = User.where(role: 'admin').pluck(:id)
      Agent.where(user_id: admin_ids)
    end
  end

  def agent_ids
    @agent_ids ||= employee_agents.pluck(:id)
  end

  # Employee's transactions = transactions they created for their agents
  def employee_transactions
    @employee_transactions ||= Transaction.where(creator_id: current_employee.id)
  end

  def daily_statistics
    today = Date.current
    
    # Employee's transactions created today (for any of their agents)
    today_employee_transactions = employee_transactions.where(date: today.beginning_of_day..today.end_of_day)
    
    # Calculate employee's aggregate daily balance from all their agents
    opening_balance = calculate_employee_opening_balance(today)
    closing_balance = calculate_employee_closing_balance(today)
    
    # Today's commissions from all employee's agents
    today_commissions = Commission.where(agent_id: agent_ids)
                                  .where(created_at: today.beginning_of_day..today.end_of_day)
                                  .sum(:amount)
    
    # Active debtors across all employee's agents
    active_debtors_count = Debtor.where(agent_id: agent_ids)
                                 .where('debt_amount > total_paid')
                                 .count
    
    # Agent transactions today (daily updates by agents themselves)
    agent_transactions_today = AgentTransaction.where(agent_id: agent_ids)
                                               .where(created_at: today.beginning_of_day..today.end_of_day)
                                               .count

    {
      opening_balance: opening_balance.to_f,
      closing_balance: closing_balance.to_f,
      employee_transactions: today_employee_transactions.count, # Transactions employee created today
      agent_transactions: agent_transactions_today, # Agent daily updates
      total_commissions: today_commissions.to_f,
      active_debtors: active_debtors_count,
      net_change: closing_balance.to_f - opening_balance.to_f,
      has_today_transaction: today_employee_transactions.exists? # Has employee created any transactions today?
    }
  rescue => e
    Rails.logger.error "Error in daily_statistics: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    default_daily_stats
  end

  def calculate_employee_opening_balance(date)
    # Sum of all opening balances from today's transactions created by employee
    today_transactions = employee_transactions.where(date: date.beginning_of_day..date.end_of_day)
    
    if today_transactions.exists?
      return today_transactions.sum(:opening_balance)
    end
    
    # If no transactions today, get latest closing balances from previous day
    previous_day_transactions = employee_transactions.where('date < ?', date.beginning_of_day)
                                                    .where(date: (date - 1.day).beginning_of_day..(date - 1.day).end_of_day)
    
    return previous_day_transactions.sum(:closing_balance) || 0.0
  end

  def calculate_employee_closing_balance(date)
    # Sum of all closing balances from today's transactions created by employee
    today_transactions = employee_transactions.where(date: date.beginning_of_day..date.end_of_day)
    
    if today_transactions.exists?
      return today_transactions.sum(:closing_balance)
    end
    
    # If no transactions today, return opening balance
    return calculate_employee_opening_balance(date)
  end

  def recent_activities
    activities = []
    
    # Activities related to employee's work
    activities += fetch_transactions_created_by_employee
    activities += fetch_recent_agent_transactions
    activities += fetch_recent_commissions
    activities += fetch_recent_debtor_payments
    
    # Sort by timestamp and return top 5
    activities.sort_by { |a| a[:timestamp] }.reverse.first(5)
  rescue => e
    Rails.logger.error "Error in recent_activities: #{e.message}"
    []
  end

  def fetch_transactions_created_by_employee
    employee_transactions.where(created_at: 24.hours.ago..Time.current)
                         .includes(:agent)
                         .order(created_at: :desc)
                         .limit(3)
                         .map do |transaction|
      amount = (transaction.closing_balance || 0).to_f - (transaction.opening_balance || 0).to_f
      {
        id: "emp_created_trans_#{transaction.id}",
        type: 'employee_created_transaction',
        title: 'Transaction Created',
        description: "For #{transaction.agent.name}",
        amount: amount,
        time: transaction.created_at.strftime('%I:%M %p'),
        date: transaction.date.strftime('%b %d'),
        icon: 'account-balance-wallet',
        color: amount >= 0 ? '#48BB78' : '#F56565',
        timestamp: transaction.created_at.to_i
      }
    end
  rescue => e
    Rails.logger.error "Error fetching employee created transactions: #{e.message}"
    []
  end

  def fetch_recent_agent_transactions
    return [] if agent_ids.empty?
    
    AgentTransaction.where(agent_id: agent_ids)
                   .where(created_at: 24.hours.ago..Time.current)
                   .includes(:agent)
                   .order(created_at: :desc)
                   .limit(2)
                   .map do |transaction|
      amount = (transaction.closing_balance || 0).to_f - (transaction.opening_balance || 0).to_f
      {
        id: "agent_trans_#{transaction.id}",
        type: 'agent_transaction',
        title: "#{transaction.agent.name} Self-Update",
        description: 'Agent daily balance update',
        amount: amount,
        time: transaction.created_at.strftime('%I:%M %p'),
        date: transaction.created_at.strftime('%b %d'),
        icon: 'people',
        color: amount >= 0 ? '#48BB78' : '#F56565',
        timestamp: transaction.created_at.to_i
      }
    end
  rescue => e
    Rails.logger.error "Error fetching agent transactions: #{e.message}"
    []
  end

  def fetch_recent_commissions
    return [] if agent_ids.empty?
    
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
        description: "From #{commission.agent.name}",
        amount: commission.amount.to_f,
        time: commission.created_at.strftime('%I:%M %p'),
        date: commission.created_at.strftime('%b %d'),
        icon: 'attach-money',
        color: '#48BB78',
        timestamp: commission.created_at.to_i
      }
    end
  rescue => e
    Rails.logger.error "Error fetching commissions: #{e.message}"
    []
  end

  def fetch_recent_debtor_payments
    return [] if agent_ids.empty?
    
    Debtor.where(agent_id: agent_ids)
          .where('updated_at >= ? AND total_paid > 0', 24.hours.ago)
          .order(updated_at: :desc)
          .limit(2)
          .map do |debtor|
      {
        id: "debtor_#{debtor.id}",
        type: 'debtor_payment',
        title: 'Debt Payment Received',
        description: "From #{debtor.name} via #{debtor.agent.name}",
        amount: debtor.total_paid.to_f,
        time: debtor.updated_at.strftime('%I:%M %p'),
        date: debtor.updated_at.strftime('%b %d'),
        icon: 'money-off',
        color: '#4299E1',
        timestamp: debtor.updated_at.to_i
      }
    end
  rescue => e
    Rails.logger.error "Error fetching debtor payments: #{e.message}"
    []
  end

  def quick_statistics
    today = Date.current
    this_month = today.beginning_of_month..today.end_of_month
    this_week = today.beginning_of_week..today.end_of_week
    
    {
      total_agents: employee_agents.count, # Agents employee manages
      active_debtors: agent_ids.empty? ? 0 : Debtor.where(agent_id: agent_ids)
                                                   .where('debt_amount > total_paid')
                                                   .count,
      monthly_commissions: agent_ids.empty? ? 0.0 : Commission.where(agent_id: agent_ids)
                                                              .where(created_at: this_month)
                                                              .sum(:amount).to_f,
      weekly_transactions: employee_transactions.where(date: this_week).count + # Transactions employee created
                          (agent_ids.empty? ? 0 : AgentTransaction.where(agent_id: agent_ids)
                                                                 .where(created_at: this_week).count), # + Agent self-updates
      total_debt_outstanding: agent_ids.empty? ? 0.0 : Debtor.where(agent_id: agent_ids)
                                                             .sum('debt_amount - total_paid').to_f,
      total_debt_collected: agent_ids.empty? ? 0.0 : Debtor.where(agent_id: agent_ids)
                                                           .sum(:total_paid).to_f
    }
  rescue => e
    Rails.logger.error "Error in quick_statistics: #{e.message}"
    default_quick_stats
  end

  def agents_summary
    agents_data = employee_agents.includes(:agent_transactions, :commissions, :debtors).map do |agent|
      # Get the LATEST transaction for this agent (created by ANYONE)
      latest_transaction = Transaction.where(agent: agent).order(date: :desc).first
      
      # Latest self-update by agent (fallback)
      latest_agent_transaction = agent.agent_transactions.order(created_at: :desc).first
      
      total_commissions = agent.commissions.sum(:amount)
      active_debtors = agent.debtors.where('debt_amount > total_paid').count
      total_debt = agent.debtors.sum('debt_amount - total_paid')
      
      {
        id: agent.id,
        name: agent.name,
        type: agent.type_of_agent || 'Service Provider',
        latest_balance: latest_transaction&.closing_balance&.to_f || latest_agent_transaction&.closing_balance&.to_f || 0.0,
        last_transaction_date: latest_transaction&.date || latest_agent_transaction&.created_at&.to_date,
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
  rescue => e
    Rails.logger.error "Error in agents_summary: #{e.message}"
    default_agents_summary
  end

  def debtors_summary
    return { debtors: [] } if agent_ids.empty?
    
    debtors = Debtor.where(agent_id: agent_ids)
                    .where('debt_amount > total_paid')
                    .includes(:agent)
                    .order('debt_amount - total_paid DESC')
                    .limit(10)
                    .map do |debtor|
      {
        id: debtor.id,
        name: debtor.name,
        phone: debtor.phone,
        agent_name: debtor.agent.name, # Show which agent/service provider
        total_debt: debtor.debt_amount.to_f,
        total_paid: debtor.total_paid.to_f,
        outstanding: (debtor.debt_amount - debtor.total_paid).to_f,
        status: debtor.debt_amount > debtor.total_paid ? 'active' : 'paid_off'
      }
    end
    
    { debtors: debtors }
  rescue => e
    Rails.logger.error "Error in debtors_summary: #{e.message}"
    { debtors: [] }
  end

  def weekly_statistics
    start_date = 7.days.ago.to_date
    end_date = Date.current
    
    # Transactions created by employee in the last 7 days
    transactions_count = employee_transactions.where(date: start_date.beginning_of_day..end_date.end_of_day).count
    
    # Commissions earned in the last 7 days
    commissions_sum = agent_ids.empty? ? 0.0 : Commission.where(agent_id: agent_ids)
                                                        .where(created_at: start_date.beginning_of_day..end_date.end_of_day)
                                                        .sum(:amount)
    {
      transactions_last_7_days: transactions_count,
      commissions_last_7_days: commissions_sum.to_f
    }
  rescue => e
    Rails.logger.error "Error in weekly_statistics: #{e.message}"
    { transactions_last_7_days: 0, commissions_last_7_days: 0.0 }
  end

  def monthly_statistics
    start_date = Date.current.beginning_of_month
    end_date = Date.current.end_of_month
    
    # Transactions created by employee this month
    transactions_count = employee_transactions.where(date: start_date.beginning_of_day..end_date.end_of_day).count
    
    # Commissions earned this month
    commissions_sum = agent_ids.empty? ? 0.0 : Commission.where(agent_id: agent_ids)
                                                        .where(created_at: start_date.beginning_of_day..end_date.end_of_day)
                                                        .sum(:amount)
    {
      transactions_this_month: transactions_count,
      commissions_this_month: commissions_sum.to_f
    }
  rescue => e
    Rails.logger.error "Error in monthly_statistics: #{e.message}"
    { transactions_this_month: 0, commissions_this_month: 0.0 }
  end

  def agents_performance_data
    employee_agents.map do |agent|
      monthly_commission = agent.commissions.where(created_at: Date.current.beginning_of_month..Date.current.end_of_month).sum(:amount).to_f
      active_debtors_count = agent.debtors.where('debt_amount > total_paid').count
      
      {
        agent_id: agent.id,
        agent_name: agent.name,
        agent_type: agent.type_of_agent,
        monthly_commission: monthly_commission,
        active_debtors: active_debtors_count,
        transactions_created: employee_transactions.where(agent: agent)
                                                  .where(created_at: Date.current.beginning_of_month..Date.current.end_of_month)
                                                  .count
      }
    end
  rescue => e
    Rails.logger.error "Error in agents_performance_data: #{e.message}"
    []
  end

  def performance_summary
    agents = employee_agents
    
    {
      total_agents: agents.count,
      total_commissions_monthly: agents.sum { |a| a.commissions.where(created_at: Date.current.beginning_of_month..Date.current.end_of_month).sum(:amount) },
      total_active_debtors: agents.sum { |a| a.debtors.where('debt_amount > total_paid').count },
      total_transactions_created_monthly: employee_transactions.where(created_at: Date.current.beginning_of_month..Date.current.end_of_month).count
    }
  rescue => e
    Rails.logger.error "Error in performance_summary: #{e.message}"
    {
      total_agents: 0,
      total_commissions_monthly: 0.0,
      total_active_debtors: 0,
      total_transactions_created_monthly: 0
    }
  end

  # Default fallback methods
  def default_daily_stats
    {
      opening_balance: 0.0,
      closing_balance: 0.0,
      employee_transactions: 0,
      agent_transactions: 0,
      total_commissions: 0.0,
      active_debtors: 0,
      net_change: 0.0,
      has_today_transaction: false
    }
  end

  def default_quick_stats
    {
      total_agents: 0,
      active_debtors: 0,
      monthly_commissions: 0.0,
      weekly_transactions: 0,
      total_debt_outstanding: 0.0,
      total_debt_collected: 0.0
    }
  end

  def default_agents_summary
    {
      agents: [],
      summary: {
        total_agents: 0,
        agents_with_updates_today: 0,
        total_active_debtors: 0,
        total_debt_managed: 0.0
      }
    }
  end

  def format_currency(amount)
    return "TSh 0" if amount.nil?
    "TSh #{amount.to_f.round(0).to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1,').reverse}"
  end

  def ensure_employee!
    unless current_user&.role == 'employee'
      render json: { error: 'Unauthorized access. Employee role required.' }, status: :unauthorized
    end
  end

  def handle_record_not_found(error)
    Rails.logger.error "Record not found: #{error.message}"
    render json: { error: 'Record not found' }, status: :not_found
  end

  def handle_general_error(error)
    Rails.logger.error "General error in dashboard: #{error.message}"
    Rails.logger.error error.backtrace.join("\n")
    render json: { error: 'An error occurred while loading dashboard data', details: error.message }, status: :internal_server_error
  end
end