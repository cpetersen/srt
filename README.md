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

'timeshift' let's you constantly shift all subtitle timecodes ...

```ruby
  file = SRT::File.parse(File.new("MY_SRT_FILENAME.srt"))
  file.timeshift(-2.5) # resynchronize subtitles so they show up 2.5 seconds earlier 
```

... 'linear_progressive_timeshift' allows progressive timeshifting, e.g. to account for time-drift caused by subtitles that were created for a video version with a different framerate

```ruby
  # apply a timeshift of 10s at minute #1 (60 => 70)
  # then progressively more towards a 60s shift by minute #45 (2700 => 2760)
  file.linear_progressive_timeshift(60, 70, 2700, 2760) 
 ```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
