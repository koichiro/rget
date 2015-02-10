require 'webradio'
require 'niconico'
require 'pit'
require 'pathname'
require 'open-uri'
require 'rss'

class Nicovideo < WebRadio
	def initialize(url)
		account = Pit::get('nicovideo', :require => {
			:id => 'your nicovideo id',
			:pass => 'your nicovideo password'
		})
		@nico = Niconico.new(account[:id], account[:pass])
		@nico.login
		super
	end

	def download(name)
		player_url = get_player_url(@url)
		video = @nico.video(Pathname(URI(player_url).path).basename.to_s)
		serial = video.title.scan(/(?:[#第]| EP)(\d+)|/).flatten.compact[0].to_i
		@file = "#{name}##{'%02d' % serial}.#{video.type}"
		if File.exist? @file
			puts "'#{@file}' is existent. skipped."
			return
		end

		print "getting #{serial}..."
		open(@file, 'wb:ASCII-8BIT') do |o|
			video.get_video do |body|
				print '.'
				o.write(body)
			end
		end
		puts "done."
	end

	def mp3ize
		mp3_convert(@file, @file.sub(/\....$/, '.mp3'))
	end

private
	def get_player_url(list_url)
		begin
			rss = RSS::Parser.parse(list_url)
			item = rss.items.first
			return item.link
		rescue RSS::NotWellFormedError
			html = open(list_url, &:read)
			url = html.scan(%r|http://www.nicovideo.jp/watch/[\w]+|).first
			raise StandardError.new('video not found in this pege') unless url
			return url
		end
	end
end
