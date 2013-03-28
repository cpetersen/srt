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
              if mres = str.match(/(?<start_timecode>[^[[:space:]]]+) -+> (?<end_timecode>[^[[:space:]]]+)/)
                
                if (line.start_time = SRT::File.parse_timecode(mres["start_timecode"])) == nil
                  line.error = "#{line}, Invalid formatting of start timecode, [#{mres["start_timecode"]}]"
                  puts line.error
                end

                if (line.end_time = SRT::File.parse_timecode(mres["end_timecode"])) == nil
                  line.error = "#{line}, Invalid formatting of end timecode, [#{mres["end_timecode"]}]"
                  puts line.error
                end
              else
                line.error = "#{line}, Invalid Time Line formatting, [#{str}]"
                puts line.error
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

    # timeshift(instructions)
    #
    # constantly shift all subtitles
    # e.g. { :all => "-3.4s" }
    #      { :all => "1.5m" }
    #      { :all => "+700mil" }
    #
    # framerate conversion
    # e.g. { "25fps" => "23.99999fps" }
    # note: this implements a naive approach of what framerate conversion does or should do;
    #       it probably won't statisfy what video professionals expect - but it's a start :)    
    #
    # linear progressive timeshift
    # e.g. { 12 => "+10s", 569 => "+2.34m" }
    #      { 23 => "00:02:12,400", 843 => "01:38:06,000" }
    #      { "00:01:10,000" => "55s", "01:33:07,200" => "2.3m" } 
    #      { "00:01:10,000" => "00:02:12,400", "01:33:07,200" => "01:38:06,000" }
    #      { 57 => "00:02:12,400", "01:33:07,200" => "+13s" }
    def timeshift(instructions)
      if instructions.length == 1
        if instructions[:all] && (seconds = SRT::File.parse_timespan(instructions[:all]))
          lines.each do |line|
            line.start_time += seconds unless line.start_time + seconds < 0
            line.end_time += seconds unless line.end_time + seconds < 0
          end
        elsif (original_framerate = SRT::File.parse_framerate(instructions.keys[0])) && (target_framerate = SRT::File.parse_framerate(instructions.values[0]))
          ratio = target_framerate / original_framerate
          lines.each do |line|
            line.start_time *= ratio
            line.end_time *= ratio
          end
        end
      elsif instructions.length == 2
        original_timecode_a = (instructions.keys[0].is_a?(String) ? SRT::File.parse_timecode(instructions.keys[0]) : lines[instructions.keys[0] - 1].start_time)
        original_timecode_b = (instructions.keys[1].is_a?(String) ? SRT::File.parse_timecode(instructions.keys[1]) : lines[instructions.keys[1] - 1].start_time)
        target_timecode_a = SRT::File.parse_timecode(instructions.values[0]) || (original_timecode_a + SRT::File.parse_timespan(instructions.values[0]))
        target_timecode_b = SRT::File.parse_timecode(instructions.values[1]) || (original_timecode_b + SRT::File.parse_timespan(instructions.values[1]))

        time_rescale_factor = (target_timecode_b - target_timecode_a) / (original_timecode_b - original_timecode_a)
        time_rebase_shift = target_timecode_a - original_timecode_a * time_rescale_factor

        lines.each do |line|
          line.start_time = line.start_time * time_rescale_factor + time_rebase_shift
          line.end_time = line.end_time * time_rescale_factor + time_rebase_shift
        end
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

    protected

    def self.parse_framerate(framerate_string)
      mres = framerate_string.match(/(?<fps>\d+((\.)?\d+))(fps)/)
      mres ? mres["fps"] : nil
    end

    def self.parse_timecode(timecode_string)
      mres = timecode_string.match(/(?<h>\d+):(?<m>\d+):(?<s>\d+),(?<mil>\d+)/)
      mres ? "#{mres["h"].to_i * 3600 + mres["m"].to_i * 60 + mres["s"].to_i}.#{mres["mil"]}".to_f : nil
    end

    def self.parse_timespan(timespan_string)
      factors = { 
        "mil" => 0.001,
        "s" => 1,
        "m" => 60,
        "h" => 3600 
      }

      mres = timespan_string.match(/(?<amount>(\+|-)?\d+((\.)?\d+))(?<unit>mil|s|m|h)/)
      mres ? mres["amount"].to_f * factors[mres["unit"]] : nil
    end
  end
end