class Admin::DashboardController < ApplicationController
  before_action :authenticate_admin!

  # Use a constant for the date range to avoid repetition
  DATE_RANGE = 1.year.ago..Time.current

  def index
    # Use a begin-rescue block to handle exceptions
    begin
      summary_metrics = fetch_summary_metrics
      recent_records = fetch_recent_records
      trends_data = fetch_trends_data
      commissions_distribution = fetch_commissions_distribution

      # Use a presenter or serializer to format the response
      render json: {
        summary_metrics: summary_metrics,
        recent_records: recent_records,
        trends_data: trends_data,
        commissions_distribution: commissions_distribution
      }
    rescue StandardError => e
      # Log the error for debugging
      Rails.logger.error "Dashboard error: #{e.message}"
      render json: { error: 'An error occurred while fetching dashboard data.' }, status: :internal_server_error
    end
  end

  private

  # Fetch summary metrics
  def fetch_summary_metrics
    Rails.cache.fetch('summary_metrics', expires_in: 12.hours) do
      {
        total_users: User.count,
        total_agents: Agent.count,
        total_commissions: Commission.sum(:amount),
        total_debtors: Debtor.sum(:debt_amount),
        total_transactions: Transaction.count
      }
    end
  end

  # Fetch recent records
  def fetch_recent_records
    Rails.cache.fetch('recent_records', expires_in: 1.hour) do
      {
        recent_agents: Agent.order(created_at: :desc).limit(5).as_json(only: [:id, :name, :email, :created_at]),
        recent_commissions: Commission.includes(:agent).order(created_at: :desc).limit(5).as_json(include: { agent: { only: [:id, :name] } }, only: [:id, :amount, :created_at]),
        recent_transactions: Transaction.order(created_at: :desc).limit(5).as_json(only: [:id, :amount, :status, :created_at])
      }
    end
  end

  # Fetch trends data
  def fetch_trends_data
    Rails.cache.fetch('trends_data', expires_in: 12.hours) do
      {
        commissions_by_month: Commission.group_by_month(:created_at, range: DATE_RANGE).sum(:amount),
        transactions_by_month: Transaction.group_by_month(:created_at, range: DATE_RANGE).count,
        debtors_by_month: Debtor.group_by_month(:created_at, range: DATE_RANGE).sum(:debt_amount)
      }
    end
  end

  # Fetch commissions distribution
  def fetch_commissions_distribution
    Rails.cache.fetch('commissions_distribution', expires_in: 12.hours) do
      Commission.joins(:agent).group('agents.name').sum(:amount)
    end
  end
end
# app/controllers/admin/dashboard_controller.rb
# class Admin::DashboardController < ApplicationController
#   before_action :authenticate_admin!
#   before_action :set_date_range, only: [:index, :analytics]
  
#   # Use constants for cache expiration times
#   CACHE_EXPIRY_SHORT = 30.minutes
#   CACHE_EXPIRY_MEDIUM = 2.hours
#   CACHE_EXPIRY_LONG = 12.hours
  
#   def index
#     begin
#       render json: {
#         summary_metrics: fetch_summary_metrics,
#         recent_records: fetch_recent_records,
#         trends_data: fetch_trends_data,
#         commissions_distribution: fetch_commissions_distribution,
#         performance_indicators: fetch_performance_indicators,
#         alerts: fetch_system_alerts
#       }
#     rescue StandardError => e
#       Rails.logger.error "Dashboard error: #{e.message}"
#       Rails.logger.error e.backtrace.join("\n")
#       render json: { 
#         error: 'An error occurred while fetching dashboard data.',
#         details: Rails.env.development? ? e.message : nil
#       }, status: :internal_server_error
#     end
#   end
  
#   def analytics
#     begin
#       timeframe = params[:timeframe] || 'monthly'
      
#       render json: {
#         revenue_trends: fetch_revenue_trends(timeframe),
#         user_growth: fetch_user_growth(timeframe),
#         commission_trends: fetch_commission_trends(timeframe),
#         agent_performance: fetch_agent_performance_data,
#         geographic_data: fetch_geographic_data,
#         conversion_metrics: fetch_conversion_metrics
#       }
#     rescue StandardError => e
#       Rails.logger.error "Analytics error: #{e.message}"
#       render json: { error: 'Failed to fetch analytics data.' }, status: :internal_server_error
#     end
#   end
  
#   def performance_summary
#     begin
#       period = params[:period] || 'last_30_days'
      
#       render json: {
#         top_agents: fetch_top_agents(period),
#         revenue_breakdown: fetch_revenue_breakdown(period),
#         growth_metrics: fetch_growth_metrics(period),
#         efficiency_metrics: fetch_efficiency_metrics(period)
#       }
#     rescue StandardError => e
#       Rails.logger.error "Performance summary error: #{e.message}"
#       render json: { error: 'Failed to fetch performance data.' }, status: :internal_server_error
#     end
#   end
  
#   def export
#     begin
#       export_type = params[:type]
#       format = params[:format] || 'csv'
      
#       case export_type
#       when 'users'
#         data = export_users_data(format)
#       when 'agents'
#         data = export_agents_data(format)
#       when 'commissions'
#         data = export_commissions_data(format)
#       when 'transactions'
#         data = export_transactions_data(format)
#       else
#         return render json: { error: 'Invalid export type' }, status: :bad_request
#       end
      
#       send_data data[:content], 
#                 filename: data[:filename], 
#                 type: data[:content_type],
#                 disposition: 'attachment'
#     rescue StandardError => e
#       Rails.logger.error "Export error: #{e.message}"
#       render json: { error: 'Failed to export data.' }, status: :internal_server_error
#     end
#   end
  
#   private
  
#   def set_date_range
#     @start_date = params[:start_date]&.to_date || 1.year.ago
#     @end_date = params[:end_date]&.to_date || Date.current
#     @date_range = @start_date..@end_date
#   end
  
#   def fetch_summary_metrics
#     Rails.cache.fetch('admin_summary_metrics', expires_in: CACHE_EXPIRY_MEDIUM) do
#       {
#         total_users: User.count,
#         active_users: User.where(last_sign_in_at: 30.days.ago..Time.current).count,
#         total_agents: Agent.count,
#         active_agents: Agent.joins(:commissions)
#                            .where(commissions: { created_at: 30.days.ago..Time.current })
#                            .distinct.count,
#         total_commissions: Commission.sum(:amount),
#         monthly_commissions: Commission.where(created_at: 30.days.ago..Time.current).sum(:amount),
#         total_debtors: Debtor.sum(:debt_amount),
#         collected_debt: Debtor.where(status: 'collected').sum(:debt_amount),
#         total_transactions: Transaction.count,
#         monthly_transactions: Transaction.where(created_at: 30.days.ago..Time.current).count,
#         conversion_rate: calculate_conversion_rate,
#         average_transaction_value: calculate_average_transaction_value
#       }
#     end
#   end
  
#   def fetch_recent_records
#     Rails.cache.fetch('admin_recent_records', expires_in: CACHE_EXPIRY_SHORT) do
#       {
#         recent_agents: Agent.includes(:user)
#                            .order(created_at: :desc)
#                            .limit(10)
#                            .as_json(
#                              only: [:id, :name, :email, :created_at, :status],
#                              include: { user: { only: [:id, :email] } }
#                            ),
#         recent_commissions: Commission.includes(:agent, :transaction)
#                                     .order(created_at: :desc)
#                                     .limit(10)
#                                     .as_json(
#                                       only: [:id, :amount, :created_at, :status],
#                                       include: { 
#                                         agent: { only: [:id, :name] },
#                                         transaction: { only: [:id, :reference] }
#                                       }
#                                     ),
#         recent_transactions: Transaction.includes(:user)
#                                       .order(created_at: :desc)
#                                       .limit(10)
#                                       .as_json(
#                                         only: [:id, :amount, :status, :created_at, :reference],
#                                         include: { user: { only: [:id, :name, :email] } }
#                                       ),
#         recent_users: User.order(created_at: :desc)
#                          .limit(10)
#                          .as_json(only: [:id, :name, :email, :created_at, :last_sign_in_at])
#       }
#     end
#   end
  
#   def fetch_trends_data
#     Rails.cache.fetch('admin_trends_data', expires_in: CACHE_EXPIRY_LONG) do
#       {
#         commissions_by_month: Commission.group_by_month(:created_at, range: @date_range)
#                                        .sum(:amount)
#                                        .transform_keys { |k| k.strftime('%Y-%m') },
#         transactions_by_month: Transaction.group_by_month(:created_at, range: @date_range)
#                                          .count
#                                          .transform_keys { |k| k.strftime('%Y-%m') },
#         users_by_month: User.group_by_month(:created_at, range: @date_range)
#                            .count
#                            .transform_keys { |k| k.strftime('%Y-%m') },
#         debtors_by_month: Debtor.group_by_month(:created_at, range: @date_range)
#                                .sum(:debt_amount)
#                                .transform_keys { |k| k.strftime('%Y-%m') },
#         agents_by_month: Agent.group_by_month(:created_at, range: @date_range)
#                              .count
#                              .transform_keys { |k| k.strftime('%Y-%m') }
#       }
#     end
#   end
  
#   def fetch_commissions_distribution
#     Rails.cache.fetch('admin_commissions_distribution', expires_in: CACHE_EXPIRY_LONG) do
#       Commission.joins(:agent)
#                .where(created_at: @date_range)
#                .group('agents.name')
#                .sum(:amount)
#                .sort_by { |_, amount| -amount }
#                .first(10)
#                .to_h
#     end
#   end
  
#   def fetch_performance_indicators
#     Rails.cache.fetch('admin_performance_indicators', expires_in: CACHE_EXPIRY_MEDIUM) do
#       current_month = Date.current.beginning_of_month..Date.current
#       previous_month = 1.month.ago.beginning_of_month..1.month.ago.end_of_month
      
#       {
#         revenue_growth: calculate_growth_percentage(
#           Commission.where(created_at: current_month).sum(:amount),
#           Commission.where(created_at: previous_month).sum(:amount)
#         ),
#         user_growth: calculate_growth_percentage(
#           User.where(created_at: current_month).count,
#           User.where(created_at: previous_month).count
#         ),
#         transaction_growth: calculate_growth_percentage(
#           Transaction.where(created_at: current_month).count,
#           Transaction.where(created_at: previous_month).count
#         ),
#         agent_efficiency: calculate_agent_efficiency,
#         debt_collection_rate: calculate_debt_collection_rate
#       }
#     end
#   end
  
#   def fetch_system_alerts
#     alerts = []
    
#     # Check for low-performing agents
#     low_performers = Agent.joins(:commissions)
#                          .where(commissions: { created_at: 30.days.ago..Time.current })
#                          .group('agents.id')
#                          .having('SUM(commissions.amount) < ?', 1000)
#                          .count
    
#     if low_performers.any?
#       alerts << {
#         type: 'warning',
#         title: 'Low Performing Agents',
#         message: "#{low_performers.count} agents have generated less than $1,000 in commissions this month.",
#         action: 'Review agent performance'
#       }
#     end
    
#     # Check for high debt amounts
#     total_debt = Debtor.where(status: 'pending').sum(:debt_amount)
#     if total_debt > 100000
#       alerts << {
#         type: 'danger',
#         title: 'High Outstanding Debt',
#         message: "Outstanding debt has reached #{format_currency(total_debt)}.",
#         action: 'Review debt collection'
#       }
#     end
    
#     # Check for system performance
#     if Transaction.where(created_at: 1.hour.ago..Time.current).count > 1000
#       alerts << {
#         type: 'info',
#         title: 'High Transaction Volume',
#         message: 'System is experiencing high transaction volume.',
#         action: 'Monitor system performance'
#       }
#     end
    
#     alerts
#   end
  
#   def fetch_revenue_trends(timeframe)
#     case timeframe
#     when 'daily'
#       Commission.group_by_day(:created_at, range: 30.days.ago..Time.current).sum(:amount)
#     when 'weekly'
#       Commission.group_by_week(:created_at, range: 12.weeks.ago..Time.current).sum(:amount)
#     when 'monthly'
#       Commission.group_by_month(:created_at, range: 12.months.ago..Time.current).sum(:amount)
#     when 'yearly'
#       Commission.group_by_year(:created_at, range: 5.years.ago..Time.current).sum(:amount)
#     end
#   end
  
#   def fetch_user_growth(timeframe)
#     case timeframe
#     when 'daily'
#       User.group_by_day(:created_at, range: 30.days.ago..Time.current).count
#     when 'weekly'
#       User.group_by_week(:created_at, range: 12.weeks.ago..Time.current).count
#     when 'monthly'
#       User.group_by_month(:created_at, range: 12.months.ago..Time.current).count
#     when 'yearly'
#       User.group_by_year(:created_at, range: 5.years.ago..Time.current).count
#     end
#   end
  
#   def fetch_commission_trends(timeframe)
#     {
#       total_commissions: fetch_revenue_trends(timeframe),
#       commission_count: case timeframe
#                        when 'daily'
#                          Commission.group_by_day(:created_at, range: 30.days.ago..Time.current).count
#                        when 'weekly'
#                          Commission.group_by_week(:created_at, range: 12.weeks.ago..Time.current).count
#                        when 'monthly'
#                          Commission.group_by_month(:created_at, range: 12.months.ago..Time.current).count
#                        when 'yearly'
#                          Commission.group_by_year(:created_at, range: 5.years.ago..Time.current).count
#                        end,
#       average_commission: calculate_average_commission_by_period(timeframe)
#     }
#   end
  
#   def fetch_agent_performance_data
#     Agent.joins(:commissions)
#          .where(commissions: { created_at: 30.days.ago..Time.current })
#          .group('agents.id', 'agents.name')
#          .select(
#            'agents.id',
#            'agents.name',
#            'COUNT(commissions.id) as commission_count',
#            'SUM(commissions.amount) as total_commissions',
#            'AVG(commissions.amount) as average_commission'
#          )
#          .order('total_commissions DESC')
#          .limit(20)
#          .as_json
#   end
  
#   def fetch_geographic_data
#     Rails.cache.fetch('admin_geographic_data', expires_in: CACHE_EXPIRY_LONG) do
#       User.joins(:transactions)
#           .where(transactions: { created_at: @date_range })
#           .group(:country, :state)
#           .group('transactions.status')
#           .sum('transactions.amount')
#     end
#   end
  
#   def fetch_conversion_metrics
#     Rails.cache.fetch('admin_conversion_metrics', expires_in: CACHE_EXPIRY_MEDIUM) do
#       total_users = User.count
#       users_with_transactions = User.joins(:transactions).distinct.count
#       successful_transactions = Transaction.where(status: 'completed').count
#       total_transactions = Transaction.count
      
#       {
#         user_conversion_rate: total_users > 0 ? (users_with_transactions.to_f / total_users * 100).round(2) : 0,
#         transaction_success_rate: total_transactions > 0 ? (successful_transactions.to_f / total_transactions * 100).round(2) : 0,
#         average_time_to_first_transaction: calculate_average_time_to_first_transaction,
#         repeat_customer_rate: calculate_repeat_customer_rate
#       }
#     end
#   end
  
#   def fetch_top_agents(period)
#     date_range = case period
#                 when 'last_7_days'
#                   7.days.ago..Time.current
#                 when 'last_30_days'
#                   30.days.ago..Time.current
#                 when 'last_90_days'
#                   90.days.ago..Time.current
#                 else
#                   30.days.ago..Time.current
#                 end
    
#     Agent.joins(:commissions)
#          .where(commissions: { created_at: date_range })
#          .group('agents.id', 'agents.name')
#          .select(
#            'agents.id',
#            'agents.name',
#            'COUNT(commissions.id) as commission_count',
#            'SUM(commissions.amount) as total_commissions'
#          )
#          .order('total_commissions DESC')
#          .limit(10)
#          .as_json
#   end
  
#   def fetch_revenue_breakdown(period)
#     date_range = case period
#                 when 'last_7_days'
#                   7.days.ago..Time.current
#                 when 'last_30_days'
#                   30.days.ago..Time.current
#                 when 'last_90_days'
#                   90.days.ago..Time.current
#                 else
#                   30.days.ago..Time.current
#                 end
    
#     {
#       total_revenue: Commission.where(created_at: date_range).sum(:amount),
#       commission_revenue: Commission.where(created_at: date_range).sum(:amount),
#       transaction_fees: Transaction.where(created_at: date_range).sum(:fee_amount),
#       by_category: Transaction.joins(:commissions)
#                              .where(commissions: { created_at: date_range })
#                              .group(:category)
#                              .sum('commissions.amount')
#     }
#   end
  
#   def fetch_growth_metrics(period)
#     current_range = case period
#                    when 'last_7_days'
#                      7.days.ago..Time.current
#                    when 'last_30_days'
#                      30.days.ago..Time.current
#                    when 'last_90_days'
#                      90.days.ago..Time.current
#                    else
#                      30.days.ago..Time.current
#                    end
    
#     previous_range = case period
#                     when 'last_7_days'
#                       14.days.ago..7.days.ago
#                     when 'last_30_days'
#                       60.days.ago..30.days.ago
#                     when 'last_90_days'
#                       180.days.ago..90.days.ago
#                     else
#                       60.days.ago..30.days.ago
#                     end
    
#     current_revenue = Commission.where(created_at: current_range).sum(:amount)
#     previous_revenue = Commission.where(created_at: previous_range).sum(:amount)
#     current_users = User.where(created_at: current_range).count
#     previous_users = User.where(created_at: previous_range).count
    
#     {
#       revenue_growth: calculate_growth_percentage(current_revenue, previous_revenue),
#       user_growth: calculate_growth_percentage(current_users, previous_users),
#       agent_growth: calculate_growth_percentage(
#         Agent.where(created_at: current_range).count,
#         Agent.where(created_at: previous_range).count
#       )
#     }
#   end
  
#   def fetch_efficiency_metrics(period)
#     date_range = case period
#                 when 'last_7_days'
#                   7.days.ago..Time.current
#                 when 'last_30_days'
#                   30.days.ago..Time.current
#                 when 'last_90_days'
#                   90.days.ago..Time.current
#                 else
#                   30.days.ago..Time.current
#                 end
    
#     {
#       average_commission_per_agent: calculate_average_commission_per_agent(date_range),
#       transactions_per_user: calculate_transactions_per_user(date_range),
#       debt_collection_efficiency: calculate_debt_collection_efficiency(date_range),
#       processing_time_metrics: calculate_processing_time_metrics(date_range)
#     }
#   end
  
#   def export_users_data(format)
#     users = User.includes(:transactions).all
    
#     case format
#     when 'csv'
#       csv_data = CSV.generate(headers: true) do |csv|
#         csv << ['ID', 'Name', 'Email', 'Created At', 'Last Sign In', 'Total Transactions', 'Total Amount']
#         users.each do |user|
#           csv << [
#             user.id,
#             user.name,
#             user.email,
#             user.created_at,
#             user.last_sign_in_at,
#             user.transactions.count,
#             user.transactions.sum(:amount)
#           ]
#         end
#       end
      
#       {
#         content: csv_data,
#         filename: "users_export_#{Date.current}.csv",
#         content_type: 'text/csv'
#       }
#     when 'json'
#       {
#         content: users.as_json(include: :transactions),
#         filename: "users_export_#{Date.current}.json",
#         content_type: 'application/json'
#       }
#     end
#   end
  
#   def export_agents_data(format)
#     agents = Agent.includes(:commissions, :user).all
    
#     case format
#     when 'csv'
#       csv_data = CSV.generate(headers: true) do |csv|
#         csv << ['ID', 'Name', 'Email', 'Status', 'Created At', 'Total Commissions', 'Commission Count']
#         agents.each do |agent|
#           csv << [
#             agent.id,
#             agent.name,
#             agent.email,
#             agent.status,
#             agent.created_at,
#             agent.commissions.sum(:amount),
#             agent.commissions.count
#           ]
#         end
#       end
      
#       {
#         content: csv_data,
#         filename: "agents_export_#{Date.current}.csv",
#         content_type: 'text/csv'
#       }
#     when 'json'
#       {
#         content: agents.as_json(include: [:commissions, :user]),
#         filename: "agents_export_#{Date.current}.json",
#         content_type: 'application/json'
#       }
#     end
#   end
  
#   def export_commissions_data(format)
#     commissions = Commission.includes(:agent, :transaction).all
    
#     case format
#     when 'csv'
#       csv_data = CSV.generate(headers: true) do |csv|
#         csv << ['ID', 'Amount', 'Status', 'Created At', 'Agent Name', 'Transaction Reference']
#         commissions.each do |commission|
#           csv << [
#             commission.id,
#             commission.amount,
#             commission.status,
#             commission.created_at,
#             commission.agent&.name,
#             commission.transaction&.reference
#           ]
#         end
#       end
      
#       {
#         content: csv_data,
#         filename: "commissions_export_#{Date.current}.csv",
#         content_type: 'text/csv'
#       }
#     when 'json'
#       {
#         content: commissions.as_json(include: [:agent, :transaction]),
#         filename: "commissions_export_#{Date.current}.json",
#         content_type: 'application/json'
#       }
#     end
#   end
  
#   def export_transactions_data(format)
#     transactions = Transaction.includes(:user, :commissions).all
    
#     case format
#     when 'csv'
#       csv_data = CSV.generate(headers: true) do |csv|
#         csv << ['ID', 'Reference', 'Amount', 'Status', 'Created At', 'User Name', 'User Email']
#         transactions.each do |transaction|
#           csv << [
#             transaction.id,
#             transaction.reference,
#             transaction.amount,
#             transaction.status,
#             transaction.created_at,
#             transaction.user&.name,
#             transaction.user&.email
#           ]
#         end
#       end
      
#       {
#         content: csv_data,
#         filename: "transactions_export_#{Date.current}.csv",
#         content_type: 'text/csv'
#       }
#     when 'json'
#       {
#         content: transactions.as_json(include: [:user, :commissions]),
#         filename: "transactions_export_#{Date.current}.json",
#         content_type: 'application/json'
#       }
#     end
#   end
  
#   def calculate_conversion_rate
#     total_users = User.count
#     users_with_transactions = User.joins(:transactions).distinct.count
#     return 0 if total_users.zero?
    
#     (users_with_transactions.to_f / total_users * 100).round(2)
#   end
  
#   def calculate_average_transaction_value
#     total_amount = Transaction.sum(:amount)
#     total_count = Transaction.count
#     return 0 if total_count.zero?
    
#     (total_amount / total_count).round(2)
#   end
  
#   def calculate_growth_percentage(current, previous)
#     return 0 if previous.zero?
    
#     ((current - previous).to_f / previous * 100).round(2)
#   end
  
#   def calculate_agent_efficiency
#     active_agents = Agent.joins(:commissions)
#                         .where(commissions: { created_at: 30.days.ago..Time.current })
#                         .distinct.count
#     total_commissions = Commission.where(created_at: 30.days.ago..Time.current).sum(:amount)
    
#     return 0 if active_agents.zero?
    
#     (total_commissions / active_agents).round(2)
#   end
  
#   def calculate_debt_collection_rate
#     total_debt = Debtor.sum(:debt_amount)
#     collected_debt = Debtor.where(status: 'collected').sum(:debt_amount)
    
#     return 0 if total_debt.zero?
    
#     (collected_debt.to_f / total_debt * 100).round(2)
#   end
  
#   def calculate_average_commission_by_period(timeframe)
#     commissions = case timeframe
#                  when 'daily'
#                    Commission.where(created_at: 30.days.ago..Time.current)
#                  when 'weekly'
#                    Commission.where(created_at: 12.weeks.ago..Time.current)
#                  when 'monthly'
#                    Commission.where(created_at: 12.months.ago..Time.current)
#                  when 'yearly'
#                    Commission.where(created_at: 5.years.ago..Time.current)
#                  end
    
#     total_amount = commissions.sum(:amount)
#     total_count = commissions.count
    
#     return 0 if total_count.zero?
    
#     (total_amount / total_count).round(2)
#   end
  
#   def calculate_average_time_to_first_transaction
#     users_with_transactions = User.joins(:transactions).distinct
    
#     total_time = users_with_transactions.sum do |user|
#       first_transaction = user.transactions.order(:created_at).first
#       (first_transaction.created_at - user.created_at) / 1.day
#     end
    
#     return 0 if users_with_transactions.count.zero?
    
#     (total_time / users_with_transactions.count).round(2)
#   end
  
#   def calculate_repeat_customer_rate
#     users_with_multiple_transactions = User.joins(:transactions)
#                                          .group('users.id')
#                                          .having('COUNT(transactions.id) > 1')
#                                          .count
    
#     total_users_with_transactions = User.joins(:transactions).distinct.count
    
#     return 0 if total_users_with_transactions.zero?
    
#     (users_with_multiple_transactions.count.to_f / total_users_with_transactions * 100).round(2)
#   end
  
#   def calculate_average_commission_per_agent(date_range)
#     total_commissions = Commission.where(created_at: date_range).sum(:amount)
#     active_agents = Agent.joins(:commissions)
#                         .where(commissions: { created_at: date_range })
#                         .distinct.count
    
#     return 0 if active_agents.zero?
    
#     (total_commissions / active_agents).round(2)
#   end
  
#   def calculate_transactions_per_user(date_range)
#     total_transactions = Transaction.where(created_at: date_range).count
#     active_users = User.joins(:transactions)
#                       .where(transactions: { created_at: date_range })
#                       .distinct.count
    
#     return 0 if active_users.zero?
    
#     (total_transactions.to_f / active_users).round(2)
#   end
  
#   def calculate_debt_collection_efficiency(date_range)
#     total_debt = Debtor.where(created_at: date_range).sum(:debt_amount)
#     collected_debt = Debtor.where(created_at: date_range, status: 'collected').sum(:debt_amount)
    
#     return 0 if total_debt.zero?
    
#     (collected_debt.to_f / total_debt * 100).round(2)
#   end
  
#   def calculate_processing_time_metrics(date_range)
#     transactions = Transaction.where(created_at: date_range, status: 'completed')
    
#     return { average_processing_time: 0, median_processing_time: 0 } if transactions.empty?
    
#     processing_times = transactions.map do |transaction|
#       (transaction.updated_at - transaction.created_at) / 1.hour
#     end
    
#     {
#       average_processing_time: (processing_times.sum / processing_times.count).round(2),
#       median_processing_time: processing_times.sort[processing_times.count / 2].round(2)
#     }
#   end
  
#   def format_currency(amount)
#     ActionController::Base.helpers.number_to_currency(amount)
#   end
# end