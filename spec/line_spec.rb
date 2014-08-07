require 'spec_helper'
require 'srt'

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
