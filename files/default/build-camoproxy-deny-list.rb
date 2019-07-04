#!/usr/bin/ruby

FES_DIR = '/etc/haproxy/front-end-security'.freeze
SOURCE_FILE = "#{FES_DIR}/deny-403-urls-camoproxy.src".freeze
DEST_FILE = "#{FES_DIR}/deny-403-urls-camoproxy.lst".freeze

File.open(DEST_FILE, 'w') do |dest|
  File.readlines(SOURCE_FILE).each do |line|
    dest.puts line.strip.unpack('H*')
  end
end
