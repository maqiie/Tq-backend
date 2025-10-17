class Admin::DashboardController < ApplicationController
  before_action :authenticate_user!
  
  # Use a constant for the date range to avoid repetition
  DATE_RANGE = 1.year.ago..Time.current
  
  def index
    begin
      summary_metrics = fetch_summary_metrics
      recent_records = fetch_recent_records
      trends_data = fetch_trends_data
      commissions_distribution = fetch_commissions_distribution
      
      render json: {
        summary_metrics: summary_metrics,
        recent_records: recent_records,
        trends_data: trends_data,
        commissions_distribution: commissions_distribution
      }
    rescue StandardError => e
      Rails.logger.error "Dashboard error: #{e.message}"
      render json: { error: 'An error occurred while fetching dashboard data.' }, status: :internal_server_error
    end
  end
  
  private
  
  # Fetch summary metrics scoped to current user's agents
  def fetch_summary_metrics
    agent_ids = current_user.accessible_agents.pluck(:id)
    
    Rails.cache.fetch("summary_metrics_user_#{current_user.id}", expires_in: 12.hours) do
      {
        total_users: current_user.admin? ? User.where(admin_id: current_user.id).count : 0,
        total_agents: current_user.accessible_agents.count,
        total_commissions: Commission.where(agent_id: agent_ids).sum(:amount),
        total_debtors: Debtor.where(agent_id: agent_ids).sum(:debt_amount),
        total_transactions: Transaction.where(agent_id: agent_ids).count
      }
    end
  end
  
  # Fetch recent records scoped to current user's agents
  def fetch_recent_records
    agent_ids = current_user.accessible_agents.pluck(:id)
    
    Rails.cache.fetch("recent_records_user_#{current_user.id}", expires_in: 1.hour) do
      {
        recent_agents: current_user.accessible_agents
                                  .order(created_at: :desc)
                                  .limit(5)
                                  .as_json(only: [:id, :name, :email, :created_at]),
        recent_commissions: Commission.includes(:agent)
                                     .where(agent_id: agent_ids)
                                     .order(created_at: :desc)
                                     .limit(5)
                                     .as_json(include: { agent: { only: [:id, :name] } }, 
                                             only: [:id, :amount, :created_at]),
        recent_transactions: Transaction.where(agent_id: agent_ids)
                                       .order(created_at: :desc)
                                       .limit(5)
                                       .as_json(only: [:id, :amount, :status, :created_at])
      }
    end
  end
  
  # Fetch trends data scoped to current user's agents
  def fetch_trends_data
    agent_ids = current_user.accessible_agents.pluck(:id)
    
    Rails.cache.fetch("trends_data_user_#{current_user.id}", expires_in: 12.hours) do
      {
        commissions_by_month: Commission.where(agent_id: agent_ids)
                                       .group_by_month(:created_at, range: DATE_RANGE)
                                       .sum(:amount),
        transactions_by_month: Transaction.where(agent_id: agent_ids)
                                         .group_by_month(:created_at, range: DATE_RANGE)
                                         .count,
        debtors_by_month: Debtor.where(agent_id: agent_ids)
                               .group_by_month(:created_at, range: DATE_RANGE)
                               .sum(:debt_amount)
      }
    end
  end
  
  # Fetch commissions distribution scoped to current user's agents
  def fetch_commissions_distribution
    agent_ids = current_user.accessible_agents.pluck(:id)
    
    Rails.cache.fetch("commissions_distribution_user_#{current_user.id}", expires_in: 12.hours) do
      Commission.joins(:agent)
               .where(agent_id: agent_ids)
               .group('agents.name')
               .sum(:amount)
    end
  end
end
# class Admin::DashboardController < ApplicationController
#   before_action :authenticate_admin!

#   # Use a constant for the date range to avoid repetition
#   DATE_RANGE = 1.year.ago..Time.current

#   def index
#     # Use a begin-rescue block to handle exceptions
#     begin
#       summary_metrics = fetch_summary_metrics
#       recent_records = fetch_recent_records
#       trends_data = fetch_trends_data
#       commissions_distribution = fetch_commissions_distribution

#       # Use a presenter or serializer to format the response
#       render json: {
#         summary_metrics: summary_metrics,
#         recent_records: recent_records,
#         trends_data: trends_data,
#         commissions_distribution: commissions_distribution
#       }
#     rescue StandardError => e
#       # Log the error for debugging
#       Rails.logger.error "Dashboard error: #{e.message}"
#       render json: { error: 'An error occurred while fetching dashboard data.' }, status: :internal_server_error
#     end
#   end

#   private

#   # Fetch summary metrics
#   def fetch_summary_metrics
#     Rails.cache.fetch('summary_metrics', expires_in: 12.hours) do
#       {
#         total_users: User.count,
#         total_agents: Agent.count,
#         total_commissions: Commission.sum(:amount),
#         total_debtors: Debtor.sum(:debt_amount),
#         total_transactions: Transaction.count
#       }
#     end
#   end

#   # Fetch recent records
#   def fetch_recent_records
#     Rails.cache.fetch('recent_records', expires_in: 1.hour) do
#       {
#         recent_agents: Agent.order(created_at: :desc).limit(5).as_json(only: [:id, :name, :email, :created_at]),
#         recent_commissions: Commission.includes(:agent).order(created_at: :desc).limit(5).as_json(include: { agent: { only: [:id, :name] } }, only: [:id, :amount, :created_at]),
#         recent_transactions: Transaction.order(created_at: :desc).limit(5).as_json(only: [:id, :amount, :status, :created_at])
#       }
#     end
#   end

#   # Fetch trends data
#   def fetch_trends_data
#     Rails.cache.fetch('trends_data', expires_in: 12.hours) do
#       {
#         commissions_by_month: Commission.group_by_month(:created_at, range: DATE_RANGE).sum(:amount),
#         transactions_by_month: Transaction.group_by_month(:created_at, range: DATE_RANGE).count,
#         debtors_by_month: Debtor.group_by_month(:created_at, range: DATE_RANGE).sum(:debt_amount)
#       }
#     end
#   end

#   # Fetch commissions distribution
#   def fetch_commissions_distribution
#     Rails.cache.fetch('commissions_distribution', expires_in: 12.hours) do
#       Commission.joins(:agent).group('agents.name').sum(:amount)
#     end
#   end
# end