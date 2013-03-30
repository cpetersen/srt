module SRT
  class File
    def self.parse(file)
      result = SRT::File.new
      line = SRT::Line.new
      file.each_with_index do |str, index|
        begin
          if str.strip.empty?
            result.lines << line unless line.empty?
            line = SRT::Line.new
          elsif !line.error

            if line.sequence.nil?
              line.sequence = str.to_i
            elsif line.start_time.nil?
              if mres = str.match(/(?<start_timecode>[^[[:space:]]]+) -+> (?<end_timecode>[^[[:space:]]]+) ?(?<display_coordinates>X1:\d+ X2:\d+ Y1:\d+ Y2:\d+)?/)
                
                if (line.start_time = SRT::File.parse_timecode(mres["start_timecode"])) == nil
                  line.error = "#{line}, Invalid formatting of start timecode, [#{mres["start_timecode"]}]"
                  puts line.error
                end

                if (line.end_time = SRT::File.parse_timecode(mres["end_timecode"])) == nil
                  line.error = "#{line}, Invalid formatting of end timecode, [#{mres["end_timecode"]}]"
                  puts line.error
                end

                if mres["display_coordinates"]
                  line.display_coordinates = mres["display_coordinates"]
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

    def split(instructions)
      if instructions.length == 1 && instructions[:at]
        split_points = [instructions[:at]].flatten.map{ |timecode| SRT::File.parse_timecode(timecode) }.sort
        split_offsprings = [SRT::File.new]

        loss_compensation = 0

        lines.each_with_index do |line, index|
          if split_points.empty? || line.end_time <= split_points.first
            split_offsprings.last.lines << line.clone
            split_offsprings.last.lines.last.start_time -= loss_compensation
            split_offsprings.last.lines.last.end_time -= loss_compensation
          elsif line.start_time < split_points.first
            split_offsprings.last.lines << line.clone
            split_offsprings.last.lines.last.start_time -= loss_compensation
            split_offsprings.last.lines.last.end_time = split_points.first - loss_compensation
            loss_compensation = split_points.first
            split_points.delete_at(0)
            split_offsprings << SRT::File.new
            split_offsprings.last.lines << line.clone
            split_offsprings.last.lines.last.start_time = 0
            split_offsprings.last.lines.last.end_time -= loss_compensation                        
          else
            loss_compensation = split_points.first
            split_points.delete_at(0)
            split_offsprings << SRT::File.new
            split_offsprings.last.lines << line.clone
            split_offsprings.last.lines.last.start_time -= loss_compensation
            split_offsprings.last.lines.last.end_time -= loss_compensation            
          end
        end
      end

      split_offsprings
    end

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
      lines.map{ |l| [l.sequence, (l.display_coordinates ? l.time_str + l.display_coordinates : l.time_str), l.text, ""] }.flatten.join("\n")
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
      mres ? mres["fps"].to_f : nil
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