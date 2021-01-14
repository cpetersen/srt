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

  describe "#time_str (second time)" do
    let(:line) { SRT::Line.new }

    before do
      line.start_time = 36915.85455630479
      line.end_time = 36915.999869858395
    end

    it "should produce timecodes that match the internal float values" do
      expect(line.time_str).to eq("10:15:15,855 --> 10:15:16,000")
    end
  end

  describe "#to_s" do
    let(:line) { SRT::Line.new }

    before do
      line.sequence = "1"
      line.start_time = 224.2
      line.end_time = 244.578
    end

    context "with empty content" do
      it "creates a valid empty node" do
        expect(line.to_s).to eq("1\n00:03:44,200 --> 00:04:04,578\n\n")
      end
    end
  end
end
