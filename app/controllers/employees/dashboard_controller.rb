class Employees::DashboardController < ApplicationController
  before_action :authenticate_user!
  before_action :ensure_employee!
  
  def index
    render json: {
      daily_stats: daily_statistics,
      recent_activity: recent_activities,
      quick_stats: quick_statistics,
      last_updated: Time.current.iso8601
    }
  end
  
  private
  
  # Helper method to get accessible agents
  def accessible_agents
    current_user.accessible_agents  # ← FIXED - single source of truth
  end
  
  def daily_statistics
    today = Date.current
    begin
      agent_ids = accessible_agents.pluck(:id)
      
      today_transaction = Transaction.where(agent_id: agent_ids)
                                     .where(date: today)
                                     .first
      
      latest_transaction = Transaction.where(agent_id: agent_ids)
                                      .order(date: :desc)
                                      .first
      
      opening_balance = today_transaction&.opening_balance || latest_transaction&.closing_balance || 0.0
      closing_balance = today_transaction&.closing_balance || opening_balance
      
      today_commissions = Commission.where(agent_id: agent_ids)
                                    .where(created_at: today.beginning_of_day..today.end_of_day)
                                    .sum(:amount)
      
      active_debtors_count = Debtor.where(agent_id: agent_ids)
                                   .where('debt_amount > total_paid')
                                   .count
      
      {
        opening_balance: opening_balance.to_f,
        closing_balance: closing_balance.to_f,
        total_commissions: today_commissions.to_f,
        active_debtors: active_debtors_count,
        net_change: (closing_balance.to_f - opening_balance.to_f),
        has_today_transaction: today_transaction.present?
      }
    rescue => e
      Rails.logger.error "Error in daily_statistics: #{e.message}"
      {
        error: "An error occurred while fetching daily statistics."
      }
    end
  end
  
  def recent_activities
    activities = []
    agent_ids = accessible_agents.pluck(:id)
    
    recent_transactions = Transaction.where(agent_id: agent_ids)
                                     .where(created_at: 24.hours.ago..Time.current)
                                     .includes(:agent)
                                     .order(created_at: :desc)
                                     .limit(3)
    
    recent_transactions.each do |transaction|
      amount = (transaction.closing_balance || 0).to_f - (transaction.opening_balance || 0).to_f
      activities << {
        id: "emp_trans_#{transaction.id}",
        type: 'employee_transaction',
        title: 'Transaction Created',
        description: "For #{transaction.agent.name}",
        amount: amount,
        time: transaction.created_at.strftime('%I:%M %p'),
        date: transaction.date.strftime('%b %d'),
        icon: 'account-balance-wallet',
        color: amount >= 0 ? '#48BB78' : '#F56565'
      }
    end
    
    activities.sort_by { |a| Time.parse("#{a[:date]} #{a[:time]}") }.reverse.first(5)
  end
  
  def quick_statistics
    today = Date.current
    this_month = today.beginning_of_month..today.end_of_month
    agent_ids = accessible_agents.pluck(:id)
    
    {
      total_agents: agent_ids.count,
      active_debtors: Debtor.where(agent_id: agent_ids).where('debt_amount > total_paid').count,
      monthly_commissions: Commission.where(agent_id: agent_ids)
                                    .where(created_at: this_month)
                                    .sum(:amount).to_f,
      total_debt_outstanding: Debtor.where(agent_id: agent_ids).sum('debt_amount - total_paid').to_f,
      total_debt_collected: Debtor.where(agent_id: agent_ids).sum(:total_paid).to_f
    }
  end
  
  def format_currency(amount)
    "TSh #{amount.to_f.round(0)}"
  end
  
  def ensure_employee!
    unless current_user.role == 'employee'
      render json: { error: 'Unauthorized access' }, status: :unauthorized
    end
  end
end

# class Employees::DashboardController < ApplicationController
#   before_action :authenticate_user!
#   before_action :ensure_employee!

#   def index
#     render json: {
#       daily_stats: daily_statistics,
#       recent_activity: recent_activities,
#       quick_stats: quick_statistics,
#       last_updated: Time.current.iso8601
#     }
#   end

#   private

#   # Helper method to get agents belonging to admin(s)
#   def admin_agents
#     # Example: fetch all agents belonging to all admins
#     admin_ids = User.where(role: 'admin').pluck(:id)
#     Agent.where(user_id: admin_ids)
#   end

#   # Use admin_agents to fetch transactions/commissions/debtors, etc.
#   def daily_statistics
#   today = Date.current

#   begin
#     today_transaction = Transaction.joins(:agent)
#                                    .where(agent_id: admin_agents.select(:id))
#                                    .where(date: today)
#                                    .first

#     latest_transaction = Transaction.joins(:agent)
#                                     .where(agent_id: admin_agents.select(:id))
#                                     .order(date: :desc)
#                                     .first

#     opening_balance = today_transaction&.opening_balance || latest_transaction&.closing_balance || 0.0
#     closing_balance = today_transaction&.closing_balance || opening_balance

#     today_commissions = Commission.joins(:agent)
#                                   .where(agent_id: admin_agents.select(:id))
#                                   .where(created_at: today.beginning_of_day..today.end_of_day)
#                                   .sum(:amount)

#     active_debtors_count = Debtor.joins(:agent)
#                                  .where(agent_id: admin_agents.select(:id))
#                                  .where('debt_amount > 0')
#                                  .count

#     {
#       opening_balance: opening_balance.to_f,
#       closing_balance: closing_balance.to_f,
#       total_commissions: today_commissions.to_f,
#       active_debtors: active_debtors_count,
#       net_change: (closing_balance.to_f - opening_balance.to_f),
#       has_today_transaction: today_transaction.present?
#     }
#   rescue => e
#     Rails.logger.error "Error in daily_statistics: #{e.message}"
#     {
#       error: "An error occurred while fetching daily statistics."
#     }
#   end
# end


#   def recent_activities
#     activities = []

#     recent_transactions = Transaction.joins(:agent)
#                                      .where(agent_id: admin_agents.select(:id))
#                                      .where(created_at: 24.hours.ago..Time.current)
#                                      .order(created_at: :desc)
#                                      .limit(3)

#     recent_transactions.each do |transaction|
#       activities << {
#         id: "emp_trans_#{transaction.id}",
#         type: 'employee_transaction',
#         title: transaction.type&.humanize || 'Daily Transaction',
#         description: "Balance: #{format_currency(transaction.opening_balance)} → #{format_currency(transaction.closing_balance)}",
#         amount: transaction.amount.to_f,
#         time: transaction.created_at.strftime('%I:%M %p'),
#         date: transaction.date.strftime('%b %d'),
#         icon: 'account-balance-wallet',
#         color: transaction.amount >= 0 ? '#48BB78' : '#F56565'
#       }
#     end

#     activities.sort_by { |a| Time.parse("#{a[:date]} #{a[:time]}") }.reverse.first(5)
#   end

#   def quick_statistics
#     today = Date.current
#     this_month = today.beginning_of_month..today.end_of_month

#     agent_ids = admin_agents.pluck(:id)  # changed here

#     {
#       total_agents: agent_ids.count,
#       active_debtors: Debtor.where(agent_id: agent_ids).where('debt_amount > 0').count,
#       monthly_commissions: Commission.where(agent_id: agent_ids)
#                                     .where(created_at: this_month)
#                                     .sum(:amount).to_f,
#       total_debt_outstanding: Debtor.where(agent_id: agent_ids).sum(:debt_amount).to_f,
#       total_debt_collected: Debtor.where(agent_id: agent_ids).sum(:total_paid).to_f
#     }
#   end

#   def format_currency(amount)
#     "$#{amount.to_f.round(2)}"
#   end

#   def ensure_employee!
#     unless current_user.role == 'employee'
#       render json: { error: 'Unauthorized access' }, status: :unauthorized
#     end
#   end
# end


