class UpsertFoodCostsService
  attr_reader :errors
  def initialize(date, food_cost_items, admin_user)
    @date = date
    @items = food_cost_items
    @admin_user = admin_user
    @errors = []
  end

  def perform
    old_total_amount = FoodCost.where(date: @date).sum(:amount_yen)

    FoodCost.transaction do
      FoodCost.where(date: @date).destroy_all

      @items.each do |item|
        FoodCost.create!(date: @date, **item.to_h)
      end
    end

    new_total_amount = @items.sum { |item| item[:amount_yen].to_i }
    create_log_if_changed(old_total_amount, new_total_amount)
    true
  rescue ActiveRecord::RecordInvalid => e
    @errors = e.record.errors.full_messages
    false
  end

  private

  def create_log_if_changed(old_total, new_total)
    return if old_total == new_total

    is_new_record = old_total.zero?
    action, details = if is_new_record
      [ "食材費登録", "#{@date}の食材費を「#{new_total}円」で登録しました。" ]
    else
      [ "食材費更新", "#{@date}の食材費を「#{old_total}円」から「#{new_total}円」に更新しました。" ]
    end

    AdminLog.create!(
      admin_user: @admin_user,
      action: action,
      details: details
    )
  end
end
