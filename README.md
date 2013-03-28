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

`timeshift` offers multiple ways to fix subtitle synchronization issues;  

Pass it a hash of the form `:all => "[+/-][amount][h|m|s|mil]"` for a constant shift:

```ruby
  # Shift all subtitles so they show up ...
  file.timeshift({ :all => "-2.5s" }) # 2.5 seconds earlier
  file.timeshift({ :all => "1.5m" }) # 1.5 minutes later  
  file.timeshift({ :all => "+700mil" }) # 700 milliseconds later    
```
Pass it a hash of the form `"[old]fps" => "[new]fps"` for a framerate based shift:

```ruby
  file.timeshift({ "25fps" => "23.976fps" }) # scale timecodes from 25fps to 23.976fps
```
Pass it a hash in any of the following forms for a linear progressive shift , e.g. to account for time-drift caused by subtitles that were created for a video version with a different framerate:

```ruby
  file.timeshift({ 12 => "+10s", 569 => "+2.34m" })
  file.timeshift({ 23 => "00:02:12,400", 843 => "01:38:06,000" }) 
  file.timeshift({ "00:01:10,000" => "55s", "01:33:07,200" => "2.3m" })
  file.timeshift({ "00:01:10,000" => "00:02:12,400", "01:33:07,200" => "01:38:06,000" })
  file.timeshift({ 57 => "00:02:12,400", "01:33:07,200" => "+13s" })
```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
