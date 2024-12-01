class Admin::DashboardController < ApplicationController
    before_action :authenticate_admin!
  
    def index
      # Aggregating key data for the dashboard
  
      # General statistics
      @total_users = User.count
      @total_agents = Agent.count
      @total_commissions = Commission.sum(:amount)
      @total_debtors = Debtor.sum(:debt_amount)
      @total_transactions = Transaction.count
      @total_posts = Post.count
  
      # Recent data for quick overview
      @recent_agents = Agent.order(created_at: :desc).limit(5)
      @recent_commissions = Commission.order(created_at: :desc).limit(5)
      @recent_transactions = Transaction.order(created_at: :desc).limit(5)
      @recent_posts = Post.order(created_at: :desc).limit(5)
  
      # Monthly trends and statistics
      @commissions_by_month = Commission.group_by_month(:created_at, range: 1.year.ago..Time.now).sum(:amount)
      @transactions_by_month = Transaction.group_by_month(:created_at, range: 1.year.ago..Time.now).count
      @debtors_by_month = Debtor.group_by_month(:created_at, range: 1.year.ago..Time.now).sum(:debt_amount)
  
      # Pie chart data for the commission distribution per agent (can be used in frontend)
      @commissions_per_agent = Commission.group(:agent_id).sum(:amount)
  
      # Rendering JSON response for frontend (e.g., React)
      render json: {
        total_users: @total_users,
        total_agents: @total_agents,
        total_commissions: @total_commissions,
        total_debtors: @total_debtors,
        total_transactions: @total_transactions,
        total_posts: @total_posts,
        recent_agents: @recent_agents,
        recent_commissions: @recent_commissions,
        recent_transactions: @recent_transactions,
        recent_posts: @recent_posts,
        commissions_by_month: @commissions_by_month,
        transactions_by_month: @transactions_by_month,
        debtors_by_month: @debtors_by_month,
        commissions_per_agent: @commissions_per_agent
      }
    end
  end
  