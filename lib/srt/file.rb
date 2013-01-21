module SRT
  class File
    def self.parse(file)
      result = SRT::File.new
      line = SRT::Line.new
      file.each_with_index do |str, index|
        begin
          if line.error
            if str.strip.empty?
              result.lines << line unless line.empty?
              line = SRT::Line.new
            end
          else
            if str.strip.empty?
              result.lines << line unless line.empty?
              line = SRT::Line.new
            elsif line.sequence.nil?
              line.sequence = str.to_i
            elsif line.start_time.nil?
              matcher = str.match(/(.*) -+> (.*)/)
              if matcher
                line.start_time = DateTime.strptime(matcher[1].strip, "%H:%M:%S,%L")
                line.end_time = DateTime.strptime(matcher[2].strip, "%H:%M:%S,%L")
              else
                line.error = "#{line}, Invalid Time String, [#{str}]"
              end
            else
              line.text << str.strip
            end
          end
        rescue
          line.error = "#{index}, General Error, [#{str}]"
          puts line.error
        end
      end
      result
    end

    attr_writer :lines
    def lines
      @lines ||= []
    end

    def errors
      lines.collect { |l| l.error if l.error }.compact
    end
  end
end
