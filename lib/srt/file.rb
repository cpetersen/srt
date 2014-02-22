module SRT
  class File
    def self.parse(input, options = {})
      @debug = options.fetch(:debug, false)
      if input.is_a?(String)
        parse_string(input)
      elsif input.is_a?(::File)
        parse_file(input)
      else
        raise "Invalid input. Expected a String or File, got #{input.class.name}."
      end
    end

    def self.parse_file(srt_file)
      parse_string ::File.open(srt_file, 'rb') { |f| srt_file.read }
    end

    def self.parse_string(srt_data)
      result = new
      line = SRT::Line.new

      split_srt_data(srt_data).each_with_index do |str, index|
        begin
          if str.strip.empty?
            result.lines << line unless line.empty?
            line = SRT::Line.new
          elsif !line.error
            if line.sequence.nil?
              line.sequence = str.to_i
            elsif line.start_time.nil?
              if mres = str.match(/(?<start_timecode>[^[[:space:]]]+) -+> (?<end_timecode>[^[[:space:]]]+) ?(?<display_coordinates>X1:\d+ X2:\d+ Y1:\d+ Y2:\d+)?/)

                if (line.start_time = Parser.timecode(mres["start_timecode"])) == nil
                  line.error = "#{index}, Invalid formatting of start timecode, [#{mres["start_timecode"]}]"
                  $stderr.puts line.error if @debug
                end

                if (line.end_time = Parser.timecode(mres["end_timecode"])) == nil
                  line.error = "#{index}, Invalid formatting of end timecode, [#{mres["end_timecode"]}]"
                  $stderr.puts line.error if @debug
                end

                if mres["display_coordinates"]
                  line.display_coordinates = mres["display_coordinates"]
                end
              else
                line.error = "#{index}, Invalid Time Line formatting, [#{str}]"
                $stderr.puts line.error if @debug
              end
            else
              line.text << str.strip
            end

          end
        rescue
          line.error = "#{index}, General Error, [#{str}]"
          $stderr.puts line.error if @debug
        end
      end
      result
    end

    # Ruby often gets the wrong encoding for a file and will throw
    # errors on `split` for invalid byte sequences. This chain of
    # fallback encodings lets us get something that works.
    def self.split_srt_data(srt_data)
      begin
        srt_data.split(/\n/) + ["\n"]
      rescue
        begin
          srt_data.force_encoding('utf-8').split(/\n/) + ["\n"]
        rescue
          srt_data.force_encoding('iso-8859-1').split(/\n/) + ["\n"]
        end
      end
    end

    def append(options)
      if options.length == 1 && options.values[0].class == self.class
        reshift = Parser.timecode(options.keys[0]) || (lines.last.end_time + Parser.timespan(options.keys[0]))
        renumber = lines.last.sequence

        options.values[0].lines.each do |line|
          lines << line.clone
          lines.last.sequence += renumber
          lines.last.start_time += reshift
          lines.last.end_time += reshift
        end
      end

      self
    end

    def split(options)
      options = { :timeshift => true, :renumber => true }.merge(options)

      split_points = []

      if (options[:at])
        split_points = [options[:at]].flatten.map{ |timecode| Parser.timecode(timecode) }.sort
      elsif (options[:every])
        interval = Parser.timecode(options[:every])
        max = lines.last.end_time
        (interval..max).step(interval){ |t| split_points << t }
      end

      if (split_points.count > 0)
        split_offsprings = [SRT::File.new]

        reshift = 0
        renumber = 0

        lines.each do |line|
          if split_points.empty? || line.end_time <= split_points.first
            cloned_line = line.clone
            cloned_line.sequence -= renumber if options[:renumber]
            if options[:timeshift]
              cloned_line.start_time -= reshift
              cloned_line.end_time -= reshift
            end
            split_offsprings.last.lines << cloned_line
          elsif line.start_time < split_points.first
            cloned_line = line.clone
            cloned_line.sequence -= renumber if options[:renumber]
            if options[:timeshift]
              cloned_line.start_time -= reshift
              cloned_line.end_time = split_points.first - reshift
            end
            split_offsprings.last.lines << cloned_line

            renumber = line.sequence - 1
            reshift = split_points.first
            split_points.delete_at(0)

            split_offsprings << SRT::File.new
            cloned_line = line.clone
            cloned_line.sequence -= renumber if options[:renumber]
            if options[:timeshift]
              cloned_line.start_time = 0
              cloned_line.end_time -= reshift
            end
            split_offsprings.last.lines << cloned_line
          else
            renumber = line.sequence - 1
            reshift = split_points.first
            split_points.delete_at(0)

            split_offsprings << SRT::File.new
            cloned_line = line.clone
            cloned_line.sequence -= renumber if options[:renumber]
            if options[:timeshift]
              cloned_line.start_time -= reshift
              cloned_line.end_time -= reshift
            end
            split_offsprings.last.lines << cloned_line
          end
        end
      end

      split_offsprings
    end

    def timeshift(options)
      if options.length == 1
        if options[:all] && (seconds = Parser.timespan(options[:all]))
          lines.each do |line|
            line.start_time += seconds
            line.end_time += seconds
          end
        elsif (original_framerate = Parser.framerate(options.keys[0])) && (target_framerate = Parser.framerate(options.values[0]))
          ratio = target_framerate / original_framerate
          lines.each do |line|
            line.start_time *= ratio
            line.end_time *= ratio
          end
        end
      elsif options.length == 2
        origins, targets = options.keys, options.values

        [0,1].each do |i|
          if origins[i].is_a?(String) && Parser.id(origins[i])
            origins[i] = lines[Parser.id(origins[i]) - 1].start_time
          elsif origins[i].is_a?(String) && Parser.timecode(origins[i])
            origins[i] = Parser.timecode(origins[i])
          end

          if targets[i].is_a?(String) && Parser.timecode(targets[i])
            targets[i] = Parser.timecode(targets[i])
          elsif targets[i].is_a?(String) && Parser.timespan(targets[i])
            targets[i] = origins[i] + Parser.timespan(targets[i])
          end
        end

        time_rescale_factor = (targets[1] - targets[0]) / (origins[1] - origins[0])
        time_rebase_shift = targets[0] - origins[0] * time_rescale_factor

        lines.each do |line|
          line.start_time = line.start_time * time_rescale_factor + time_rebase_shift
          line.end_time = line.end_time * time_rescale_factor + time_rebase_shift
        end
      end

      if lines.reject! { |line| line.end_time < 0 }
        lines.sort_by! { |line| line.sequence }
        lines.each_with_index do |line, index|
         line.sequence = index + 1
         line.start_time = 0 if line.start_time < 0
        end
      end
    end

    def to_s(time_str_function=:time_str)
      lines.map { |l| [l.sequence, (l.display_coordinates ? l.send(time_str_function) + l.display_coordinates : l.send(time_str_function)), l.text, ""] }.flatten.join("\n")
    end

    def to_webvtt
      header = <<eos
WEBVTT
X-TIMESTAMP-MAP=MPEGTS:0,LOCAL:00:00:00.000

eos
      header + to_s(:webvtt_time_str)
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
