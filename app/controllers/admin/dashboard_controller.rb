class Admin::DashboardController < ApplicationController
  before_action :authenticate_admin!

  def index
    # Summary Metrics
    total_users = User.count
    total_agents = Agent.count
    total_commissions = Commission.sum(:amount)
    total_debtors = Debtor.sum(:debt_amount)
    total_transactions = Transaction.count

    # Recent Records
    recent_agents = Agent.order(created_at: :desc).limit(5).as_json(only: [:id, :name, :email, :created_at])
    recent_commissions = Commission.includes(:agent).order(created_at: :desc).limit(5).as_json(include: { agent: { only: [:id, :name] } }, only: [:id, :amount, :created_at])
    recent_transactions = Transaction.order(created_at: :desc).limit(5).as_json(only: [:id, :amount, :status, :created_at])

    # Trends Over Last 12 Months
    commissions_by_month = Commission.group_by_month(:created_at, range: 1.year.ago..Time.current).sum(:amount)
    transactions_by_month = Transaction.group_by_month(:created_at, range: 1.year.ago..Time.current).count
    debtors_by_month = Debtor.group_by_month(:created_at, range: 1.year.ago..Time.current).sum(:debt_amount)

    # Pie Chart: Commission Distribution per Agent
    commissions_per_agent = Commission.joins(:agent)
                                      .group('agents.name')
                                      .sum(:amount)

    # Build JSON response for the React frontend
    render json: {
      total_users:,
      total_agents:,
      total_commissions:,
      total_debtors:,
      total_transactions:,
      recent_agents:,
      recent_commissions:,
      recent_transactions:,
      commissions_by_month:,
      transactions_by_month:,
      debtors_by_month:,
      commissions_per_agent:
    }
  end
end
