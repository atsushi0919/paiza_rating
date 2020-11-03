N = 3
PATH = "sample_data.txt"

class InputData
  def initialize(**params)
  end
end

def trim_input_data(input_data)
  input_data.each_slice(N) do |title, result, aggregate|
    # titleの処理
    title, date = title.split(",").map(&:strip)
    id = title.slice(0..3)
    title = title.slice(5..-1)

    # resultの処理
    language, time, performance, points = result.split(",").compact.reject(&:empty?).map(&:strip)
    p time.slice(0..-2).split("分").map(&:to_i)
    #p [language, time, performance, points]
  end
end

def main
  input_data = File.open(PATH, "r") { |f| f.readlines }
  trim_input_data(input_data)
end

main
