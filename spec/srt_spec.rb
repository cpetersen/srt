require 'srt'

describe SRT do
  context "A single line" do
    let(:line) { SRT::Line.new }
    it "should be empty" do
      line.should be_empty
    end

    it "should not be empty" do
      line.text = "This is a test"
      line.should_not be_empty
    end

    it "should have the correct time string" do
      line.start_time = 2.110
      line.end_time = 4.578
      line.time_str.should == "00:00:02,110 --> 00:00:04,578"
    end

    # it "should have the correct time values after timeshifting" do
    #   line.start_time = DateTime.strptime("00:00:02,110", "%H:%M:%S,%L")
    #   line.end_time = DateTime.strptime("00:00:04,578", "%H:%M:%S,%L")
    #   line.shift(2.5)
    #   line.time_str.should == "00:00:02,110 --> 00:00:04,578"        
    # end
  end

  context "A properly formatted SRT file" do
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

    context "the first line" do
      let(:line) { file.lines.first }

      it "should have the proper text" do
        line.text.should == ["<i>(male narrator) Previously", "on Battlestar Galactica.</i>"]
      end

      it "should have the proper sequence" do
        line.sequence.should == 1
      end

      it "should have the proper time string" do
        line.time_str.should == "00:00:02,110 --> 00:00:04,578"
      end
    end

    context "the last line" do
      let(:line) { file.lines.last }
      
      it "should have the proper text" do
        line.text.should == ["Thank you."]
      end

      it "should have the proper sequence" do
        line.sequence.should == 600
      end

      it "should have the proper time string" do
        line.time_str.should == "00:43:26,808 --> 00:43:28,139"
      end
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
end
