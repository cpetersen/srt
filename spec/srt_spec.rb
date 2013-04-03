require 'srt'

describe SRT do

  describe SRT::Line do
    describe "#new" do
      let(:line) { SRT::Line.new }
      
      it "should create an empty subtitle" do
        expect(line).to be_empty
      end      
    end

    describe "#time_str" do
      let(:line) { SRT::Line.new }

      before do
        line.start_time = 224.2
        line.end_time = 244.578
      end

      it "should produce timecodes that match the internal float values" do
        expect(line.time_str).to eq("00:03:44,200 --> 00:04:04,578")
      end      
    end
  end

  describe SRT::File do
    describe ".parse_timecode" do
      it "should convert the SRT timecode format to a float representing seconds" do
        expect(SRT::File.parse_timecode("01:03:44,200")).to eq(3824.2)
      end
    end

    describe ".parse_timespan" do
      it "should convert a timespan string ([+|-][amount][h|m|s|mil]) to a float representing seconds" do
        expect(SRT::File.parse_timespan("-3.5m")).to eq(-210)
      end
    end

    describe ".parse_framerate" do
      it "should convert a framerate string ([number]fps) to a float representing seconds" do
        expect(SRT::File.parse_framerate("23.976fps")).to eq(23.976)
      end
    end    

    describe ".parse" do
      context "when parsing a properly formatted BSG SRT file" do
        let(:file) { SRT::File.parse(File.open("./spec/bsg-s01e01.srt")) }

        it "should return an SRT::File" do
          expect(file.class).to eq(SRT::File)
        end
        
        it "should have 600 lines" do
          expect(file.lines.size).to eq(600)
        end

        it "should have no errors" do
          expect(file.errors).to be_empty
        end

        it "should have the expected sequence number on the first subtitle" do
          expect(file.lines.first.sequence).to eq(1)
        end

        it "should have the expected timecodes on the first subtitle" do
          expect(file.lines.first.time_str).to eq("00:00:02,110 --> 00:00:04,578")
        end

        it "should have the expected text on the first subtitle" do
          expect(file.lines.first.text).to eq(["<i>(male narrator) Previously", "on Battlestar Galactica.</i>"])
        end

        it "should have the expected sequence number on the last subtitle" do
          expect(file.lines.last.sequence).to eq(600)
        end

        it "should have the expected timecodes on the last subtitle" do
          expect(file.lines.last.time_str).to eq("00:43:26,808 --> 00:43:28,139")
        end

        it "should have the expected text on the last subtitle" do
          expect(file.lines.last.text).to eq(["Thank you."])
        end
      end

      context "when parsing a spanish language WOTW SRT file with unknown encoding" do
        let(:file) { SRT::File.parse(File.open("./spec/wotw-dubious.srt")) }

        # not sure actually

        # it "should parse" do
        #   expect(file.class).to eq(SRT::File)
        # end

        # it "should have 1123 lines" do
        #   expect(file.lines.size).to eq(1123)
        # end

        # it "should have no errors" do
        #   expect(file.errors).to be_empty
        # end
      end      

      context "when parsing a dummy SRT file containing display coordinates" do
        let(:file) { SRT::File.parse(File.open("./spec/coordinates-dummy.srt")) }

        it "should return an SRT::File" do
          expect(file.class).to eq(SRT::File)
        end
        
        it "should have 3 lines" do
          expect(file.lines.size).to eq(3)
        end

        it "should have no errors" do
          expect(file.errors).to be_empty
        end

        it "should have the expected display coordinates on the first subtitle" do
          expect(file.lines.first.display_coordinates).to eq("X1:100 X2:600 Y1:1 Y2:4")
        end

        it "should have the expected display coordinates on the last subtitle" do 
          expect(file.lines.last.display_coordinates).to eq("X1:1 X2:333 Y1:50 Y2:29")
        end
      end
    end

    describe "#split" do
      context "when calling it on a properly formatted BSG SRT file" do
        let(:file) { SRT::File.parse(File.open("./spec/bsg-s01e01.srt")) }
      
        context "when passing { :at => \"00:19:24,500\" }" do 
          let(:result) { file.split( :at => "00:19:24,500" ) }

          it "should return an array containing two SRT::File instances" do
            expect(result.length).to eq(2)
            expect(result[0].class).to eq(SRT::File)
            expect(result[1].class).to eq(SRT::File)
          end

          it "should include a subtitle that overlaps a splitting point in the first file" do
            expect(result[0].lines.last.text).to eq(["I'll see you guys in combat."])
          end

          it "should make an overlapping subtitle end at the splitting point in the first file" do
            expect(result[0].lines.last.time_str).to eq("00:19:23,901 --> 00:19:24,500")
          end

          it "should include a subtitle that overlaps a splitting point in the second file as well" do
            expect(result[1].lines.first.text).to eq(["I'll see you guys in combat."])
          end

          it "should make an overlapping subtitle remain at the beginning in the second file" do
            expect(result[1].lines.first.time_str).to eq("00:00:00,000 --> 00:00:01,528")
          end

          it "should shift back all timecodes of the second file relative to the new file beginning" do
            expect(result[1].lines[1].time_str).to eq("00:00:01,737 --> 00:00:03,466")
          end
        end
      
        context "when passing { :at => [\"00:15:00,000\", \"00:30:00,000\"] }" do 
          let(:result) { file.split( :at => ["00:15:00,000", "00:30:00,000"] ) }

          it "should return an array containing three SRT::File instances" do
            expect(result.length).to eq(3)
            expect(result[0].class).to eq(SRT::File)
            expect(result[1].class).to eq(SRT::File)
            expect(result[2].class).to eq(SRT::File)
          end

          it "should let subtitles start at sequence number #1 in all three files" do
            expect(result[0].lines.first.sequence).to eq(1)
            expect(result[1].lines.first.sequence).to eq(1)
            expect(result[2].lines.first.sequence).to eq(1)
          end

          it "should put 176 subtitles in the first file" do
            expect(result[0].lines.length).to eq(176)
            expect(result[0].lines.last.sequence).to eq(176)
          end

          it "should put 213 subtitles in the second file" do
            expect(result[1].lines.length).to eq(213)
            expect(result[1].lines.last.sequence).to eq(213)
          end

          it "should put 212 subtitles in the third file" do
            expect(result[2].lines.length).to eq(212)
            expect(result[2].lines.last.sequence).to eq(212)
          end         
        end
      end
    end

    describe "#timeshift" do
      context "when calling it on a properly formatted BSG SRT file" do
        let(:file) { SRT::File.parse(File.open("./spec/bsg-s01e01.srt")) }

        context "when passing { :all => \"+2.5s\" }" do
          before { file.timeshift({ :all => "+2.5s" }) }

          it "should have timecodes shifted forward by 2.5s for subtitle #24" do
            expect(file.lines[23].time_str).to eq("00:01:59,291 --> 00:02:00,815")
          end

          it "should have timecodes shifted forward by 2.5s for subtitle #43" do
            expect(file.lines[42].time_str).to eq("00:03:46,164 --> 00:03:47,631")
          end
        end

        context "when passing { \"25fps\" => \"23.976fps\" }" do
          before { file.timeshift({ "25fps" => "23.976fps" }) }

          it "should have correctly scaled timecodes for subtitle #24" do
            expect(file.lines[23].time_str).to eq("00:01:52,007 --> 00:01:53,469")
          end
          
          it "should have correctly scaled timecodes for subtitle #43" do
            expect(file.lines[42].time_str).to eq("00:03:34,503 --> 00:03:35,910")
          end
        end

        context "when passing { 24 => \"00:03:53,582\", 43 => \"00:14:54,656\" }" do
          before { file.timeshift({ 24 => "00:03:53,582", 43 => "00:14:54,656" }) }

          it "should have shifted timecodes for subtitle #24" do
            expect(file.lines[23].time_str).to eq("00:03:53,582 --> 00:04:03,009")
          end
          
          it "should have differently shifted timecodes for subtitle #43" do
            expect(file.lines[42].time_str).to eq("00:14:54,656 --> 00:15:03,730")
          end
        end
      end

      describe "#to_s" do
        context "when calling it on a short SRT file" do
          let(:file) { SRT::File.parse(File.open("./spec/bsg-s01e01.srt")) }
          
          before { file.lines = file.lines[0..2] }

          it "should produce the exactly correct output" do
            OUTPUT =<<END
1
00:00:02,110 --> 00:00:04,578
<i>(male narrator) Previously
on Battlestar Galactica.</i>

2
00:00:05,313 --> 00:00:06,871
Now you're telling me
you're a machine.

3
00:00:07,014 --> 00:00:08,003
The robot.
END
            expect(file.to_s).to eq(OUTPUT)
          end
        end
      end
    end
  end
end