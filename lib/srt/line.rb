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
      [@start_time, @end_time].map { |t|  f=sprintf("%.3f", t); ip=f[0,f.size-4].to_i;fp=f[-3,3]; "%02d:%02d:%02d#{subframe_separator}%s" % [ip / 3600, (ip % 3600) / 60, ip % 60,fp] }.join(" --> ")
    end

    def webvtt_time_str
      time_str(".")
    end

    def to_s(time_str_function=:time_str)
      content = text.empty? ? [''] : text
      coordinates = display_coordinates ? display_coordinates : ""
      [sequence, send(time_str_function) + coordinates, content, ""].flatten.join("\n")
    end
  end
end
