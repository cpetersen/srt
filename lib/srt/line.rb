module SRT
  class Line
    attr_accessor :display_coordinates
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

    def clone
      clone = Line.new
      clone.display_coordinates = display_coordinates
      clone.sequence = sequence
      clone.start_time = start_time
      clone.end_time = end_time
      clone.error = error
      clone.text = text.clone
      clone
    end

    def empty?
      sequence.nil? && start_time.nil? && end_time.nil? && text.empty?
    end

    def time_str(subframe_separator=",")
      [@start_time, @end_time].map { |t| sprintf("%02d:%02d:%02d#{subframe_separator}%s", t / 3600, (t % 3600) / 60, t % 60, sprintf("%.3f", t)[-3, 3]) }.join(" --> ")
    end

    def webvtt_time_str
      time_str(".")
    end

    def to_s(time_str_function=:time_str)
      [sequence, (display_coordinates ? send(time_str_function) + display_coordinates : send(time_str_function)), text, ''].flatten.join("\n")
    end
  end
end
