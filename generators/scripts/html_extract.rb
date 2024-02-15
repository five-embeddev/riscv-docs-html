# coding: utf-8
require 'rubygems'
require 'nokogiri'
require 'cgi'
require 'pp'
require 'iconv'

MAX_HDR=5
STYLE=%w{code em span a}

def clean_elem(elem)
  return clean_text(elem.text)
end

def clean_text(text)
  #text = text.encode("ASCII", :invalid => :replace, :undef => :replace, :replace => "?")
  text = text.force_encoding('utf-8').gsub("â\u0080\u009C",'"').gsub("â\u0080\u009D",'"').gsub("â\u0080\u0086","'").gsub("â\u0080²","")
  text = Iconv.iconv('ISO-8859-1//TRANSLIT//IGNORE','UTF-8', text).join("")
  return text.strip.squeeze(" \n").gsub(/\s+/," ")
end


def unquote(text)
  # CGI.unescapeHTML()...
  return text.gsub(/\&acirc;\u0080\u009D/,'"').gsub(/\&acirc;\u0080\u009C/,'"')
end

def finalize_lines(text)
  lines = []
  text[:para_lines].each {|x| 
    lines += [clean_text(x.gsub("\n"," "))] #.split(/(?<=[^\d])\.\s/).compact.map {|y|clean_text(y)}
  }
  lines += text[:pre_lines]
  text[:pre_lines].clear
  text[:para_lines].clear
  text[:join] = false
  return lines.compact
end

def visit(depth, output, headers, text, parent, elem)
  if elem.is_a?(Nokogiri::XML::Text)
    if parent =~ /^h(\d)/
      print "SAVE:" + text[:id] + "\n"
      output.push([headers.compact,text[:id],finalize_lines(text)])
      text[:depth] = depth
      idx = $1.to_i
      if idx < MAX_HDR
        headers[idx] = clean_elem(elem).tr("\n"," ")
        if idx+1 < MAX_HDR
          headers[idx+1..MAX_HDR] = [nil] * (MAX_HDR-idx-1)
        end
      end            

    else
      if parent == "pre"
        text[:pre_lines] += clean_elem(elem).split("\n").compact
      elsif not elem.text =~ /^\s*$/
        string = clean_elem(elem)
        
        if STYLE.include?(parent)
          text[:join] = true
          if text[:para_lines].empty?
            text[:para_lines].push(string)
          else
            text[:para_lines][-1] += " " + string
          end
        else
          if text[:join] || string =~ /^\s*\./ 
            text[:para_lines][-1] += " " + string
            text[:join] = false
          else
            text[:para_lines].push(string)
          end
        end
        text[:depth] = depth
      end
    end
  else
    if elem.is_a?(Nokogiri::XML::Element)
      parent= elem.name.to_s
    end
    if elem.respond_to?(:children)
      elem.children.each do  | celem |
        visit(depth +1, output, headers,  text, parent.clone, celem)
      end
    end
    if elem.is_a?(Nokogiri::XML::Element)

      if elem.name.to_s =~ /^h(\d)/
        elem.attributes.each do | type, attr |
          if type == "id"
            text[:id] = "#" + attr.value
            print "FIND:" + text[:id] + "\n"
          end
        end
      end

      if elem.name.to_s =~ /^section/
        elem.attributes.each do | type, attr |
          if type == "id"
            text[:id] = "#" + attr.value
            print "FIND:" + text[:id] + "\n"
          end
        end
      end


    end

  end
end

def html_extract(fin)
  output = []
  cnt=0
  headers = [nil]*10
  text = {:depth => 0, :id=>"", :pre_lines => [],:para_lines => [],:join=>false}
  fin.each_with_index do | line, line_no |
    if line =~ /^\-+$/
      cnt += 1
      # Jekyll Header
      break if cnt >= 2 
    elsif  line_no == 0
      # Pure HTML
      break
    end
  end
  page = Nokogiri::HTML(fin)   
  # Remove span/em/code etc
  page.xpath(".//span").each do |node|
    node.replace Nokogiri::XML::Text.new(node.text, node.document)
  end                          
  page.xpath(".//code").each do |node|
    node.replace Nokogiri::XML::Text.new(node.text, node.document)
  end                          
  page.xpath(".//em").each do |node|
    node.replace Nokogiri::XML::Text.new(node.text, node.document)
  end                          

  visit(0, output, headers,  text, "top", page.children)

  output.push([headers.compact,text[:id],finalize_lines(text)])
  return output
end


#pp html_extract(open(ARGV[0]))
