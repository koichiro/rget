require 'webradio'

class HLS < WebRadio
private
	def hls_download(name, html, serial_pattern, m3u_pattern)
		serial = html.scan(serial_pattern).flatten.sort{|a,b| a.to_i <=> b.to_i}.last
		@m4a_file = "#{name}##{serial}.m4a"
		@mp3_file = @m4a_file.sub(/\.m4a$/, '.mp3')
		mp3nize(@m4a_file, @mp3_file) do
			m3u_meta2 = html.scan(m3u_pattern).flatten.sort.last
			unless m3u_meta2
				raise WebRadio::DownloadError.new("recent radio program not found.")
			end
			m3u_meta1 = URI.open(m3u_meta2, &:read)
			m3u = m3u_meta1.scan(/^[^#].*/).first
			save_m4a(URI(m3u), @m4a_file)
		end
	end

	def get_m4a(uri_playlist)
		URI.open(uri_playlist).each_line do |l|
			next if /^#/ =~ l
			l.chomp!
			print "."
			yield URI.open(uri_playlist + l, 'r:ASCII-8BIT', &:read)
		end
	end
	
	def save_m4a(uri_playlist, m4a_file)
		open(m4a_file, 'wb:ASCII-8BIT') do |m4a|
			get_m4a(uri_playlist) do |part|
				m4a.write part
			end
		end
	end
end
