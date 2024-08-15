require 'pdf-reader'
require 'strscan'
require 'date'

class Performance
  attr_accessor :pattern, :date, :sun, :time, :candidates

  def initialize(pattern:, date:, sun: :night, time: nil)
    @pattern = pattern
    @date = date
    @sun = sun
    @time = time
    @candidates = []
  end

  def self.all
    return @all if defined?(@all)
    @all = DATE_PERFORMANCES.flat_map do |date, performances|
      performances.map do |params|
        Performance.new(date: date, **params)
      end
    end
  end

  def regex
    return @regex if @regex
    artists = @pattern.split(/ b2b /i)
    regexes = artists.map{|a| a.gsub('_', '[a-zA-Z0-9]') }
    @regex = /^(#{regexes.join('|')})$/i
  end

  def match?(string)
    regex.match?(string)
  end

  DATE_PERFORMANCES = {
    '2024/08/25' => [
      { pattern: '________ __d______', time: '11:30pm' },
      { pattern: '___y_ _____' },
      { pattern: '_____ ____i__' },
      { pattern: '_o___' },
      { pattern: '____ __l_', sun: :sunrise },
      { pattern: '_a____ ___', sun: :day },
      { pattern: '______r_', sun: :day }
    ],
    '2024/08/26' => [
      { pattern: '__r____', time: '11:30pm' },
      { pattern: '______ _a_____' },
      { pattern: '_h___ ______' },
      { pattern: '___e_' },
      { pattern: '_a____ _____', sun: :sunrise },
      { pattern: '__s__', sun: :day }
    ],
    '2024/08/27' => [
      { pattern: '______m___', time: '11:30pm' },
      { pattern: '______n ______' },
      { pattern: '__o_' },
      { pattern: 'A____', sun: :sunrise },
      { pattern: '______e___', sun: :day },
      { pattern: '____ ___ ___ _i__ ____' }
    ],
    '2024/08/28' => [
      { pattern: '____t___ ____', sun: :day, time: '6:00pm' }
    ],
    '2024/08/29' => [
      { pattern: '_e___ _____', time: '11:30pm' },
      { pattern: '_____ __w___ B2B _a___ ___' },
      { pattern: '__i__ _______ B2B ____ _m___' },
      { pattern: '___n__ ____ B2B _a_____' },
      { pattern: '_e____ B2B __n___', sun: :sunrise },
      { pattern: '____ ___u_____ B2B _____ _a_____'},
      { pattern: '___n___ _______ B2B ____f____', sun: :day, time: '4:00pm' },
      { pattern: '__i___', sun: :sunset },
      { pattern: '_____s' }
    ],
    '2024/08/30' => [
      { pattern: '__n__' },
      { pattern: '_i__ & ____ ____a________' },
      { pattern: '_e__ ____' },
      { pattern: '___ __r_____', sun: :sunrise },
      { pattern: '__n____ _______' }
    ],
    '2024/08/31' => [
      { pattern: '__i__', time: '8:00pm' }
    ],
    '2024/09/01' => [
      { pattern: '____a_', time: '1:30am' },
      { pattern: '___e _____' },
      { pattern: '_____g___ __' },
      { pattern: '_a_ ___', sun: :sunrise },
      { pattern: '_____ __c_' }
    ]
  }
end

class ArtistList
  def artists
    @artists ||= %w{2023 2019 2018}.flat_map{|y| read(y) }.uniq.sort
  end

  def read(year)
    pdf = PDF::Reader.new("./#{year}.pdf")
    pdf.pages.flat_map do |page|
      page.text.scan(/(AM|PM) (.+?)(\s{4,})/).map do |match|
        artist = match[1]
        artist.gsub(/ \(live\)/i, '').gsub(/ B2B\s?/i, '')
      end.select do |artist|
        artist !~ /(AM|PM)/
      end
    end.uniq.sort
  end
end

def match_artists
  performances = Performance.all
  artist_list = ArtistList.new

  performances.each do |p|
    artist_list.artists.each do |a|
      if p.match?(a)
        p.candidates << a
      end
    end
  end

  File.open('performances.txt', 'w') do |f|
    grouped = performances.group_by(&:date)
    grouped.each do |date, ps|
      date = Date.parse(date)
      f.puts "#{date.strftime("%A %F")}:"
      ps.each do |p|
        title = String.new("#{p.pattern} (#{p.sun}")
        title << " #{p.time}" if p.time
        title << ")"

        f.puts "  #{title}:"
        p.candidates.sort.each do |c|
          f.puts "    #{c}"
        end
      end
      f.puts "\n"
    end
  end
end

match_artists