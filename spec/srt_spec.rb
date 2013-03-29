require 'srt'

describe SRT do
  context "A single line" do
    let(:line) { SRT::Line.new }
    it "should initially be empty" do
      line.should be_empty
    end

    it "should not be empty after inserting text" do
      line.text = ["This is a test"]
      line.should_not be_empty
    end

    it "should print a time string that corresponds to its internal time values" do
      line.start_time = 2.110
      line.end_time = 4.578
      line.time_str.should == "00:00:02,110 --> 00:00:04,578"
    end
  end

  context "This given, properly formatted BSG SRT file" do
    let(:file) { SRT::File.parse(File.open("./spec/bsg-s01e01.srt")) }

    it "should parse" do
      file.class.should == SRT::File
    end

    it "should have 600 lines" do
      file.lines.size.should == 600
    end

    it "should not have errors" do
      file.errors.should be_empty
    end

    it "should have the expected data on the first line" do
      file.lines.first.sequence.should == 1
      file.lines.first.time_str.should == "00:00:02,110 --> 00:00:04,578"
      file.lines.first.text.should == ["<i>(male narrator) Previously", "on Battlestar Galactica.</i>"]
    end
      
    it "should have the expected data on the last line" do
      file.lines.last.sequence.should == 600
      file.lines.last.time_str.should == "00:43:26,808 --> 00:43:28,139"
      file.lines.last.text.should == ["Thank you."]
    end

    it "should have constantly shifted time strings on all lines after timeshift { :all => \"+2.5s\" }" do
      file.timeshift({ :all => "+2.5s" })
      file.lines[23].time_str.should == "00:01:59,291 --> 00:02:00,815"
      file.lines[42].time_str.should == "00:03:46,164 --> 00:03:47,631"
    end

    it "should have progressively shifted time strings on all lines after timeshift { \"25fps\" => \"23.976fps\" }" do
      file.timeshift({ "25fps" => "23.976fps" })
      file.lines[23].time_str.should == "00:01:52,007 --> 00:01:53,469"
      file.lines[42].time_str.should == "00:03:34,503 --> 00:03:35,910"
    end    

    it "should have progressively shifted time strings on all lines after timeshift { 24 => \"00:03:53,582\", 43 => \"00:14:54,656\" }" do
      file.timeshift({ 24 => "00:03:53,582", 43 => "00:14:54,656" })
      file.lines[23].time_str.should == "00:03:53,582 --> 00:04:03,009"
      file.lines[42].time_str.should == "00:14:54,656 --> 00:15:03,730"
    end
  end

  context "A short SRT file" do
    let(:file) { 
      file = SRT::File.parse(File.open("./spec/bsg-s01e01.srt"))
      file.lines = file.lines[0..2]
      file
    }

    it "should have the proper to_s" do
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
      file.to_s.should == OUTPUT
    end
  end

  context "This given, technically dubious, spanish language WOTW SRT file" do
    let(:file) { SRT::File.parse(File.open("./spec/wotw-dubious.srt")) }

    it "should parse" do
      file.class.should == SRT::File
    end

    it "should have 1123 lines" do
      file.lines.size.should == 1123
    end

    it "should not have errors" do
      file.errors.should be_empty
    end
  end  

  context "This dummy SRT file containing display coordinates" do
    let(:file) { SRT::File.parse(File.open("./spec/coordinates-dummy.srt")) }

    it "should parse" do
      file.class.should == SRT::File
    end
    it "should have 3 lines" do
      file.lines.size.should == 3
    end

    it "should not have errors" do
      file.errors.should be_empty
    end    

    it "should have the expected display coordinates on the first line" do
      file.lines.first.display_coordinates.should == "X1:100 X2:600 Y1:1 Y2:4"
    end

    it "should have the expected display coordinates on the last line" do
      file.lines.last.display_coordinates.should == "X1:1 X2:333 Y1:50 Y2:29"
    end  
  end
end