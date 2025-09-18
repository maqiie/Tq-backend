# app/controllers/admin/exports_controller.rb
module Admin
  class ExportsController < ApplicationController
    # before_action :authenticate_user!
    # before_action :authenticate_admin!

    def full_report
      set_date_range
      load_all_data

      respond_to do |format|
        format.xlsx do
          response.headers['Content-Disposition'] =
            "attachment; filename=\"full_report_#{Date.current.strftime('%Y%m%d')}.xlsx\""
        end
      end
    end

    def transactions
      set_date_range
      @transactions = Transaction.includes(:agent)
      @transactions = filter_by_date_range(@transactions) if @start_date || @end_date
      @transactions = @transactions.order(created_at: :desc)

      respond_to do |format|
        format.xlsx do
          response.headers['Content-Disposition'] =
            "attachment; filename=\"transactions_#{Date.current.strftime('%Y%m%d')}.xlsx\""
        end
      end
    end

    def agents
      @agents = Agent.includes(:user).order(:name)

      respond_to do |format|
        format.xlsx do
          response.headers['Content-Disposition'] =
            "attachment; filename=\"agents_#{Date.current.strftime('%Y%m%d')}.xlsx\""
        end
      end
    end

    def debtors
      set_date_range
      @debtors = Debtor.includes(:agent)
      @debtors = filter_by_date_range(@debtors) if @start_date || @end_date
      @debtors = @debtors.order(:name)

      respond_to do |format|
        format.xlsx do
          response.headers['Content-Disposition'] =
            "attachment; filename=\"debtors_#{Date.current.strftime('%Y%m%d')}.xlsx\""
        end
      end
    end

    def commissions
      set_date_range
      @commissions = Commission.includes(:agent)

      if @start_date && @end_date
        start_year = @start_date.year
        start_month = @start_date.month
        end_year = @end_date.year
        end_month = @end_date.month

        @commissions = @commissions.where(
          "(year > ? OR (year = ? AND month >= ?)) AND (year < ? OR (year = ? AND month <= ?))",
          start_year, start_year, start_month, end_year, end_year, end_month
        )
      end

      @commissions = @commissions.order(:year, :month)

      respond_to do |format|
        format.xlsx do
          response.headers['Content-Disposition'] =
            "attachment; filename=\"commissions_#{Date.current.strftime('%Y%m%d')}.xlsx\""
        end
      end
    end

    private

    def authenticate_admin!
      unless current_user&.admin?
        render json: { error: 'You must be an admin to perform this action.' }, status: :forbidden
      end
    end

    def set_date_range
      if params[:range].present?
        case params[:range]
        when 'week'
          @start_date = 1.week.ago.beginning_of_week
          @end_date = Date.current.end_of_week
        when 'month'
          @start_date = Date.current.beginning_of_month
          @end_date = Date.current.end_of_month
        when 'quarter'
          @start_date = Date.current.beginning_of_quarter
          @end_date = Date.current.end_of_quarter
        when 'year'
          @start_date = Date.current.beginning_of_year
          @end_date = Date.current.end_of_year
        when 'last_month'
          @start_date = 1.month.ago.beginning_of_month
          @end_date = 1.month.ago.end_of_month
        when 'last_quarter'
          @start_date = 3.months.ago.beginning_of_quarter
          @end_date = 3.months.ago.end_of_quarter
        end
      else
        @start_date = Date.parse(params[:start_date]) if params[:start_date].present?
        @end_date = Date.parse(params[:end_date]) if params[:end_date].present?
      end
    rescue ArgumentError
      @start_date = @end_date = nil
    end

    def load_all_data
      @agents = Agent.includes(:user).order(:name)

      @transactions = Transaction.includes(:agent)
      @transactions = filter_by_date_range(@transactions) if @start_date || @end_date
      @transactions = @transactions.order(created_at: :desc)

      @debtors = Debtor.includes(:agent)
      @debtors = filter_by_date_range(@debtors) if @start_date || @end_date
      @debtors = @debtors.order(:name)

      @commissions = Commission.includes(:agent)
      if @start_date && @end_date
        start_year = @start_date.year
        start_month = @start_date.month
        end_year = @end_date.year
        end_month = @end_date.month

        @commissions = @commissions.where(
          "(year > ? OR (year = ? AND month >= ?)) AND (year < ? OR (year = ? AND month <= ?))",
          start_year, start_year, start_month, end_year, end_year, end_month
        )
      end
      @commissions = @commissions.order(:year, :month)
    end

    def filter_by_date_range(relation)
      relation = relation.where("created_at >= ?", @start_date) if @start_date
      relation = relation.where("created_at <= ?", @end_date.end_of_day) if @end_date
      relation
    end
  end
end
