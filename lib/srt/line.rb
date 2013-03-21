module SRT
  class Line
    attr_accessor :sequence
    attr_accessor :start_time
    attr_accessor :end_time
    attr_accessor :error
    attr_writer :text

    def text
      @text ||= []
    end

    def initialize(options={})
      options.each do |k,v|
        self.send("#{k}=",v)
      end
    end

    def empty?
      sequence.nil? && start_time.nil? && end_time.nil? && text.empty?
    end

    def shift(amount)

    end

    def time_str
      [start_time, end_time].map { |t| sprintf("%02d:%02d:%02d,%s", t / 3600, (t % 3600) / 60, t % 60, sprintf("%.3f", t)[-3, 3]) }.join(" --> ")
    end
  end
end
