# coding: utf-8
require 'yaml'
#require 'file'
require '../scripts/html_extract'
require 'optparse'

options = {
  :opcode_path=>"../../external/riscv-opcodes/",
  :manual_path=>"/riscv-isa-manual/latest/",
  :html_path=>"../../references/",
  :output_file=>"../../data/riscv-isa-data/opcodes.yaml",
}
OptionParser.new do |opt|
  opt.on('--opcode-path OPCODE_PATH') { |o| options[:opcode_path] = o }
  opt.on('--manual-path MANUAL_PATH') { |o| options[:manual_path] = o }
  opt.on('--html-path HTML_PATH') { |o| options[:html_path] = o }
  opt.on('--output-file OUTPUT_YAML') { |o| options[:output_file] = o }
end.parse!


OPCODE_FILES=%w{opcodes opcodes-custom opcodes-pseudo opcodes-rvc opcodes-rvc-pseudo opcodes-rvv}

ISA_LIST=%w{
   rv32 
   rv32e 
   rv64 
   rv128 
   zifencei 
   zihintpause 
   m 
   a 
   csr 
   counters 
   f 
   d 
   q 
   zfh 
   rvwmo 
   c 
   b 
   j 
   p 
   v 
   zam 
   zfinx 
   ztso 
   machine supervisor hypervisor} 



OPCODE_GROUP_MAP= {
  "opcodes-rvv" => "v",
  "opcodes-rvc" => "c",
  "opcodes-rvc-pseudo" => "c",
}

first_section = {}
section_labels = {}

OPCODE_GROUP_DEFAULT_DESC= {
  "opcodes-custom" => {"custom" => {"#" => {"url"=>"/riscv-isa-manual/latest/", "headers"=>[],}}},
  "opcodes-psuedo" => {"psuedo" => {"#" => {"url"=>"/riscv-isa-manual/latest/", "headers"=>[]}}},
  "opcodes-rvv" => {"v" => {"#_introduction" => {"url"=>"/riscv-v-spec/draft/v-spec.html#_introduction", "headers"=>[]}}},
  "opcodes-rvc" => {"c" => {"#compressed" => {"url"=>"/riscv-isa-manual/latest/c.html#compressed", "headers"=>[]}}},
}
OPCODE_GROUP_DEFAULT_DESC["opcodes-rvc-pseudo"]  =OPCODE_GROUP_DEFAULT_DESC["opcodes-rvc"]

def opcode_alias(opcode_aliases,opcode)
  if opcode =~ /^amo/
    ret="AMO instructions"
    opcode_aliases[ret] ||= []
    opcode_aliases[ret].push(opcode)
  end
end


OPCODE_TYPES={
  ["bimm12hi", "rs1", "rs2", "bimm12lo"]=>["rs1", "rs2", "bimm12"],
  ["rd", "rs1", "imm12"]=>["rd", "rs1", "imm12"],
  ["rd", "jimm20"]=>["rd", "jimm20"],
  ["rd", "imm20"]=>["rd", "imm20"],
  ["rd", "rs1"]=>["rd", "rs1"],
  ["rd", "rs1", "rs2"]=>["rd", "rs1", "rs2"],
  ["imm12hi", "rs1", "rs2", "imm12lo"]=>["imm12hi", "rs1", "rs2", "imm12lo"],
  ["rs1", "rd"]=>["rs1", "rd"],
  ["imm12", "rs1", "rd"]=>["imm12", "rs1", "rd"],
  ["rs1", "rs2"]=>["rs1", "rs2"],
  ["rd", "rs1", "rs2", "rs3"]=>["rd", "rs1", "rs2", "rs3"],
  ["rd"]=>["rd"],
  ["rd", "zimm"]=>["rd", "zimm"],
  ["rd=2"]=>["rd=2"],
  ["!rs2"]=>["!rs2"],
  ["!rs1", "!rs2=c.jalr"]=>["!rs1", "!rs2=c.jalr"],
  ["zimm11", "rs1", "rd"]=>["zimm11", "rs1", "rd"],
  ["rs2", "rs1", "rd"]=>["rs2", "rs1", "rd"],
  ["rs1", "vd"]=>["rs1", "vd"],
  ["rs1", "vs3"]=>["rs1", "vs3"],
  ["rs2", "rs1", "vd"]=>["rs2", "rs1", "vd"],
  ["rs2", "rs1", "vs3"]=>["rs2", "rs1", "vs3"],
  ["vs2", "rs1", "vd"]=>["vs2", "rs1", "vd"],
  ["vs2", "rs1", "vs3"]=>["vs2", "rs1", "vs3"],
  ["vs2", "vs1", "vd"]=>["vs2", "vs1", "vd"],
  ["vs2", "rd"]=>["vs2", "rd"],
  ["vs2", "simm5", "vd"]=>["vs2", "simm5", "vd"],
  ["simm5", "vd"]=>["simm5", "vd"],
  ["vs2", "vs1", "rd"]=>["vs2", "vs1", "rd"],
  ["vs2", "vd"]=>["vs2", "vd"]
}


def opcode_args(data)
  filtered_list = []
  opcode = data[0]
  data[1..-1].each do | param |
    if param =~ /((v|r)(d|s)|imm|bimm)/        
      filtered_list.push(param)
    end
  end
  if !OPCODE_TYPES.include?(filtered_list)
    OPCODE_TYPES[filtered_list]= filtered_list
  else
    filtered_list = OPCODE_TYPES[filtered_list]
  end
  return filtered_list
end


def get_op_desc(options, opcode_data, opcode_aliases, section_labels, isa_name)
  fname_base = isa_name + ".html"
  fname =  File.join( options[:manual_path], fname_base)
  get_op_desc_fname(options, opcode_data, opcode_aliases, section_labels, isa_name, fname)
end

def get_op_desc_fname(options, opcode_data, opcode_aliases, section_labels, isa_name, fname_path)
  #fname =  File.join( FS_MANUAL_PATH, fname_base)
  #isa_name=File.basename(fname, ".tex")
  fname  = options[:html_path] + "/" + fname_path
  fname_base = File.basename(fname_path)
  url_base = fname_path

  section_labels[isa_name] = {}

  opcode_keys = opcode_data.keys()
  psuedo_opcodes = opcode_keys.select {|opcode| opcode[0] == "@"}.map{|opcode| opcode[1..-1]}
  opcode_keys.concat(psuedo_opcodes)

  # Regexp to cover all opcodes
  opcode_stem_aliases = {}
  opcode_upcase_str = "\\b("+opcode_keys.map {|x| x.upcase.gsub(/\./,'\.')}.join('|')+")\\b"
  opcode_upcase_re = Regexp.new(opcode_upcase_str)
  opcode_downcase_str = "\\b("+opcode_keys.map {|x| x.downcase.gsub(/\./,'\.')}.join('|')+")\\b"
  opcode_downcase_re = Regexp.new(opcode_upcase_str)
  opcode_alias_str = "\\b("+opcode_aliases.keys().map {|x| x}.join('|')+")\\b"
  opcode_alias_re = Regexp.new(opcode_alias_str)  
  opcode_stem_re = nil
  if isa_name == "v"
    opcode_stem_parts = []
    opcode_data.keys().each do |opcode| 
      next unless opcode_data[opcode]["opcode_group"] == "opcodes-rvv"
      parts = opcode.split(".",2)
      if opcode_stem_aliases.include?(parts[0])
        opcode_stem_aliases[parts[0]].push(opcode)
      else
        opcode_stem_aliases[parts[0]] = [opcode]
        opcode_stem_parts.push(parts[0])
      end
    end
    opcode_stem_str = "\\b(" + opcode_stem_parts.join('|') + ")\\b"
    opcode_stem_re = Regexp.new(opcode_stem_str)
  end
  opcodes = []
  saved_opcodes = []

  # Get all lines in the file.
  File.open(fname,"r:UTF-8") do | fin |

    c = ""
    nest=0
    skip=false

    html_data = html_extract(fin)
    html_data.each do | headers, id, text |
      
      if not section_labels[isa_name].has_key?(id)
        section_labels[isa_name][id] = {
          "headers" => headers.compact,
          "url" => url_base + id,
        }
      end
      
      text.each do |line|
        matched_opcodes = []
        search_str = line.tr("\n\r"," ")
        while not search_str =~ /^\s*$/
          scan_upcase_re=search_str.scan(opcode_upcase_re)
          if !scan_upcase_re.empty? then
            scan_upcase_re.each do | match |
              match.each do |matched_opcode|
                matched_opcodes.push( matched_opcode.downcase)
              end
            end
            search_str = $`
          elsif search_str =~ opcode_downcase_re then
            matched_opcodes.push( $1.downcase)
            search_str = $`
          elsif search_str =~ opcode_alias_re then
            matched_opcodes += opcode_aliases[$1]
            search_str = $`
          elsif not opcode_stem_re.nil? and search_str =~ opcode_stem_re then
            matched_opcodes += opcode_stem_aliases[$1]
            search_str = $`
          else
            #p search_str
            break
          end
        end

        psuedo_matched_opcodes = matched_opcodes.select { |opcode| psuedo_opcodes.include?opcode}.map {|opcode| "@" + opcode}
        matched_opcodes.concat(psuedo_matched_opcodes)
        
        matched_opcodes.each do |opcode|
          desc=line
          #p opcode
          if opcode_data.has_key?(opcode)
            if not opcode_data[opcode].has_key?("desc")
              opcode_data[opcode]["main_desc"] = isa_name
              opcode_data[opcode]["main_id"] = id
              opcode_data[opcode]["desc"] = {}
              saved_opcodes.push(opcode)
            end
            new_desc = desc.strip
            opcode_data[opcode]["desc"][isa_name] ||= {}
            opcode_data[opcode]["desc"][isa_name][id] ||= {}
            opcode_data[opcode]["desc"][isa_name][id]["text"] ||= []            
            if !opcode_data[opcode]["desc"][isa_name][id]["text"].include?(new_desc)
              opcode_data[opcode]["desc"][isa_name][id]["text"].push(new_desc)
            end
          end
        end
      end # alll lines
    end # all html
  end
end



def get_opcodes(opcode_data, fname)
  opcode_group=File.basename(fname)
  opcodes=[]
  File.open(fname,"r") do | fin |    
    fin.each_line do | line |
      next if line =~ /^\s*$/
      next if line =~ /^\#/
      parts = line.split(/\s+/)      
      opcode=parts[0]
      opcode_data[opcode]={"opcode" => parts,
                           "opcode_group" => opcode_group,
                           "opcode_args" => opcode_args(parts),
                          }      
      opcodes += [opcode]
    end
  end
  return {opcode_group => opcodes}
end

def float_alias(options, opcode_desc,opcode_data,section_labels, type,size)
  opcode_desc[type] ||= {}
  opcodes = []
  regexp_str = "^(f\\w+\)." + type
  re = Regexp.new(regexp_str)
  id = ""
  opcode_data.each_pair do  | opcode, info |
      next if info.has_key?("desc")
      if opcode =~ re
        single = $1 + ".s"
        if opcode_data.has_key?(single)
          info_src = opcode_data[single]
          if info_src.has_key?("desc")
            id = info_src["main_id"]

            url =  options[:manual_path] + "/" + type + ".html"
            if not section_labels[type].has_key?(id)
              section_labels[type][id] = {
                "headers" => section_labels["f"][id]["headers"],
                "url" => url
              }
            end

            text = []
            info_src["desc"]["f"][id]["text"].each do |sentence|
              text.push(sentence)
            end
            info["main_desc"] = type
            info["main_id"] = id
            info["desc"] = {type => {
                              id => {  
                                "text" => text,
                              }
                            }
                           }
            opcode_desc[type].push(opcode)
          end
        end
      end
      
  end
  return opcodes
end

def resolve_desc(desc, opcode_data)
  opcodes = []
  opcode_data.each_pair do  | opcode, info |
    assign_desc = nil
    if OPCODE_GROUP_MAP.has_key?(info["opcode_group"])
      assign_desc = OPCODE_GROUP_MAP[info["opcode_group"]]
    elsif info.has_key?("main_desc")
      assign_desc = info["main_desc"]
    end
    if not assign_desc.nil?
      desc[assign_desc] ||= []
      desc[assign_desc].push(opcode)
    end
  end
end

def get_no_desc(opcode_data, section_labels)
  opcodes = []
  opcode_data.each_pair do  | opcode, info |
      next if info.has_key?("main_desc")
      group =  info["opcode_group"]
      if OPCODE_GROUP_DEFAULT_DESC.has_key?(group)

        assign_desc = OPCODE_GROUP_DEFAULT_DESC[group]
        isa = assign_desc.keys[0]
        id = assign_desc[isa].keys[0]
        
        section_labels[isa] ||= {}
        if not section_labels[isa].has_key?(id)
          section_labels[isa][id] = {
            "headers" =>  assign_desc[isa][id]["headers"],
            "url" => assign_desc[isa][id]["url"]
          }
        end

        info["main_desc"] = isa
        info["main_id"] = id
        info["desc"] = {}
        info["desc"][isa] ||= {}
        info["desc"][isa][id] ||= {"text" => []}

        next
      end
      opcodes.push(opcode)
  end
  return opcodes
end

def collect_sections(opcode_data) 
  sections = {}
  opcodes = {}
  ISA_LIST.each do |isa|
    sections[isa] = {}
  end
  sections["custom"] = {}
  opcode_data.each_pair do  | opcode, info |
    next if opcodes.has_key?(opcode)
    next unless info.has_key?("main_desc")
    next unless info.has_key?("main_id")
    isa=info["main_desc"]
    id=info["main_id"]
    if not sections.has_key?(isa)
      print "NO ISA?? " + isa
      next
    end
    sections[isa][id] ||= []
    sections[isa][id].push(opcode)
  end
  return sections
end

top_data = {}
opcode_data = {}
groups = {}
desc = {}

OPCODE_FILES.each do |opcode_file|
  groups.merge!(get_opcodes(opcode_data,options[:opcode_path] + "/" + opcode_file))
end

opcode_aliases = {}
opcode_data.each_pair do  | opcode, info |
  opcode_alias(opcode_aliases, opcode)
end


ISA_LIST.each do | isa |
  next if isa == "v"
  get_op_desc(options, opcode_data,opcode_aliases,section_labels,isa)
end
get_op_desc_fname(options, opcode_data,opcode_aliases,section_labels, "v","/riscv-v-spec/draft/v-spec.html")

resolve_desc(desc, opcode_data)

float_alias(options, desc, opcode_data,section_labels, "d","double")
float_alias(options, desc, opcode_data,section_labels, "q","quad")

desc["unassigned"] = get_no_desc(opcode_data, section_labels)

def sort_hash_list(data)
  data = data.sort_by {|key| key}.to_h
  data.keys.sort.each do | key | 
    data[key] = data[key].sort
  end
  return data
end
def sort_hash_hash_list(data)
  data = data.sort_by {|key| key}.to_h
  data.keys.sort.each do | key | 
    data[key] = sort_hash_list(data[key])
  end
  return data
end
def sort_hash(data)
  return data.sort_by {|key| key}.to_h
end
def sort_hash_hash(data)
  data = data.sort_by {|key| key}.to_h
  data.keys.sort.each do | key | 
    data[key] = sort_hash(data[key])
  end
  return data
end


top_data["opcodes"] = sort_hash(opcode_data)
top_data["groups"] = sort_hash_list(groups)
top_data["sections"] = sort_hash_hash_list(collect_sections(opcode_data))
top_data["sections_labels"] = sort_hash_hash(section_labels)
top_data["isa"] = sort_hash_list(desc)
top_data["args"] = OPCODE_TYPES

File.open(options[:output_file],"w") do | fout |
  fout.write(top_data.to_yaml)
end

