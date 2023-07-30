#!/bin/env ruby
# encoding: utf-8

require 'yaml'
require 'optparse'

options = {
  :keywords_yaml=>"../../data/keywords.yaml",
}

OptionParser.new do |opt|
  opt.on('--keywords-yaml KEYWORDS_YAML') { |o| options[:keywords_yaml] = o }
end.parse!


keywords_data = {}

def merge_url(type,a,b)
  list = []
  if a.include?type
    list += a[type]
  elsif b.include?type
    list += b[type]
  else
    return
  end
  a[type] = list
end

ARGV.each do | fpath |
  new_keywords_data = YAML.load_file(fpath)
  new_keywords_data.each_pair  do | keyword, data |
    if !keywords_data.include?(keyword)
      keywords_data[keyword] = data
    else
      keywords_data[keyword]["hit_count"] += data["hit_count"]
      merge_url("head_url",keywords_data[keyword], data)
      merge_url("content_url",keywords_data[keyword], data)
    end
  end
end


File.open(options[:keywords_yaml],"w") do | fout |
  fout.write(keywords_data.sort_by {|key| key}.to_h.to_yaml)
end
