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
    food_cost_items = food_cost_params

    # 変更前の値を保持
    old_total_amount = FoodCost.where(date: date).sum(:amount_yen)
    is_new_record = old_total_amount.zero?

    # 一つでも保存に失敗したら全ての変更を元に戻す（トランザクション）
    FoodCost.transaction do
      # その日の食材費を一旦全削除
      FoodCost.where(date: date).destroy_all

      # 新しいデータを１つずつ保存
      food_cost_items.each do |item|
        FoodCost.create!(date: date, **item.to_h)
      end
    end

    new_total_amount = food_cost_items.sum { |item| item[:amount_yen].to_i }

    if is_new_record
      action = "食材費登録"
      details = "#{date}の食材費を「#{new_total_amount}円」で登録しました。"
    else
      action = "食材費更新"
      details = "#{date}の食材費を「#{old_total_amount}円」から「#{new_total_amount}円」に更新しました。"
    end

    if old_total_amount != new_total_amount
      # 変更があった場合の処理
      create_admin_log(
        action: action,
        details: details
      )
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

  def food_cost_params
    (params[:food_costs] || []).map do |item|
      item.permit(:category, :amount_yen, :note)
    end
  end
end
