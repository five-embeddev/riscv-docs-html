# encoding: utf-8

require 'yaml'
require 'optparse'

options = {
  :base_path=>"../../",
  :keywords_yaml=>"../../data/keywords.yaml",
  :menu_yaml_out=>"menu.yaml",
  :menu_html_out=>"menu.html"
}

OptionParser.new do |opt|
  opt.on('--keywords-yaml KEYWORDS_YAML') { |o| options[:keywords_yaml] = o }
  opt.on('--base-path BASE_PATH') { |o| options[:base_path] = o }
  opt.on('--yaml-out YAML_PATH') { |o| options[:menu_yaml_out] = o }
  opt.on('--html-out HTML_PATH') { |o| options[:menu_html_out] = o }
end.parse!

ENCODING_OPTIONS = {
  :invalid           => :replace,  # Replace invalid byte sequences
  :undef             => :replace,  # Replace anything not defined in ASCII
  :replace           => '',        # Use a blank for those replacements
  :universal_newline => true       # Always break lines with \n
}

keywords_data = {}
if File.exists?(options[:keywords_yaml])
  keywords_data = YAML.load_file(options[:keywords_yaml])
end


$hit_counts = {}

def update_keyword(data, keyword, key, value)
  if $hit_counts.has_key?(keyword)
    $hit_counts[keyword] += 1
  else
    $hit_counts[keyword] = 1
  end
  if not data.has_key?(keyword)
    data[keyword] = {}
  end
  if not data[keyword].has_key?(key)
    data[keyword][key] = []
  end
  if not data[keyword][key].include?(value)
    data[keyword][key].push(value)
  end
  data[keyword]["hit_count"] = $hit_counts[keyword] 
end

def parse_keywords(data, key, value, text)
  ["code", "span"].each do | tag |
    while text =~ /<#{tag}>\s*([a-zA-Z]\w+)\s*<\/#{tag}>/
      keyword=$1
      update_keyword(data, keyword, key, value)
      text = $'
    end
  end
end

def collect_headings(fpath, menu_top, keywords_data, options)
  menu_stack = [menu_top] + [nil]*10
  menu_node = menu_top
  depth=0
  id = ""
  File.open(fpath, "r:utf-8") do | fin |
    section_html = []
    fin.each_line do | line |
      if line =~ /h([123])\s+id=\"(.*?)\"/
        new_depth=$1.to_i - 1
        id=$2
      elsif line =~ /h([123])\s+data-number="[\d\.]+"\s+id=\"(.*?)\"/
        new_depth=$1.to_i - 1
        id=$2
      elsif line =~ /h([123])\s+data-number="\d[\d\.]*"/
        new_depth=$1.to_i - 1
      elsif line =~ /\s+id=\"(.*?)\"\s+data-number="[\d\.]+"/
        id=$1
        next
      else
        section_html.push(line)
        next
      end

      head=nil
      section=nil
      if line =~ /([\d\.]+)\s*\<\/span\>(.*?)(\<\/h|$)/
        section=$1
        head=$2.strip
      elsif line =~ /\>([\d\.]+).\s+(.*?)(\<\/h|$)/
        section=$1
        head=$2.strip
      elsif line =~ /\>(.*?)(\<\/h|$)/
        head=$1.strip
      end
      if !head.nil?
        p head
        head = head.encode(Encoding.find('ASCII'),
  :replace           => '',        # Use a blank for those replacements
  :universal_newline => true       # Always break lines with \n
)
        head.gsub!("'","")
        if (depth > new_depth)
          menu_node = menu_stack[new_depth] 
          depth = new_depth
        elsif (depth < new_depth)
          while (depth < new_depth)
            if menu_node.empty?
              menu_node.push({})
            end
            menu_node[-1]["menu"] ||= []
            depth += 1
            menu_node = menu_node[-1]["menu"]
            menu_stack[depth] = menu_node
          end
        end
        fname=fpath.sub(options[:base_path],"")
        url = fname.sub("references/","")
        url_section="/#{url}\##{id}"
        url_section = url_section.gsub("//","/")
        if head =~ /^\w/
          entry = {
            "name"  => head,
            "url" => url_section, 
            "depth" => depth, 
         }
          if section
            entry["section"] = section
          end
          menu_node.push(entry)
        end
        if id != ""
          update_keyword(keywords_data, id, "head_url", url_section)
        end
        parse_keywords(keywords_data, "head_url", url_section, head)
        parse_keywords(keywords_data, "content_url", url_section, section_html.join(""))
        section_html = []
      end
    end    
  end # file
end

menu_top = []

ARGV.each do | fpath |
  collect_headings(fpath, menu_top, keywords_data, options)
end # Files

File.open(options[:keywords_yaml],"w") do | fout |
  fout.write(keywords_data.sort_by {|key| key}.to_h.to_yaml)
end
while (menu_top.length == 1) and  menu_top[0].has_key?("menu") and not menu_top[0].has_key?("name")
  # skip the top
  menu_top = menu_top[0]["menu"]
end
                      
File.open(options[:menu_yaml_out],"w") do | fout |
  fout.write(menu_top.to_yaml)
end
File.open(options[:menu_html_out],"w") do | fout |
  fout.puts("<html><head></head><body>")
  def html_write(fout, list)
    fout.puts("<ul>")
    list.each do | item |
      if item['url'].nil? 
        url=""
      else
        url=File.basename(item['url'])      
      end
      fout.write("#{'  ' * item['depth'].to_i }<li>")
      fout.write("<b>#{item['section']}</b><a href=#{url}>#{item['name']}</a>")
      if item.include?("menu")
        html_write(fout, item["menu"])
      end
      fout.puts("</li>")
    end
    fout.puts("</ul>")
  end
  html_write(fout, menu_top)
  fout.puts("</body></html>")
end
