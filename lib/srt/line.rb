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
  end
end
