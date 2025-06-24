module Admin
    class DebtorsController < ApplicationController
      before_action :authenticate_user!
      before_action :ensure_admin!
  
      def index
        @debtors = Debtor.all.includes(:agent)
        render json: @debtors.as_json(include: :agent)
      end
  
      private
  
      def ensure_admin!
        render json: { error: "Unauthorized" }, status: :unauthorized unless current_user&.admin?
      end
    end
  end
  