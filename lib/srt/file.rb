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

    def timeshift(seconds)
      lines.each do |line|
        line.start_time += seconds unless  line.start_time + seconds < 0
        line.end_time += seconds unless  line.end_time + seconds < 0
      end
    end

    def linear_progressive_timeshift(reference_time_a, target_time_a, reference_time_b, target_time_b)
      time_rescale_factor = (target_time_b - target_time_a) / (reference_time_b - reference_time_a)
      time_rebase_shift = target_time_a - reference_time_a * time_rescale_factor

      lines.each do |line|
        line.start_time *= time_rescale_factor
        line.start_time += time_rebase_shift
        line.end_time *= time_rescale_factor
        line.end_time += time_rebase_shift
      end
    end

    def to_s
      lines.map{ |l| [l.sequence, l.time_str, l.text, ""] }.flatten.join("\n")
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