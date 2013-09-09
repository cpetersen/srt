require 'srt'
require 'spec_helper'

describe SRT do

  describe SRT::Line do
    describe "#new" do
      let(:line) { SRT::Line.new }
      
      it "should create an empty subtitle" do
        line.should be_empty
      end      
    end

    describe "#time_str" do
      let(:line) { SRT::Line.new }

      before do
        line.start_time = 224.2
        line.end_time = 244.578
      end

      it "should produce timecodes that match the internal float values" do
        line.time_str.should eq("00:03:44,200 --> 00:04:04,578")
      end      
    end
  end

  describe SRT::File do

    describe ".parse_id" do
      it "should convert the id string (#[id]) to an int representing the sequence number" do
        SRT::File.parse_id("#317").should eq(317)
      end
    end

    describe ".parse_timecode" do
      it "should convert the SRT timecode format to a float representing seconds" do
        SRT::File.parse_timecode("01:03:44,200").should eq(3824.2)
      end
    end

    describe ".parse_timespan" do
      it "should convert a timespan string ([+|-][amount][h|m|s|ms]) to a float representing seconds" do
        SRT::File.parse_timespan("-3.5m").should eq(-210)
      end

      it "should convert a timespan string ([+|-][amount][h|m|s|ms]) to a float representing seconds" do
        SRT::File.parse_timespan("-1s").should eq(-1)
      end

      it "should convert a timespan string ([+|-][amount][h|m|s|ms]) to a float representing seconds" do
        SRT::File.parse_timespan("100ms").should eq(0.1)
      end      
    end

    describe ".parse_framerate" do
      it "should convert a framerate string ([number]fps) to a float representing seconds" do
        SRT::File.parse_framerate("23.976fps").should eq(23.976)
      end
    end    

    shared_examples_for "an SRT file" do
      context "when parsing a properly formatted BSG SRT file" do
        it "should return an SRT::File" do
          subject.class.should eq(SRT::File)
        end
        
        it "should have 600 lines" do
          subject.lines.size.should eq(600)
        end

        it "should have no errors" do
          subject.errors.should be_empty
        end

        it "should have the expected sequence number on the first subtitle" do
          subject.lines.first.sequence.should eq(1)
        end

        it "should have the expected timecodes on the first subtitle" do
          subject.lines.first.time_str.should eq("00:00:02,110 --> 00:00:04,578")
        end

        it "should have the expected text on the first subtitle" do
          subject.lines.first.text.should eq(["<i>(male narrator) Previously", "on Battlestar Galactica.</i>"])
        end

        it "should have the expected sequence number on the last subtitle" do
          subject.lines.last.sequence.should eq(600)
        end

        it "should have the expected timecodes on the last subtitle" do
          subject.lines.last.time_str.should eq("00:43:26,808 --> 00:43:28,139")
        end

        it "should have the expected text on the last subtitle" do
          subject.lines.last.text.should eq(["Thank you."])
        end
      end
    end

    describe ".parse with uncommon formats" do
      context "when parsing a spanish language WOTW SRT file with unknown encoding" do
        let(:file) { SRT::File.parse(File.open("./spec/wotw-dubious.srt")) }

        it "should parse" do
          file.class.should eq(SRT::File)
        end

        it "should have 1123 lines" do
          file.lines.size.should eq(1123)
        end

        it "should have no errors" do
          file.errors.should be_empty
        end
      end

      context "when parsing a dummy SRT file containing display coordinates" do
        let(:file) { SRT::File.parse(File.open("./spec/coordinates-dummy.srt")) }

        it "should return an SRT::File" do
          file.class.should eq(SRT::File)
        end
        
        it "should have 3 lines" do
          file.lines.size.should eq(3)
        end

        it "should have no errors" do
          file.errors.should be_empty
        end

        it "should have the expected display coordinates on the first subtitle" do
          file.lines.first.display_coordinates.should eq("X1:100 X2:600 Y1:1 Y2:4")
        end

        it "should have the expected display coordinates on the last subtitle" do 
          file.lines.last.display_coordinates.should eq("X1:1 X2:333 Y1:50 Y2:29")
        end
      end
    end

    describe SRT::File, "when initialized with a valid BSG SRT string" do
      subject { SRT::File.parse(File.read("./spec/bsg-s01e01.srt")) }
      it_should_behave_like "an SRT file"
    end

    describe SRT::File, "when initialized with a valid BSG SRT File" do
      subject { SRT::File.parse(File.open("./spec/bsg-s01e01.srt")) }
      it_should_behave_like "an SRT file"
    end

    describe "#append" do
      context "when calling it on the first (part1) of two seperate SRT files for Black Swan" do
        let(:part1) { SRT::File.parse(File.open("./spec/blackswan-part1.srt")) }
        let(:part2) { SRT::File.parse(File.open("./spec/blackswan-part2.srt")) }
      
        context "when passing { \"00:53:57,241\" => part2 }" do
          before { part1.append({ "00:53:57,241" => part2 }) }

          it "should have grown to 808 subtitles" do
            part1.lines.length.should eq(808)
          end

          it "should have appended subtitles starting with sequence number 448" do
            part1.lines[447].sequence.should eq(448)
          end         

          it "should have appended subtitles ending with sequence number 808" do
            part1.lines.last.sequence.should eq(808)
          end

          it "should have appended subtitles relatively from 00:53:57,241" do
            part1.lines[447].time_str.should eq("00:54:02,152 --> 00:54:04,204")
          end          
        end

        context "when passing { \"+7.241s\" => part2 }" do
          before { part1.append({ "+7.241s" => part2 }) }
          
          it "should have appended subtitles relatively from +7.241s after the previously last subtitle" do
            part1.lines[447].time_str.should eq("00:54:02,283 --> 00:54:04,335")
          end
        end
      end
    end

    describe "#split" do
      context "when calling it on a properly formatted BSG SRT file" do
        let(:file) { SRT::File.parse(File.open("./spec/bsg-s01e01.srt")) }
      
        context "when passing { :at => \"00:19:24,500\" }" do 
          let(:result) { file.split( :at => "00:19:24,500" ) }

          it "should return an array containing two SRT::File instances" do
            result.length.should eq(2)
            result[0].class.should eq(SRT::File)
            result[1].class.should eq(SRT::File)
          end

          it "should include a subtitle that overlaps a splitting point in the first file" do
            result[0].lines.last.text.should eq(["I'll see you guys in combat."])
          end

          it "should make an overlapping subtitle end at the splitting point in the first file" do
            result[0].lines.last.time_str.should eq("00:19:23,901 --> 00:19:24,500")
          end

          it "should include a subtitle that overlaps a splitting point in the second file as well" do
            result[1].lines.first.text.should eq(["I'll see you guys in combat."])
          end

          it "should make an overlapping subtitle remain at the beginning in the second file" do
            result[1].lines.first.time_str.should eq("00:00:00,000 --> 00:00:01,528")
          end

          it "should shift back all timecodes of the second file relative to the new file beginning" do
            result[1].lines[1].time_str.should eq("00:00:01,737 --> 00:00:03,466")
          end
        end

        context "when passing { :at => \"00:19:24,500\", :timeshift => false }" do
          let(:result) { file.split( :at => "00:19:24,500", :timeshift => false ) }

          it "should return an array containing two SRT::File instances" do
            result.length.should eq(2)
            result[0].class.should eq(SRT::File)
            result[1].class.should eq(SRT::File)
          end

          it "should include a subtitle that overlaps a splitting point in the first file" do
            result[0].lines.last.text.should eq(["I'll see you guys in combat."])
          end

          it "should not make an overlapping subtitle end at the splitting point in the first file" do
            result[0].lines.last.time_str.should eq("00:19:23,901 --> 00:19:26,028")
          end

          it "should include a subtitle that overlaps a splitting point in the second file as well" do
            result[1].lines.first.text.should eq(["I'll see you guys in combat."])
          end

          it "should not make an overlapping subtitle remain at the beginning in the second file" do
            result[1].lines.first.time_str.should eq("00:19:23,901 --> 00:19:26,028")
          end

          it "should not shift back timecodes of the second file relative to the new file beginning" do
            result[1].lines[1].time_str.should eq("00:19:26,237 --> 00:19:27,966")
          end
        end
      
        context "when passing { :at => [\"00:15:00,000\", \"00:30:00,000\"] }" do 
          let(:result) { file.split( :at => ["00:15:00,000", "00:30:00,000"] ) }

          it "should return an array containing three SRT::File instances" do
            result.length.should eq(3)
            result[0].class.should eq(SRT::File)
            result[1].class.should eq(SRT::File)
            result[2].class.should eq(SRT::File)
          end

          it "should let subtitles start at sequence number #1 in all three files" do
            result[0].lines.first.sequence.should eq(1)
            result[1].lines.first.sequence.should eq(1)
            result[2].lines.first.sequence.should eq(1)
          end

          it "should put 176 subtitles in the first file" do
            result[0].lines.length.should eq(176)
            result[0].lines.last.sequence.should eq(176)
          end

          it "should put 213 subtitles in the second file" do
            result[1].lines.length.should eq(213)
            result[1].lines.last.sequence.should eq(213)
          end

          it "should put 212 subtitles in the third file" do
            result[2].lines.length.should eq(212)
            result[2].lines.last.sequence.should eq(212)
          end         
        end

        context "when passing { :at => \"00:19:24,500\", :every => \"00:00:01,000\" }" do
          let(:result) { file.split( :at => "00:19:24,500", :every => "00:00:01,000" ) }

          it "should return an array containing two SRT::File instances, ignoring :every" do
            result.length.should eq(2)
            result[0].class.should eq(SRT::File)
            result[1].class.should eq(SRT::File)
          end
        end

        context "when passing { :every => \"00:05:00,000\" }" do
          let(:result) { file.split( :every => "00:05:00,000" ) }

          it "should return an array containing nine SRT::File instances" do
            result.length.should eq(9)
            (0...result.count).each do |n|
              result[n].class.should eq(SRT::File)
            end
          end
        end

        context "when passing { :at => \"00:19:24,500\", :renumber => false }" do
          let(:result) { file.split( :at => "00:19:24,500", :renumber => false ) }

          it "sequence for the last line of first part should be the sequence for the first line of second part" do
            result[0].lines.last.text.should == result[1].lines.first.text
            result[0].lines.last.sequence.should == result[1].lines.first.sequence
          end
        end

        context "when passing { :at => \"00:19:24,500\", :renumber => true }" do
          let(:result) { file.split( :at => "00:19:24,500", :renumber => true ) }

          it "first line of second part's number should be one" do
            result[1].lines.first.sequence.should == 1
          end

          it "sequence for the last line of first part should have different number than the sequence for the first line of second part" do
            result[0].lines.last.text.should == result[1].lines.first.text
            result[0].lines.last.sequence.should_not == result[1].lines.first.sequence
          end
        end

        context "when passing { :at => \"00:19:24,500\", :timeshift => false }" do
          let(:result) { file.split( :at => "00:19:24,500", :timeshift => false ) }

          it "time for last line of first part should be the time for first line of second part" do
            result[0].lines.last.text.should == result[1].lines.first.text
            result[0].lines.last.time_str.should == result[1].lines.first.time_str
          end
        end

        context "when passing { :at => \"00:19:24,500\", :timeshift => true }" do
          let(:result) { file.split( :at => "00:19:24,500", :timeshift => true ) }

          it "start_time of first line in second part should be 0" do
            result[1].lines.first.start_time.should == 0
          end

          it "time for last line of first part should not be the time for first line of second part" do
            result[0].lines.last.text.should == result[1].lines.first.text
            result[0].lines.last.time_str.should_not == result[1].lines.first.time_str
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
            file.lines[23].time_str.should eq("00:01:59,291 --> 00:02:00,815")
          end

          it "should have timecodes shifted forward by 2.5s for subtitle #43" do
            file.lines[42].time_str.should eq("00:03:46,164 --> 00:03:47,631")
          end
        end

        context "when passing { \"25fps\" => \"23.976fps\" }" do
          before { file.timeshift({ "25fps" => "23.976fps" }) }

          it "should have correctly scaled timecodes for subtitle #24" do
            file.lines[23].time_str.should eq("00:01:52,007 --> 00:01:53,469")
          end
          
          it "should have correctly scaled timecodes for subtitle #43" do
            file.lines[42].time_str.should eq("00:03:34,503 --> 00:03:35,910")
          end
        end

        context "when passing { \"#24\" => \"00:03:53,582\", \"#42\" => \"00:04:24,656\" }" do
          before { file.timeshift({ "#24" => "00:03:53,582", "#42" => "00:04:24,656" }) }

          it "should have shifted timecodes for subtitle #24" do
            file.lines[23].time_str.should eq("00:03:53,582 --> 00:03:54,042")
          end
          
          it "should have differently shifted timecodes for subtitle #43" do
            file.lines[41].time_str.should eq("00:04:24,656 --> 00:04:25,298")
          end
        end

        context "when passing { 180 => \"+1s\", 264 => \"+1.5s\" }" do
          before { file.timeshift({ 180 => "+1s", 264 => "+1.5s" }) }

          it "should have shifted by +1s at 180 seconds" do
            file.lines[23].time_str.should eq("00:01:57,415 --> 00:01:58,948")
          end
          
          it "should have shifted by +1.5s at 264 seconds" do
            file.lines[41].time_str.should eq("00:03:40,997 --> 00:03:43,136")
          end
        end        
      end

      context "when calling it on a spanish language WOTW SRT file with unknown encoding" do
        let(:file) { SRT::File.parse(File.open("./spec/wotw-dubious.srt")) }

        context "when passing { :all => \"-2.7m\" }" do
          before { file.timeshift({ :all => "-2.7m" }) }

          it "should have dumped 16 lines with now negative timecodes, leaving 1107" do
            file.lines.size.should eq(1107)
          end
        end

        context "when passing { \"00:03:25,430\" => \"00:00:44,200\", \"01:49:29,980\" => \"01:46:35,600\" }" do
          before { file.timeshift({ "00:03:25,430" => "00:00:44,200", "01:49:29,980" => "01:46:35,600" }) }

          it "should have dumped 16 lines with now negative timecodes, leaving 1107" do
            file.lines.size.should eq(1107)
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
            file.to_s.should eq(OUTPUT)
          end
        end
      end

      describe "#to_webvtt" do
        context "when calling it on a short SRT file" do
          let(:file) { SRT::File.parse(File.open("./spec/bsg-s01e01.srt")) }

          before { file.lines = file.lines[0..2] }

          it "should produce the exactly correct output" do
            OUTPUT_WEBVTT =<<END
WEBVTT
X-TIMESTAMP-MAP=MPEGTS:0,LOCAL:00:00:00.000

1
00:00:02.110 --> 00:00:04.578
<i>(male narrator) Previously
on Battlestar Galactica.</i>

2
00:00:05.313 --> 00:00:06.871
Now you're telling me
you're a machine.

3
00:00:07.014 --> 00:00:08.003
The robot.
END
            file.to_webvtt.should eq(OUTPUT_WEBVTT)
          end
        end
      end

    end
  end
end
