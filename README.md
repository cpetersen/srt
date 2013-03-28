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

#### Timeshifting

The method `timeshift` takes a hash and supports three different modes of timecode processing:

**Constant timeshift** 

```ruby
  file.timeshift( :all => "-2.5s" ) # Shift all subtitles so they show up 2.5 seconds earlier    
```

Simply pass a hash of the form `:all => "[+|-][amount][h|m|s|mil]"`  
Other example options, e.g.: `:all => "+700mil"`, `:all => "1.34m"`, `:all => "0.15h"`

 **Progressive timeshift**

```ruby
  file.timeshift({ 1 => "00:02:12,000", 843 => "01:38:06,000" }) # Correct drifting-out-of-sync
```

This example call would shift the **first subtitle** to `00:02:12`, the **last subtitle** (assuming here that `#843` is the last one in your file!) to `01:38:06` and all the ones before, after, and in between those two reference points seamlessly to their relatively earlier or later begin times.

To make this work pass two `original timecode/id => target timecode` pairs where each takes any of these 4 forms: 

* `[id] => "[hh]:[mm]:[ss],[mil]"`
* `[id] => "[+/-][amount][h|m|s|mil]"`
* `"[hh]:[mm]:[ss],[mil]" => "[hh]:[mm]:[ss],[mil]"`
* `"[hh]:[mm]:[ss],[mil]" => "[+/-][amount][h|m|s|mil]"`

Another full example: `{ "00:00:51,400" => "+13s", "01:12:44,320" => "+2.436m" }`

This method can be used to fix subtitles that are *at different times differently out of sync*,
and comes in handy especially if you have no idea what framerate your video or the video for which your subtitles
were created for is using - you just need find two matching reference points in your video and subtitles.

**Framerate-based timeshift**

```ruby
  file.timeshift({ "25fps" => "23.976fps" }) # Scale timecodes from 25fps to 23.976fps
```

For a framerate-based timeshift pass a hash of the form `"[old]fps" => "[new]fps"`

This is usually only useful if you have some background information about the designated framerates of your video and subtitles.

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
