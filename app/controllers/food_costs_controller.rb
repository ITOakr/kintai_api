class FoodCostsController < ApplicationController
  before_action :authenticate!
  before_action :require_admin!

  # GET /v1/food_costs?date=YYYY-MM-DD
  def show
    date = parse_date!(params[:date])
    return if performed?
    food_cost = FoodCost.where(date: date)
    render json: food_cost.map { |fc| serialize(fc) }
  end

  # PUT /v1/food_costs?date=YYYY-MM-DD
  # body: amount_yen, note(optional)
  def upsert
    date = parse_date!(params[:date])
    return if performed?

    # フロントエンドから送られてくる食材費リスト
    food_cost_items = params.require(:food_costs)

    # 一つでも保存に失敗したら全ての変更を元に戻す（トランザクション）
    FoodCost.transaction do
      # その日の食材費を一旦全削除
      FoodCost.where(date: date).delete_all

      # 新しいデータを１つずつ保存
      food_cost_items.each do |item|
        safe_params = item.permit(:category, :amount_yen, :note)
        FoodCost.create!(date: date, **safe_params)
      end
    end

    # 最新のデータを取得して返す
    new_food_costs = FoodCost.where(date: date)
    render json: new_food_costs.map { |fc| serialize(fc) }

  rescue ActiveRecord::RecordInvalid => e
    render json: { errors: e.record.errors.full_messages }, status: :unprocessable_entity
  end

  private

  def parse_date!(date_str)
    Date.parse(date_str.presence || Date.today.to_s)
  rescue ArgumentError
    render json: { error: "invalid_date_format" }, status: :bad_request
  end

  def serialize(fc)
    {
      id: fc.id,
      date: fc.date.to_s,
      category: fc.category,
      amount_yen: fc.amount_yen,
      note: fc.note
    }
  end
end
