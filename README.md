# SRT [![Build Status](https://travis-ci.org/cpetersen/srt.png?branch=master)](https://travis-ci.org/cpetersen/srt)

SRT stands for SubRip text file format, which is a file for storing subtitles. This is a Ruby library for manipulating SRT files. 

## Installation

Add this line to your application's Gemfile:

    gem 'srt'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install srt

## Usage

You can parse an SRT file with the following code:

```ruby
  file = SRT::File.parse(File.new("MY_SRT_FILENAME.srt"))
  file.lines.each do |line|
    puts line.text.join(" ")
  end
```

`timeshift` offers multiple ways to fix subtitle synchronization issues

# timeshift(instructions)
#
# constantly shift all subtitles
# e.g. { :all => "-3.4s" }
#      { :all => "1.5m" }
#      { :all => "+700mil" }
#
# framerate conversion
# e.g. { "25fps" => "23.99999fps" }
# note: this implements a naive approach of what framerate conversion does or should do;
#       it probably won't statisfy what video professionals expect - but it's a start :)    
#
# linear progressive timeshift
# e.g. { 12 => "+10s", 569 => "+2.34m" }
#      { 23 => "00:02:12,400", 843 => "01:38:06,000" }
#      { "00:01:10,000" => "55s", "01:33:07,200" => "2.3m" } 
#      { "00:01:10,000" => "00:02:12,400", "01:33:07,200" => "01:38:06,000" }
#      { 57 => "00:02:12,400", "01:33:07,200" => "+13s" }

```ruby
  file.timeshift({ :all => "-2.5s" }) # resynchronize subtitles so they show up 2.5 seconds earlier 
```

`linear_progressive_timeshift` allows progressive timeshifting, e.g. to account for time-drift  
caused by subtitles that were created for a video version with a different framerate:

```ruby
  file.linear_progressive_timeshift(60, 70, 2700, 2760) 
 ```

This applies a timeshift of 10 seconds at minute #1 (60 => 70),  
then progressively more towards a 60 second shift by minute #45 (2700 => 2760)


## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
