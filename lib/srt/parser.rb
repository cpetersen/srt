module SRT
  class Parser
    class << self
      def framerate(framerate_string)
        mres = framerate_string.match(/(?<fps>\d+((\.)?\d+))(fps)/)
        mres ? mres["fps"].to_f : nil
      end

      def id(id_string)
        mres = id_string.match(/#(?<id>\d+)/)
          mres ? mres["id"].to_i : nil
      end

      def timecode(timecode_string)
        mres = timecode_string.match(/(?<h>\d+):(?<m>\d+):(?<s>\d+),(?<ms>\d+)/)
        mres ? "#{mres["h"].to_i * 3600 + mres["m"].to_i * 60 + mres["s"].to_i}.#{mres["ms"]}".to_f : nil
      end

      def timespan(timespan_string)
        factors = {
          "ms" => 0.001,
          "s" => 1,
          "m" => 60,
          "h" => 3600
        }
        mres = timespan_string.match(/(?<amount>(\+|-)?\d+((\.)?\d+)?)(?<unit>ms|s|m|h)/)
        mres ? mres["amount"].to_f * factors[mres["unit"]] : nil
      end
    end
  end
end
