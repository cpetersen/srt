# SRT 
[![Build Status](https://travis-ci.org/cpetersen/srt.png?branch=master)](https://travis-ci.org/cpetersen/srt)
[![Code Climate](https://codeclimate.com/github/cpetersen/srt.png)](https://codeclimate.com/github/cpetersen/srt)
[![Coverage Status](https://coveralls.io/repos/cpetersen/srt/badge.png?branch=master)](https://coveralls.io/r/cpetersen/srt?branch=master)
[![Gem Version](https://badge.fury.io/rb/srt.png)](http://badge.fury.io/rb/srt)

SRT stands for SubRip text file format, which is a file for storing subtitles; This is a Ruby library for manipulating SRT files.
Current functionality includes **parsing**, **appending**, **splitting** and **timeshifting** (constant, progressive and framerate-based).

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

Each line exposes the following methods/members:
* `sequence` The incrementing subtitle ID (starts at 1)
* `text` An **Array** holding one or multiple lines of text.
* `start_time` The subtitle start timecode in seconds as a float
* `end_time` The subtitle end timecode in seconds as a float
* `time_str` Returns a timecode string of the form `"00:53:35,558 --> 00:53:36,556"`
* `display_coordinates` Optional display coordinates of the form `"X1:100 X2:600 Y1:100 Y2:400"`

#### Appending

```ruby
  part2 = SRT::File.parse(File.new("PART2_FILENAME.srt"))
  file.append( "00:53:57,000" => part2 ) # Append subtitles from part2 starting at 00:53:57
```

The method `append` can be used to merge two subtitle files into one (e.g. two parts from a 2-cd video).
Pass a hash with the key being either the *end timecode of the corresponding video of the subtitle being appended to*
or the *timespan between the last subtitle and the end of that video* and the value being another `SRT::File`.
The timecodes of the appended subtitles are shifted so they start at the right point in your merged video as well.

Example options for the timespan variant: `{ "+3.56s" => part2 }`

#### Splitting

```ruby
  parts = file.split( :at => "01:09:24,000" ) # Split the file in two at 01:09:24
```

The method `split` splits your subtitles at one (or more) points and returns an array of two (or more) instances of `SRT::File`.
By default, the timecodes of the split parts are relatively shifted towards their beginnings (to line up with correspondingly split multi-part video);
By additionally passing `:timeshift => false` you can prevent that behaviour and retain the original timecodes for each split part.

Pass  the option `:renumber => false` to prevent the line sequence number from being reset for a segment.

```ruby
  parts = file.split( :at => "01:09:24,000", :renumber => false ) # Split the file in two at 01:09:24 but do not reset the sequence number on the second part
```

Example options for a multi-split: `{ :at => ["00:19:24,500", "01:32:09,120", ...] }`


Optionally, for multi-splitting, you can pass a ":every" option to split the subtitles at a fixed interval.

```ruby
  parts = file.split( :every => "00:01:00,000" ) # Split the file every 1 minute
```
Note that the options :at and :every are mutually exclusive, and :at takes precedence.

#### Timeshifting

The method `timeshift` takes a hash and supports three different modes of timecode processing:

**Constant timeshift**

```ruby
  file.timeshift( :all => "-2.5s" ) # Shift all subtitles so they show up 2.5 seconds earlier
```

Simply pass a hash of the form `:all => "[+|-][amount][h|m|s|ms]"`
Other example options, e.g.: `:all => "+1.34m"`, `:all => "0.15h"`, `:all => "90ms"`

 **Progressive timeshift**

```ruby
  file.timeshift({ "#1" => "00:02:12,000", "#843" => "01:38:06,000" }) # Correct drifting-out-of-sync
```

This example call would shift the **first subtitle** to `00:02:12`, the **last subtitle** (assuming here that `#843` is the last one in your file) to `01:38:06`, and all the ones before, after, and in between those two reference points seamlessly to their own resulting earlier or later begin times.

To make this work pass two `origin timecode => target timecode` pairs, where the *origin timecodes* can be supplied as:

* `float` providing the raw timecode in *seconds*, e.g.:  `195.65`
* `"[hh]:[mm]:[ss],[ms]"` string, which is a timecode in SRT notation, e.g.: `"00:02:12,000"`
* `"#[id]"` string, which references the timecode of the subtitle with the supplied id, e.g.:  `"#317"`

... and the *target timecodes* can be supplied as:

* `float` providing the raw timecode in *seconds*, e.g.:  `3211.3`
* `"[hh]:[mm]:[ss],[ms]"` string, which is a timecode in SRT notation, e.g.: `"01:01:03,300"`
* `"[+/-][amount][h|m|s|ms]"` string, describing the amount by which to shift the origin timecode, e.g.: `"+1.5s"`

So for example: `{ "00:00:51,400" => "+13s", "01:12:44,320" => "+2.436m" }`

This method can be used to fix subtitles that are *at different times differently out of sync*,
and comes in handy especially if you have no idea what framerate your video or the video for which your subtitles
were created for is using - you just need to find two matching reference points in your video and subtitles.

**Framerate-based timeshift**

```ruby
  file.timeshift( "25fps" => "23.976fps" ) # Scale timecodes from 25fps to 23.976fps
```

For a framerate-based timeshift pass a hash of the form `"[old]fps" => "[new]fps"`

This is usually only useful if you have some background information about the designated framerates of your video and subtitles.

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

