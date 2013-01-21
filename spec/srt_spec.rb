require 'srt'

describe SRT do
  context "A single line" do
    it "should be empty" do
      line = SRT::Line.new
      line.should be_empty
    end

    it "should not be empty" do
      line = SRT::Line.new(:text => "This is a test")
      line.should_not be_empty
    end

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

      it "should have the proper start time" do
        line.start_time.strftime("%H:%M:%S,%L").should == "00:00:02,110"
      end

      it "should have the proper end time" do
        line.end_time.strftime("%H:%M:%S,%L").should == "00:00:04,578"
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

      it "should have the proper start time" do
        line.start_time.strftime("%H:%M:%S,%L").should == "00:43:26,808"
      end

      it "should have the proper end time" do
        line.end_time.strftime("%H:%M:%S,%L").should == "00:43:28,139"
      end
    end
  end
end
