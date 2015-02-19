require 'spec_helper'
require 'srt'

describe SRT::File do
  describe '#parse' do
    context "parsing with debug true" do
      it "should be verbose when failing" do
        expect($stderr).to receive(:puts).once
        expect(SRT::File.parse(File.open("./spec/fixtures/invalid.srt"), debug: true).errors).not_to be_empty
      end
    end
    context "parsing with debug false" do
      it "should raise exception silently" do
        expect($stderr).not_to receive(:puts)
        expect(SRT::File.parse(File.open("./spec/fixtures/invalid.srt")).errors).not_to be_empty
      end
    end
  end

  shared_examples_for "an SRT file" do
    context "when parsing a properly formatted BSG SRT file" do
      it "should return an SRT::File" do
        expect(subject.class).to eq(SRT::File)
      end

      it "should have 600 lines" do
        expect(subject.lines.size).to eq(600)
      end

      it "should have no errors" do
        expect(subject.errors).to be_empty
      end

      it "should have the expected sequence number on the first subtitle" do
        expect(subject.lines.first.sequence).to eq(1)
      end

      it "should have the expected timecodes on the first subtitle" do
        expect(subject.lines.first.time_str).to eq("00:00:02,110 --> 00:00:04,578")
      end

      it "should have the expected text on the first subtitle" do
        expect(subject.lines.first.text).to eq(["<i>(male narrator) Previously", "on Battlestar Galactica.</i>"])
      end

      it "should have the expected sequence number on the last subtitle" do
        expect(subject.lines.last.sequence).to eq(600)
      end

      it "should have the expected timecodes on the last subtitle" do
        expect(subject.lines.last.time_str).to eq("00:43:26,808 --> 00:43:28,139")
      end

      it "should have the expected text on the last subtitle" do
        expect(subject.lines.last.text).to eq(["Thank you."])
      end
    end
  end

  describe ".parse with uncommon formats" do
    context "when parsing a spanish language WOTW SRT file with unknown encoding" do
      let(:file) { SRT::File.parse(File.open("./spec/fixtures/wotw-dubious.srt")) }

      it "should parse" do
        expect(file.class).to eq(SRT::File)
      end

      it "should have 1123 lines" do
        expect(file.lines.size).to eq(1123)
      end

      it "should have no errors" do
        expect(file.errors).to be_empty
      end
    end

    context "when parsing a dummy SRT file containing display coordinates" do
      let(:file) { SRT::File.parse(File.open("./spec/fixtures/coordinates-dummy.srt")) }

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

  describe SRT::File, "when initialized with a valid BSG SRT string" do
    subject { SRT::File.parse(File.read("./spec/fixtures/bsg-s01e01.srt")) }
    it_should_behave_like "an SRT file"
  end

  describe SRT::File, "when initialized with a valid BSG SRT File" do
    subject { SRT::File.parse(File.open("./spec/fixtures/bsg-s01e01.srt")) }
    it_should_behave_like "an SRT file"
  end

  describe "#append" do
    context "when calling it on the first (part1) of two seperate SRT files for Black Swan" do
      let(:part1) { SRT::File.parse(File.open("./spec/fixtures/blackswan-part1.srt")) }
      let(:part2) { SRT::File.parse(File.open("./spec/fixtures/blackswan-part2.srt")) }

      context "when passing { \"00:53:57,241\" => part2 }" do
        before { part1.append({ "00:53:57,241" => part2 }) }

        it "should have grown to 808 subtitles" do
          expect(part1.lines.length).to eq(808)
        end

        it "should have appended subtitles starting with sequence number 448" do
          expect(part1.lines[447].sequence).to eq(448)
        end

        it "should have appended subtitles ending with sequence number 808" do
          expect(part1.lines.last.sequence).to eq(808)
        end

        it "should have appended subtitles relatively from 00:53:57,241" do
          expect(part1.lines[447].time_str).to eq("00:54:02,152 --> 00:54:04,204")
        end
      end

      context "when passing { \"+7.241s\" => part2 }" do
        before { part1.append({ "+7.241s" => part2 }) }

        it "should have appended subtitles relatively from +7.241s after the previously last subtitle" do
          expect(part1.lines[447].time_str).to eq("00:54:02,283 --> 00:54:04,335")
        end
      end
    end
  end

  describe "#split" do
    context "when calling it on a properly formatted BSG SRT file" do
      let(:file) { SRT::File.parse(File.open("./spec/fixtures/bsg-s01e01.srt")) }

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

      context "when passing { :at => \"00:19:24,500\", :timeshift => false }" do
        let(:result) { file.split( :at => "00:19:24,500", :timeshift => false ) }

        it "should return an array containing two SRT::File instances" do
          expect(result.length).to eq(2)
          expect(result[0].class).to eq(SRT::File)
          expect(result[1].class).to eq(SRT::File)
        end

        it "should include a subtitle that overlaps a splitting point in the first file" do
          expect(result[0].lines.last.text).to eq(["I'll see you guys in combat."])
        end

        it "should not make an overlapping subtitle end at the splitting point in the first file" do
          expect(result[0].lines.last.time_str).to eq("00:19:23,901 --> 00:19:26,028")
        end

        it "should include a subtitle that overlaps a splitting point in the second file as well" do
          expect(result[1].lines.first.text).to eq(["I'll see you guys in combat."])
        end

        it "should not make an overlapping subtitle remain at the beginning in the second file" do
          expect(result[1].lines.first.time_str).to eq("00:19:23,901 --> 00:19:26,028")
        end

        it "should not shift back timecodes of the second file relative to the new file beginning" do
          expect(result[1].lines[1].time_str).to eq("00:19:26,237 --> 00:19:27,966")
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

      context "when passing { :at => \"00:19:24,500\", :every => \"00:00:01,000\" }" do
        let(:result) { file.split( :at => "00:19:24,500", :every => "00:00:01,000" ) }

        it "should return an array containing two SRT::File instances, ignoring :every" do
          expect(result.length).to eq(2)
          expect(result[0].class).to eq(SRT::File)
          expect(result[1].class).to eq(SRT::File)
        end
      end

      context "when passing { :every => \"00:05:00,000\" }" do
        let(:result) { file.split( :every => "00:05:00,000" ) }

        it "should return an array containing nine SRT::File instances" do
          expect(result.length).to eq(9)
          (0...result.count).each do |n|
            expect(result[n].class).to eq(SRT::File)
          end
        end
      end

      context "when passing { :at => \"00:19:24,500\", :renumber => false }" do
        let(:result) { file.split( :at => "00:19:24,500", :renumber => false ) }

        it "sequence for the last line of first part should be the sequence for the first line of second part" do
          expect(result[0].lines.last.text).to eq(result[1].lines.first.text)
          expect(result[0].lines.last.sequence).to eq(result[1].lines.first.sequence)
        end
      end

      context "when passing { :at => \"00:19:24,500\", :renumber => true }" do
        let(:result) { file.split( :at => "00:19:24,500", :renumber => true ) }

        it "first line of second part's number should be one" do
          expect(result[1].lines.first.sequence).to eq(1)
        end

        it "sequence for the last line of first part should have different number than the sequence for the first line of second part" do
          expect(result[0].lines.last.text).to eq(result[1].lines.first.text)
          expect(result[0].lines.last.sequence).not_to eq(result[1].lines.first.sequence)
        end
      end

      context "when passing { :at => \"00:19:24,500\", :timeshift => false }" do
        let(:result) { file.split( :at => "00:19:24,500", :timeshift => false ) }

        it "time for last line of first part should be the time for first line of second part" do
          expect(result[0].lines.last.text).to eq(result[1].lines.first.text)
          expect(result[0].lines.last.time_str).to eq(result[1].lines.first.time_str)
        end
      end

      context "when passing { :at => \"00:19:24,500\", :timeshift => true }" do
        let(:result) { file.split( :at => "00:19:24,500", :timeshift => true ) }

        it "start_time of first line in second part should be 0" do
          expect(result[1].lines.first.start_time).to eq(0)
        end

        it "time for last line of first part should not be the time for first line of second part" do
          expect(result[0].lines.last.text).to eq(result[1].lines.first.text)
          expect(result[0].lines.last.time_str).not_to eq(result[1].lines.first.time_str)
        end
      end
    end
  end

  describe "#timeshift" do
    context "when calling it on a properly formatted BSG SRT file" do
      let(:file) { SRT::File.parse(File.open("./spec/fixtures/bsg-s01e01.srt")) }

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

      context "when passing { \"#24\" => \"00:03:53,582\", \"#42\" => \"00:04:24,656\" }" do
        before { file.timeshift({ "#24" => "00:03:53,582", "#42" => "00:04:24,656" }) }

        it "should have shifted timecodes for subtitle #24" do
          expect(file.lines[23].time_str).to eq("00:03:53,582 --> 00:03:54,042")
        end

        it "should have differently shifted timecodes for subtitle #43" do
          expect(file.lines[41].time_str).to eq("00:04:24,656 --> 00:04:25,298")
        end
      end

      context "when passing { 180 => \"+1s\", 264 => \"+1.5s\" }" do
        before { file.timeshift({ 180 => "+1s", 264 => "+1.5s" }) }

        it "should have shifted by +1s at 180 seconds" do
          expect(file.lines[23].time_str).to eq("00:01:57,415 --> 00:01:58,948")
        end

        it "should have shifted by +1.5s at 264 seconds" do
          expect(file.lines[41].time_str).to eq("00:03:40,997 --> 00:03:43,136")
        end
      end
    end

    context "when calling it on a spanish language WOTW SRT file with unknown encoding" do
      let(:file) { SRT::File.parse(File.open("./spec/fixtures/wotw-dubious.srt")) }

      context "when passing { :all => \"-2.7m\" }" do
        before { file.timeshift({ :all => "-2.7m" }) }

        it "should have dumped 16 lines with now negative timecodes, leaving 1107" do
          expect(file.lines.size).to eq(1107)
        end
      end

      context "when passing { \"00:03:25,430\" => \"00:00:44,200\", \"01:49:29,980\" => \"01:46:35,600\" }" do
        before { file.timeshift({ "00:03:25,430" => "00:00:44,200", "01:49:29,980" => "01:46:35,600" }) }

        it "should have dumped 16 lines with now negative timecodes, leaving 1107" do
          expect(file.lines.size).to eq(1107)
        end
      end
    end

    describe "#to_s" do
      context "when calling it on a short SRT file" do
        let(:file) { SRT::File.parse(File.open("./spec/fixtures/bsg-s01e01.srt")) }

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

    describe "#to_webvtt" do
      context "when calling it on a short SRT file" do
        let(:file) { SRT::File.parse(File.open("./spec/fixtures/bsg-s01e01.srt")) }

        before { file.lines = file.lines[0..2] }

        it "should produce the exactly correct output" do
          OUTPUT_WEBVTT =<<END
WEBVTT
X-TIMESTAMP-MAP=MPEGTS:900000,LOCAL:00:00:00.000

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
          expect(file.to_webvtt).to eq(OUTPUT_WEBVTT)
        end
      end
    end
  end
end
