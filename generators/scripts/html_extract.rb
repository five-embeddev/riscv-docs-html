require 'rubygems'
require 'nokogiri'
require 'cgi'

MAX_HDR=5
STYLE=%w{code em }



def unquote(text)
  p text
  return text.gsub(/\&acirc;\u0080\u009D/,'"').gsub(/\&acirc;\u0080\u009C/,'"')
end

def finalize_lines(text)
  lines = []
  text[:para_lines].each {|x| 
    lines += x.gsub(/\s+/," ").split(/(?<=[^\d])\.\s/).compact.map {|y|CGI.unescapeHTML(y)}
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
        headers[idx] = unquote(CGI.unescapeHTML(elem.to_s.tr("\n"," ")).strip)
        if idx+1 < MAX_HDR
          headers[idx+1..MAX_HDR] = [nil] * (MAX_HDR-idx-1)
        end
      end            

    else
      if parent == "pre"
        text[:pre_lines] += elem.to_s.split("\n").compact
      elsif not elem.to_s =~ /^\s*$/
        string = elem.to_s.gsub(/\s+/," ")
        if STYLE.include?(parent)
          text[:join] = true
          if text[:para_lines].empty?
            text[:para_lines].push(string)
          else
            text[:para_lines][-1] += " " + string
          end
        else
          if text[:join]
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
  visit(0, output, headers,  text, "top", page.children)
  output.push([headers.compact,text[:id],finalize_lines(text)])
  return output
end


#html_extract(open(ARGV[0]))
