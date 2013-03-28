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

#### Timeshift

The method `timeshift` offers multiple ways to alter the timecodes of your subtitles;  
It takes a hash and can do three different things, depending on the options you pass:

**Constant timeshift** 

```ruby
  file.timeshift( :all => "-2.5s" ) # Shift all subtitles so they show up 2.5 seconds earlier    
```

Simply pass a hash of the form `:all => "[+/-][amount][h|m|s|mil]"`  
Other example options, e.g.: `:all => "+700mil"`, `:all => "1.34m"`, `:all => "0.15h"`

**Progressive timeshift**

```ruby
  file.timeshift({ 1 => "00:02:12,000", 843 => "01:38:06,000" }) 
```

This example call 1.) shifts the **first subtitle** so it starts at **00:02:12**, 2.) shifts the  **last subtitle** (let's assume #843 is the last one in your file) so it starts at **01:38:06**, and 3.) also shifts all the ones in between seamlessly to their relatively earlier or later begin times.

To make this work pass ***2 key/value pairs*** where each key/value pair can take any of the following forms: 

* `[id] => "[hh]:[mm]:[ss],[mil]"`
* `[id] => "[+/-][amount][h|m|s|mil]"`
* `"[hh]:[mm]:[ss],[mil]" => "[hh]:[mm]:[ss],[mil]"`
* `"[hh]:[mm]:[ss],[mil]" => "[+/-][amount][h|m|s|mil]"`

This method can be used to fix subtitles that are *at different times differently out of sync*,
especially if you have no idea what framerate your video or the video for which your subtitles
were created is using - you just need to look up 2 reference points in your video and subtitle.

**Framerate-based timeshift**

```ruby
  file.timeshift({ "25fps" => "23.976fps" }) # scale timecodes from 25fps to 23.976fps
```

For a framerate-based timeshift pass a hash of the form `"[old]fps" => "[new]fps"`

This is usually only useful if you have some background information about the designated framerates of your video and subtitle.

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
