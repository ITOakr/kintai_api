class SalesController < ApplicationController
  before_action :authenticate!
  before_action :require_admin!

  # GET /v1/sales?date=YYYY-MM-DD
  def show
    date = parse_date!(params[:date])
    return if performed?
    sale = Sale.find_by(date: date)
    render json: sale ? serialize(sale) : { date: date.to_s, amount_yen: nil, note: nil }
  end

  # PUT /v1/sales?date=YYYY-MM-DD
  # body: amount_yen, note(optional)
  def upsert
    date = parse_date!(params[:date])
    amount = params[:amount_yen].to_i
    note = params[:note].presence

    sale = Sale.find_or_initialize_by(date: date)

    is_new_record = !sale.persisted? # 保存されていない、かつ今までに削除されていない
    old_amount = is_new_record ? nil : sale.amount_yen  # 変更前の値を保持
    sale.amount_yen = amount
    sale.note = note

    if sale.save
      if is_new_record
        action = "売上登録"
        details = "#{sale.date}の売上を「#{sale.amount_yen}円」で登録しました。"
      else
        action = "売上更新"
        details = "#{sale.date}の売上を「#{old_amount}円」から「#{sale.amount_yen}円」に更新しました。"
      end
      create_admin_log(
        action: action,
        details: details
      )
      render json: serialize(sale)
    else
      render json: { errors: sale.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  def parse_date!(date_str)
    Date.parse(date_str.presence || Date.today.to_s)
  rescue ArgumentError
    render json: { error: "invalid_date_format" }, status: :bad_request
  end

  def serialize(sale)
    {
      id: sale.id,
      date: sale.date.to_s,
      amount_yen: sale.amount_yen,
      note: sale.note
    }
  end
end
