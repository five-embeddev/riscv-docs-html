#coding: utf-8
require 'yaml'
#require 'file'
require '../scripts/html_extract'
require 'optparse'

options = {
  :opcode_path=>"../../external/riscv-opcodes/",
  :user_manual_path=>"/riscv-user-isa-manual/latest/",
  :priv_manual_path=>"/riscv-priv-isa-manual/latest/",
  :vector_manual_path=>"/riscv-v-spec/v1.0/",
  :isa_sim_path=>"../../external/riscv-isa-sim/riscv/insns/",
  :asm_man_path=>"../../external/riscv-asm-manual/riscv-asm.md",
  :html_path=>"../../references/",
  :output_file=>"../../data/riscv-isa-data/opcodes.yaml",
}
OptionParser.new do |opt|
  opt.on('--opcode-path OPCODE_PATH') { |o| options[:opcode_path] = o }
  opt.on('--user-manual-path MANUAL_PATH') { |o| options[:user_manual_path] = o }
  opt.on('--priv-manual-path MANUAL_PATH') { |o| options[:priv_manual_path] = o }
  opt.on('--vector-manual-path MANUAL_PATH') { |o| options[:vector_manual_path] = o }
  opt.on('--html-path HTML_PATH') { |o| options[:html_path] = o }
  opt.on('--isa-sim-path SIM_PATH') { |o| options[:isa_sim_path] = o }
  opt.on('--asm-manual-path MANUAL_PATH') { |o| options[:asm_man_path] = o }
  opt.on('--output-file OUTPUT_YAML') { |o| options[:output_file] = o }
end.parse!

# These are the files that will be read from  https://github.com/riscv/riscv-opcodes.git

# Opcode files are named rv_*
OPCODE_FILES=Dir["../../external/riscv-opcodes/rv_*"].map {|p|File.basename(p)} +
             Dir["../../external/riscv-opcodes/rv32_*"].map {|p|File.basename(p)} +
             Dir["../../external/riscv-opcodes/rv64_*"].map {|p|File.basename(p)}

# We are scraping the html docs to find references to instructions.
# Which section has priority? - this is a quick and dirty override.
SECTION_PRIORITY_OVERRIDE=%w{
    #integer-register-register-operations
    #integer-register-immediate-instructions
    #nop-instruction
}
SECTION_LOWEST_PRI=SECTION_PRIORITY_OVERRIDE.length + 1

CORE_ISA=%w{
   rv32 
   rv64 
   rv128 
}

# These are the html files that will be read after conversion from tex/adoc
USER_ISA_LIST=%w{
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
}
PRIV_ISA_LIST=%w{
   machine 
   supervisor 
   hypervisor} 

ISA_LIST=USER_ISA_LIST+PRIV_ISA_LIST

OPCODE_GROUP_MAP= {
  "c" => "c",
  "v" => "v",
}

first_section = {}
section_labels = {}

OPCODE_GROUP_DEFAULT_DESC= {
  "v" => {"v" => {"#_introduction" => {"url"=> options[:vector_manual_path] + "/v-spec.html#_introduction", "headers"=>[]}}},
  "c" => {"c" => {"#compressed" => {"url"=> options[:user_manual_path] + "/c.html#compressed", "headers"=>[]}}},
}

def opcode_alias(opcode_aliases,opcode)
  if opcode =~ /^amo/
    ret="AMO instructions"
    opcode_aliases[ret] ||= []
    opcode_aliases[ret].push(opcode)
  end
end


# The opcodes data file includes the opcode arguments as they are encoded in the instruction word
# sometimes that requires splitting immediate values
# This map restores the hi/lo etc parts to a single parameter that the assembler will use
# Left side: opcode encoding
# Right side: assembler opcode arguments
OPCODE_TYPES={
  ["bimm12hi", "rs1", "rs2", "bimm12lo"]=>["rs1", "rs2", "bimm12"],
  ["rd", "rs1", "imm12"]=>["rd", "rs1", "imm12"],
  ["rd", "jimm20"]=>["rd", "jimm20"],
  ["rd", "imm20"]=>["rd", "imm20"],
  ["rd", "rs1"]=>["rd", "rs1"],
  ["rd", "rs1", "rs2"]=>["rd", "rs1", "rs2"],
  ["imm12hi", "rs1", "rs2", "imm12lo"]=>["rs1", "rs2", "imm12"],
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
  ["vs2", "vd"]=>["vs2", "vd"],
  ["rd_p","rs1_p", "c_uimm7lo", "c_uimm7hi"] =>  ["rd_p","rs1_p", "c_uimm7"],
  ["rs1_p","rs2_p", "c_uimm7lo", "c_uimm7hi"] =>  ["rs1_p","rs2_p", "c_uimm7"],
  ["rd_n0", "c_uimm8sphi", "c_uimm8splo"] => ["rd_n0", "c_uimm8sp"],
  ["rd_rs1_n0","c_nzimm6lo","c_nzimm6hi"] => ["rd_rs1_n0","c_nzimm6","c_nzimm6"],
  ["rd","c_imm6lo", "c_imm6hi"] => ["rd","c_imm6"],
  ["c_nzimm10hi", "c_nzimm10lo"] => ["c_nzimm10"],
  ["rd", "c_uimm9sphi", "c_uimm9splo"] => ["rd", "c_uimm9sp"],
  ["rd_p", "rs1_p", "c_uimm8lo", "c_uimm8hi"] =>  ["rd_p", "rs1_p", "c_uimm8"],

  ["rd_p", "rs1_p", "c_uimm2"]=>["rd_p", "rs1_p", "c_uimm2"],
  ["rd_p", "rs1_p", "c_uimm1"]=>["rd_p", "rs1_p", "c_uimm1"],
  ["rs2_p", "rs1_p", "c_uimm2"]=>["rs2_p", "rs1_p", "c_uimm2"],
  ["rs2_p", "rs1_p", "c_uimm1"]=>["rs2_p", "rs1_p", "c_uimm1"],
  ["rd_rs1_p"]=>["rd_rs1_p"],
  ["rd_rs1_p", "rs2_p"]=>["rd_rs1_p", "rs2_p"],
  ["zimm10", "zimm", "rd"]=>["zimm10", "zimm", "rd"],
  ["vs1", "vd"]=>["vs1", "vd"],
  ["vd"]=>["vd"],
  ["c_spimm"]=>["c_spimm"],
  ["rd_p", "c_nzuimm10"]=>["rd_p", "c_nzuimm10"],
  ["c_nzimm6hi", "c_nzimm6lo"]=>["c_nzimm6"],
  ["rd_n2", "c_nzimm18hi", "c_nzimm18lo"]=>["rd_n2", "c_nzimm18"],
  ["rd_rs1_p", "c_imm6hi", "c_imm6lo"]=>["rd_rs1_p", "c_imm6"],
  ["c_imm12"]=>["c_imm12"],
  ["rs1_p", "c_bimm9lo", "c_bimm9hi"]=>["rs1_p", "c_bimm9"],
  ["rs1_n0"]=>["rs1_n0"],
  ["rd", "c_rs2_n0"]=>["rd", "c_rs2_n0"],
  ["c_rs1_n0"]=>["c_rs1_n0"],
  ["rd_rs1", "c_rs2_n0"]=>["rd_rs1", "c_rs2_n0"],
  ["c_rs2", "c_uimm8sp_s"]=>["c_rs2", "c_uimm8sp_s"],
  ["rs1_p", "rs2_p", "c_uimm8lo", "c_uimm8hi"]=>["rs1_p", "rs2_p", "c_uimm8"],
  ["c_rs2", "c_uimm9sp_s"]=>["c_rs2", "c_uimm9sp_s"], 
  ["rs1"]=>["rs1"], 
  ["rs1", "imm12hi"]=>["rs1", "imm12hi"],

  ["rd_rs1_p", "c_nzuimm5"]=>["rd_rs1_p", "c_nzuimm5"],
  ["rd_rs1_n0", "c_nzuimm6lo"]=>["rd_rs1_n0", "c_nzuimm6lo"], 
  ["rd", "c_uimm8sphi", "c_uimm8splo"]=>["rd", "c_uimm8sp"], 
  ["rs1_p", "rs2_p", "c_uimm8hi", "c_uimm8lo"]=>["rs1_p", "rs2_p", "c_uimm8"],
  ["rd_rs1_n0", "c_imm6lo", "c_imm6hi"]=>["rd_rs1_n0", "c_imm6"], 
  ["rd_rs1_p", "c_nzuimm6lo", "c_nzuimm6hi"]=>["rd_rs1_p", "c_nzuimm6"], 
  ["rd_rs1_n0", "c_nzuimm6hi", "c_nzuimm6lo"]=>["rd_rs1_n0", "c_nzuimm6"], 
  ["rd_n0", "c_uimm9sphi", "c_uimm9splo"]=>["rd_n0", "c_uimm9sp"],

}



NEW_OPCODE_TYPES={}

def opcode_args(data, all_opcode_args_trace)
  filtered_list = []
  opcode = data[0]
  return if opcode.nil?
  data[1..-1].each do | param |
    if param =~ /((v|r)(d|s)|imm|bimm)/        
      filtered_list.push(param)
    end
  end
  if !OPCODE_TYPES.include?(filtered_list)
    OPCODE_TYPES[filtered_list]= filtered_list
    NEW_OPCODE_TYPES[filtered_list]= filtered_list
  else
    filtered_list = OPCODE_TYPES[filtered_list]
  end
  filtered_list.each do |arg|
    all_opcode_args_trace[arg] ||= []
    all_opcode_args_trace[arg].append(opcode)
  end


  return filtered_list
end


def get_op_desc(options, opcode_data, opcode_aliases, section_labels, isa_name, manual_path)
  fname_base = isa_name + ".html"
  fname =  File.join(manual_path, fname_base)
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
      next unless opcode_data[opcode]["opcode_group"] == "v"
      parts = opcode.split(".",2)
      if opcode_stem_aliases.include?(parts[0])
        opcode_stem_aliases[parts[0]].push(opcode)
      else
        opcode_stem_aliases[parts[0]] = [opcode]
        opcode_stem_parts.push(parts[0])
      end
    end
    if opcode_stem_parts.empty?
      raise "NO PARTS!"
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
              opcode_data[opcode]["main_url_base"] = url_base
              opcode_data[opcode]["main_desc"] = isa_name
              opcode_data[opcode]["main_id"] = id
              opcode_data[opcode]["desc"] = {}
              saved_opcodes.push(opcode)
            else
              old_desc = opcode_data[opcode]["main_desc"]
              old_id = opcode_data[opcode]["main_id"]
              if (old_desc == isa_name) or CORE_ISA.include?(isa_name)
                # Lowest index has higher priority
                pri_old = SECTION_PRIORITY_OVERRIDE.index(old_id) || SECTION_LOWEST_PRI
                pri_new = SECTION_PRIORITY_OVERRIDE.index(id) || SECTION_LOWEST_PRI
                if pri_new < pri_old
                  opcode_data[opcode]["main_desc"] = isa_name
                  opcode_data[opcode]["main_id"] = id                  
                end
              end
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

def get_psuedo(opcode_data, fname)
  File.open(fname,"r", :encoding => 'UTF-8') do | fin |    
      mode = :start
      fin.each_line do | line |
        if mode == :start 
          if line =~ /name\=pseudoinstructions/
            mode = :ptable
          end
        end
        if mode == :ptable
          # Expand lines for each variant
          elines = [line]
          if line =~ /\{b\|h\|w\|d\}/
            elines = [
              line.gsub(/\{b\|h\|w\|d\}/,'b'),
              line.gsub('\{b\|h\|w\|d\}','h'),
              line.gsub('\{b\|h\|w\|d\}','w'),
              line.gsub('\{b\|h\|w\|d\}','d'),
            ]
          elsif line =~ /\{w\|d\}/
            elines = [
              line.gsub('\{w\|d\}','w'),
              line.gsub('\{w\|d\}','d'),
            ]
          elsif line =~ /\[h\]/
            elines = [
              line.gsub('\[h\]',''),
              line.gsub('\[h\]','h'),
            ]
          end
          elines.each do | eline |
            parts = eline.split("|").map {|x| x}
            if parts[0] =~ /^([\w\.]+)\s([\w\s\,]+)/
              opcode=$1
              next if opcode == "Pseudoinstruction"
              args=$2.split(",").map {|x| x.strip}.delete_if {|x| x==""}
              opcode_data[opcode]={"opcode" => [opcode] + args,
                                   "opcode_group" => "psuedo",
                                   "opcode_args" => args,
                                   "psuedo_to_base" => parts[1].split(";").map {|x| x.strip},
                                  }
            end # Opcode
          end # EAch eline
        end # in the psuedo op table
      end # each line
     end
end

def get_opcodes(opcode_data, fname, all_opcode_args_trace)
  # Get the group such as "i" or "c", will generally corrospond to extension
  opcode_group=File.basename(fname).sub("rv_","").sub("rv32_","").sub("rv64_","")
  opcodes=[]
  File.open(fname,"r") do | fin |    
    fin.each_line do | line |
      pseudo_src = nil
      pseudo_op = nil
      next if line =~ /^\s*$/
      next if line =~ /^\#/
      next if line =~ /^\$import\b/
      if line =~ /^\$pseudo_op\s+(\w+)\:\:([\w\.]+)\s/
        line=$'.strip
        pseudo_src = $1
        pseudo_op = $2
      elsif line =~ /^\$/
        print "Unknown command?" + line
        next
      end

      parts = line.split(/\s+/)      
      opcode=parts[0]
      opcode_data[opcode]={"opcode" => parts,
                           "opcode_group" => opcode_group,
                           "opcode_args" => opcode_args(parts, all_opcode_args_trace),
                          }      
      if !pseudo_op.nil?
        opcode_data[opcode]["pseudo_src"] = pseudo_src
        opcode_data[opcode]["pseudo_op"] = pseudo_op
      end
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

            url =  options[:user_manual_path] + "/" + type + ".html"
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
all_opcode_args_trace = {}

get_psuedo(opcode_data,options[:asm_man_path])
OPCODE_FILES.each do |opcode_file|
  groups.merge!(get_opcodes(opcode_data,options[:opcode_path] + "/" + opcode_file, all_opcode_args_trace))
end

opcode_aliases = {}
opcode_data.each_pair do  | opcode, info |
  opcode_alias(opcode_aliases, opcode)
end


USER_ISA_LIST.each do | isa |
  next if isa == "v"
  get_op_desc(options, opcode_data,opcode_aliases,section_labels,isa, options[:user_manual_path])
end
PRIV_ISA_LIST.each do | isa |
  next if isa == "v"
  get_op_desc(options, opcode_data,opcode_aliases,section_labels,isa, options[:priv_manual_path])
end
get_op_desc_fname(options, opcode_data,opcode_aliases,section_labels, "v",options[:vector_manual_path] + "/v-spec.html")

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

def get_isa_sim(sim_path, opcode_info)
  file_name = opcode_info["opcode"][0].downcase().sub(/^c\./,"c_").sub(/\.([a-z])$/,'_\1') + ".h"
  try_file=sim_path + "/"+ file_name
  if File.exist?(try_file)
    File.open(try_file,"r") do | fin|
      sim_text = fin.readlines().map {|x| x.strip}
      opcode_info["iss_code"] = sim_text
    end
  end
end

# REad in the simulator code for each opcode
opcode_data.each_pair do  | opcode, info |
  get_isa_sim(options[:isa_sim_path], info)
end


# Check for unique removal of c. from compressed instructions
opcode_data.each_pair do  | opcode, info |
  if info["opcode"][0][0..1] == "c."
    try_alias = info["opcode"][0][2..-1]
    if !opcode_data.include?(try_alias)
      info["opcode_alias"] = try_alias
    end
  end
end

top_data["opcodes"] = sort_hash(opcode_data)
top_data["groups"] = sort_hash_list(groups)
top_data["sections"] = sort_hash_hash_list(collect_sections(opcode_data))
top_data["sections_labels"] = sort_hash_hash(section_labels)
top_data["isa"] = sort_hash_list(desc)
top_data["opcode_args_to_asm_args"] = OPCODE_TYPES.values
top_data["opcode_args_to_opcodes"] = all_opcode_args_trace


File.open(options[:output_file],"w") do | fout |
  fout.write(top_data.to_yaml)
end

p NEW_OPCODE_TYPES
