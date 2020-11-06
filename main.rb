# An class to Calculate Glicko rating
# The class holds
#   - @rating: glicko rating
#   - @rd: rating deviation
#   - @updated_at: the time when the rating is calculated.
# Ref:
#   http://www.glicko.net/glicko/glicko.pdf

class GlickoPlayer
  attr_accessor :rating, :rd  # reader -> accessor
  attr_reader :updated_at

  Q = Math.log(10.0) / 400.0

  def initialize(rating = 1500.0, rd = 350.0, updated_at = nil, c: 5.0, rd_min: 0.0, rd_max: 350.0)
    @rating = (rating || 1500.0).to_f
    @rd = (rd || 350).to_f
    @updated_at = updated_at
    @c = (c || 5.0).to_f
    @rd_min = (rd_min || 0.0).to_f
    @rd_max = (rd_max || 350.0).to_f
  end

  # Glicko Rating calculation STEP 1.
  # Update the rating based on the time.
  # For now, as "@c" is set to zero, the rating does not change.
  def update_time(now)
    t = @updated_at ? (now - @updated_at) : 0
    @rd = Math.sqrt(@rd ** 2 + @c ** 2 * t).clamp(@rd_min, @rd_max)
    @updated_at = now
  end

  # Glicko Rating calculation STEP 2
  # Update rating based on the fight.
  def fight(opponent, s)
    s = s.to_f
    opponent_rating = opponent.rating
    opponent_rd = opponent.rd
    g_opponent_rd = calc_g(opponent_rd)
    e = 1 / (1 + 10 ** (-g_opponent_rd * (rating - opponent_rating) / 400.0))
    d_squared_inv = Q ** 2 * g_opponent_rd ** 2 * e * (1 - e)
    rd_d_square = 1 / (1 / @rd ** 2 + d_squared_inv)
    rd_d_square = rd_d_square.clamp(@rd_min ** 2, @rd_max ** 2)
    @rating += Q * (rd_d_square) * g_opponent_rd * (s - e)
    # puts "rd: #{@rd} -> #{Math.sqrt(rd_d_square)}, d_squared_inv: #{d_squared_inv}"
    @rd = Math.sqrt(rd_d_square)
    # puts "rating=#{@rating} rd=#{@rd}, rd_d_square=#{rd_d_square}, rd_min=#{@rd_min}"

    # puts "g_opponent_rd=#{g_opponent_rd}, e=#{e}, d_squared_inv=#{d_squared_inv}, d=#{1/Math.sqrt(d_squared_inv)}, rd_d_square=#{rd_d_square}"
  end

  def to_s
    "rating: #{@rating}, rd: #{@rd}, updated_at: #{@updated_at}"
  end

  private

  # For "fight" method
  def calc_g(rd)
    1 / Math.sqrt(1 + 3 * Q ** 2 * rd ** 2 / Math::PI ** 2)
  end
end

# koko kara saki ha washi ga sodateta
# 2020/11/06 @atsushi_0919_
# Ref:
#   https://paiza.hatenablog.com/entry/2019/09/10/paiza_glicko_rating

require "time"

def split_trim(data)
  data.split(",").compact.reject(&:empty?).map(&:strip)
end

def split_time(time)
  time[0..-2].split("分").map(&:to_i)
end

def trim_title_data(title_data)
  title, date = title_data.split(",").map(&:strip)
  id = title[0..3]
  title = title[5..-1]
  date = Time.strptime(date, "%Y/%m/%d %H:%M")
  { id: id, title: title, date: date }
end

def trim_result_data(result_data)
  language, time, performance, score = split_trim(result_data)
  time = split_time(time)
  performance = performance[0]
  score = score.delete("^0-9").to_i
  { language: language, time: time, performance: performance, score: score }
end

def trim_aggregate_data(aggregate_data)
  level, count1, count2, correct_rate, avg_time, avg_point = split_trim(aggregate_data)
  level = level.delete!("±").split.map(&:to_i)
  count = (count1 + count2).delete("^0-9").to_i
  correct_rate = correct_rate.delete("^[0-9|.]").to_f
  avg_time = split_time(avg_time)
  avg_point = avg_point.split[-1].to_f
  { level: level, count: count, correct_rate: correct_rate, avg_time: avg_time, avg_point: avg_point }
end

def trim_input_data(input_data)
  result = []
  input_data.each_slice(3) do |title_data, result_data, aggregate_data|
    # titleの処理
    param = trim_title_data(title_data)
    # resultの処理
    param.merge!(trim_result_data(result_data))
    # aggregateの処理
    param.merge!(trim_aggregate_data(aggregate_data))

    result << param
  end
  result
end

def read_data
  # input_data = readlines.map(&:chomp)
  input_data = File.open(PATH, "r") { |f| f.readlines }
  trim_input_data(input_data)
end

def make_result_msg(result)
  date = result[:date].strftime("%Y-%m-%d")
  if result[:time][0] < 1000
    time = "#{result[:time][0].to_s.rjust(1, "0")}m#{result[:time][1].to_s.rjust(2, "0")}s"
  else
    time = "-m--s"
  end

  msg = "[#{date}] 問題: #{result[:id]} 難易度: #{result[:level][0].to_s.rjust(4)} ±#{result[:level][1].to_s.rjust(2)} "
  msg += " >> lang: #{result[:language].ljust(7)} score: #{result[:score].to_s.rjust(3)} (#{time.to_s.rjust(7)})"
end

PATH = "mydata.txt"
skill_check_results = read_data.sort_by { |x| x[:date] }

# user, task を初期化
user = GlickoPlayer.new(750, 350)
task = GlickoPlayer.new

# スキルチェック結果を呼び出す
skill_check_results.each do |result|
  task.rating, task.rd = result[:level]

  #puts "[#{user.rating.to_i}, #{task.rating}, #{user.rd.to_i}, #{task.rd.to_i]"
  #puts "[#{user.rating.to_i}, #{user.rd.to_i}"

  old_user = user.dup
  old_task = task.dup

  win = result[:score] == 100 ? 1 : 0
  user.fight(old_task, win)
  icon =

    msg = make_result_msg(result)
  msg += " >> paiza-Rating: #{old_user.rating.round.to_s.rjust(4)} -> #{user.rating.round.to_s.rjust(4)}"
  if old_user.rating.round < user.rating.round
    msg += " ↑"
  end
  puts msg
  # puts "#{result[:date].strftime("%Y/%m/%d")}, #{result[:id]}, #{user.rating}"
end
