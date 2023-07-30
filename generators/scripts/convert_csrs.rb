#!/bin/env ruby

require 'yaml'
require 'optparse'

options = {
  :csr_yaml_in=>"../../data/riscv-isa-data/csr.yaml",
  :csr_yaml_out=>"../../data/riscv-isa-data/csr.yaml",
  :keywords_yaml=>"../../data/keywords.yaml",
  :csr_spec=>"../../external/riscv-isa-manual/latest/src/priv-csrs.tex",
  :parse_opcodes=>"../../external/riscv-opcodes/parse-opcodes",
  :convert_py=>"./convert.py"
}
OptionParser.new do |opt|
  opt.on('--csr-spec-tex CSR_SPEC') { |o| options[:csr_spec] = o }
  opt.on('--csr-yaml-in CSR_YAML') { |o| options[:csr_yaml_in] = o }
  opt.on('--csr-yaml-out CSR_YAML') { |o| options[:csr_yaml_out] = o }
  opt.on('--keywords-yaml-out KEYWORDS_YAML') { |o| options[:keywords_yaml] = o }
  opt.on('--parse-opcodes PARSE_OPCODES') { |o| options[:parse_opcodes] = o }
  opt.on('--convert-py CONVERT_PY') { |o| options[:convert_py] = o }
end.parse!

def remove_format(line)
  line = line.gsub(/\\tt/,"")
  line = line.sub("}","")
  line = line.sub("{","")
  line = line.sub(/\\\\/,"")
  line = line.sub(/\s+$/,"")
  line = line.sub(/^\s+/,"")
  line = line.sub(/^\s*\%\s*/,"")
  return line
end


def get_csrs(data, csr_spec)
  File.open(csr_spec,"r") do | fin |    
    in_table=false
    group = ""
    in_reg_list = false
    prev_line = ""
    fin.each_line do | line |
      line.chomp!
      if not in_table
        if line =~ /^\\begin\{tabular/
          in_table = true
          in_reg_list = false
          next
        end
      end # not in table
      if in_table        
        if line =~ /^\\end\{tabular/
          in_table = false
          in_reg_list = false
          next
        end
        
        if line =~ /^Number/
          in_reg_list = true
          next
        end
        if in_reg_list
          if line =~ /^\\hline/
            group = prev_line.split(/[\{\}]/)[4]
            next
          end
          parts = remove_format(line).split(/\s*\&\s*/)
          
          if parts.length == 4

            number, priv, name, desc = parts

            if number.include?("0x")
              number = number.hex
              if data.include?(name)
                data[name]["number"] = number
                data[name]["priv"] = priv
                if not data[name].include?("desc")
                  data[name]["desc"] = number
                end
              else
                new_entry = {
                  "number" => number,
                  "desc" => desc,
                  "priv" => priv,
                }
                data[name] = new_entry
              end
            end
          end
          
          prev_line = line
        end
      end # in table
    end # each line
  end # File
end

def get_csrs2(data, convert_py, parse_opcodes)
  data_txt = `#{convert_py} #{parse_opcodes}`
  data_src = eval(data_txt)
  data_src.each_pair { |csr, index|
    if not data.include?(csr)
      print(csr)
      data[csr] = {"number" => index}      
    end
  }
end  


def add_urls(data, urls)
  data.each_pair do | name, values |
    next if values.has_key?("url")
    try_names = [name]
    if name =~ /^([a-zA-Z]+)\d+/
      try_names.push($1)
    end
    try_names.each do | try_name | 
      if urls.has_key?(try_name)
        name_data = urls[try_name]
        if name_data.has_key?("head_url")
          values["url"] = name_data["head_url"][0]
        elsif name_data.has_key?("content_url")
          values["url"] = name_data["content_url"][0]
        end
        break
      end
    end
  end
end


def add_section(data, keywords_data)
  data.each_pair do | name, values |
    urls = []
    if keywords_data.include?name
      if keywords_data[name].include?("head_url")
        urls += keywords_data[name]["head_url"]
      end
      if keywords_data[name].include?("content_url")
        urls += keywords_data[name]["content_url"]
      end
    end
    urls.each do | url |
      base_url = url.split("#")[0]
      low_path = base_url.split("/")[1]
      file = base_url.split("/")[-1]
      base = file.split(".")[0]
      if low_path  == "riscv-debug-spec"
        section = "debug"
      else
        section = base
      end
      if not values.has_key?("sections") or values["sections"].is_a?Array
        values["sections"] = {section => [url]}
      elsif not values["sections"].include?(section)
        values["sections"][section] = [url]
      elsif not values["sections"][section].include?(url)
        values["sections"][section].append(url)
      end
    end
  end
end

if File.exists?(options[:keywords_yaml])  then
  keywords_data = YAML.load_file(options[:keywords_yaml])
else
  keywords_data = {}
end

if File.exists?(options[:csr_yaml_in])  then
   csr_data = YAML.load_file(options[:csr_yaml_in])
else
  csr_data = {"regs" => {}}
end

get_csrs(csr_data["regs"], options[:csr_spec])
get_csrs2(csr_data["regs"], options[:convert_py], options[:parse_opcodes])
add_urls(csr_data["regs"], keywords_data)
add_section(csr_data["regs"], keywords_data)

csr_data["regs"] = csr_data["regs"].sort_by {|key| key}.to_h

File.open(options[:csr_yaml_out],"w") do | fout |
  fout.write(csr_data.to_yaml)
end

