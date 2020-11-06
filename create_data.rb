def split_trim(data)
  data.split(",").compact.reject(&:empty?).map(&:strip)
end

def split_time(time)
  time[0..-2].split("^0-9").map(&:to_i)
end

def trim_title_data(title_data)
  title, date = title_data.split(",").map(&:strip)
  id = title[0..3]
  title = title[5..-1]
  { id: id, title: title }
end

def trim_result_data(result_data)
  language, time, performance, points = split_trim(result_data)
  time = split_time(time)
  performance = performance[0]
  points = points.delete("^0-9").to_i
  { language: language, time: time, performance: performance, points: points }
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
  input_data.each_slice(N) do |title_data, result_data, aggregate_data|
    # titleの処理
    param = trim_title_data(title_data)
    p "#{param[:id]}, #{param[:title]}"
    # resultの処理
    param.merge!(trim_result_data(result_data))
    # aggregateの処理
    param.merge!(trim_aggregate_data(aggregate_data))

    result << param
  end
  result
end

def main
  input_data = File.open(PATH, "r") { |f| f.readlines }
  trim_input_data(input_data)
end

N = 3
PATH = "sample_data.txt"
main
