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
              mres = str.match(/(\d+):(\d+):(\d+),(\d+) -+> (\d+):(\d+):(\d+),(\d+)/)
              if mres
                line.start_time = "#{mres[1].to_i * 3600 + mres[2].to_i * 60 + mres[3].to_i}.#{mres[4]}".to_f
                line.end_time = "#{mres[5].to_i * 3600 + mres[6].to_i * 60 + mres[7].to_i}.#{mres[8]}".to_f
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

    def to_s
      result = []
      lines.each do |line|
        result << line.sequence
        result << line.time_str
        result += line.text
        result << ""
      end
      result.join("\n")
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
