if ARGV.length < 3 then
  puts "ERROR : too few args "
  puts "USAGE: pre-process.rb <infile> <preamble> <outpath>"
  exit(1)
end

infile=ARGV[0]
preamble=ARGV[1..-2]
outpath=ARGV[-1]

@preamble_text = ""
preamble.each do | pfile|
  if File.exists?(pfile)
    @preamble_text += File.open(pfile,"r").read()
  end
end

def create_figure(outpath, infile_base, type,  args, figure_no, lines)
  figure_name = infile_base + "_%02d" % figure_no
  figure_base_path = outpath + "/" +  figure_name
  File.open(figure_base_path + ".tex", "w") do | fig_out |
    fig_out.write("\\documentclass[notitlepage,11pt,openany]{book}\n")
    fig_out.write(@preamble_text)
    fig_out.write("\\begin{document}\n")
    fig_out.write("\\thispagestyle{empty}\n")
    fig_out.write("\\renewcommand{\\familydefault}{\\sfdefault}\n")
    fig_out.write("\\mainmatter\n")
    if type != "" 
      fig_out.write("\\begin{#{type}}#{args}\n")
    end
    # Change Escape {d|l|h ... to other character.
    lines.each { | line |
      if line =~ /(\\\{(?:([a-z])\|)+([a-z])\\\})/
        src=$1
        dst = src.gsub("|",",")
        line.gsub!(src, dst)
      end
    }    
    fig_out.write(lines.join(""))
    fig_out.write("\n")
    if type != "" 
      fig_out.write("\\end{#{type}}\n")
    end
    fig_out.write("\\end{document}\n")
  end
  # -halt-on-error
  cmd1="cd #{outpath}; pdflatex -interaction=nonstopmode #{figure_name}.tex"  
  system(cmd1)
  if $?.exitstatus != 0
    puts("ERROR: cmd1: #{cmd1}")
    exit(1)
  end
  # sudo apt install poppler-utils
  cmd2="cd #{outpath}; pdftocairo -mono -transp -r 130 -singlefile   -png #{figure_name}.pdf #{figure_name}_tmp"
  system(cmd2)
  if $?.exitstatus != 0
    puts("ERROR: cmd2: #{cmd2}")
    exit(1)
  end
  # sudo apt install imagemagick
  cmd3="cd #{outpath}; convert -trim #{figure_name}_tmp.png #{figure_name}.png"
  system(cmd3)
  if $?.exitstatus != 0
    puts("ERROR: cmd3: #{cmd3}")
    exit(1)
  end

  cmd4="cd #{outpath}; pdftocairo -paper match  -svg #{figure_name}.pdf #{figure_name}_tmp.svg"
  system(cmd4)
  if $?.exitstatus != 0
    puts("ERROR: cmd4: #{cmd4}")
    exit(1)
  end

  cmd5="cd #{outpath}; inkscape -o #{figure_name}.svg -D  #{figure_name}_tmp.svg"
  system(cmd5)
  if $?.exitstatus != 0
    puts("ERROR: cmd5: #{cmd5}")
    exit(1)
  end


  return figure_base_path + ".svg"
end
  


def remove_star(line)
  return line.gsub("*}","}")
end

def convert_file(infile, outpath) 
  figure_no=0
  figure_depth=0
  table_depth=0
  table_figure=false
  figure_setup=[]
  in_gdef_setfigfont=false
  figure_lines=[]
  table_lines=[]
  caption_lines=[]
  figure_type=""
  figure_args=""
  in_caption=false
  infile_base=File.basename(infile,".tex")
  File.open(outpath + "/" + infile_base + ".tex","w")  do | fout |
    File.open(infile,"r:UTF-8") do | fin |
      
      lines = fin.readlines

      lines.each_with_index do | line, index |

        line.gsub!("\{figure\*\}","\{figure\}")
        line.gsub!("\{table\*\}","\{table\}")
        line.gsub!(/\s+on\s+page\~\\pageref\{[\w]+\}/,"")
        
        line.gsub!("\\mbox\{\{\\tt hgatp\}.PPN\}","{\\tt hgatp}.PPN")

        # make sure there is a line before commentary
        if line == "\\begin\{commentary\}"
          fout.write("\n")
        end

        if in_gdef_setfigfont
          figure_setup.push(line)
          if line =~ /selectfont\}\s*$/
            in_gdef_setfigfont=false
          end
        elsif (figure_depth + table_depth) == 0 then
          if line =~ /(\\begin\{table\*?\})/ then
            table_depth += 1
            table_lines = [remove_star(line)]
            caption_lines = []
            if lines[index+4] =~ /\\begin\{tabulary\}/ then
              figure_type="table"
              figure_args=$1
              caption_lines = []
              table_figure=true
            else
              table_figure=false
            end
          elsif line =~ /\\begin\{(figure\*?)\}(.*?)$/ then
            figure_depth += 1
            figure_type="figure"
            figure_args=""
            caption_lines = []
            fout.write(remove_star(line))
          elsif line =~ /\\begin\{tabular\}(.*?)$/ then
            figure_depth += 1
            figure_type="tabular"
            figure_args=$1
            caption_lines = []
            fout.write("\\begin{figure}\n")
          elsif line =~ /\s*\\begin\{tabulary\}(.*?)$/ then
            figure_depth += 1
            figure_type="tabulary"
            figure_args=$1
            caption_lines = []
            fout.write("\\begin{figure}\n")
          elsif line =~ /\\gdef\\SetFigFont/
            figure_setup=[line]
            in_gdef_setfigfont=true
          else
            fout.write(line)            
          end
        elsif in_caption then
          caption_lines.push(line)
          if line =~ /}\s*$/ then
            if line.count("}") > line.count("{") 
              in_caption=false
            end
          end
        elsif table_depth == 0 then
          if line =~ /\\begin\{figure\}/ then
            figure_depth += 1
          elsif line =~ /\\begin\{tabular\}/ then
            figure_depth += 1
          elsif line =~ /\s*\\begin\{tabulary\}/ then
            figure_depth += 1
          end

          if line =~ /\\label\{/ then
            caption_lines.push(line)
          elsif line =~ /\\caption\{.*?\}\s*$/ then
            caption_lines.push(line)
          elsif line =~ /\\caption\{/ then
            caption_lines.push(line)
            in_caption=true
          elsif line =~ /\\end\{figure\*?\}/ then
            figure_depth -= 1            
            figure_lines.push(remove_star(line)) if figure_depth > -0
          elsif line =~ /\\end\{tabular\}/ then
            figure_depth -= 1
            figure_lines.push(line) if figure_depth > -0 
          elsif line =~ /\\end\{tabulary\}/ then
            figure_depth -= 1
            figure_lines.push(line) if figure_depth > -0 
          else
            figure_lines.push(line)
          end

          if figure_depth == 0 then
            image_file = create_figure(outpath, infile_base, figure_type, figure_args, figure_no, figure_lines)
            fout.write("\\includegraphics[width=\\linewidth]{#{image_file}}\n")
            fout.write(caption_lines.join(""))
            fout.write("\\end{figure}\n")
            fout.flush()
            figure_no+=1
            figure_lines=[]
          end

        else

          if line =~ /\\begin\{table\*?\}/ then
            table_lines.push(remove_star(line))
            table_depth += 1
          elsif line =~ /\\end\{table\*?\}/ then
            table_lines.push(remove_star(line))
            table_depth -= 1
          elsif line =~ /\\label\{/ then
            caption_lines.push(line)
          elsif line =~ /\\caption\{.*?\}\s*$/ then
            caption_lines.push(line)
          elsif line =~ /\\caption\{/ then
            caption_lines.push(line)
            in_caption=true
          elsif line =~ /\\multi(row|column)/ then
            table_lines.push(line)
            table_figure=true
          else
            table_lines.push(line)            
          end

          if table_depth == 0
            if table_figure
              fout.write("\\begin{figure}\n")
              figure_type=""
              figure_args=""
              image_file = create_figure(outpath, infile_base, figure_type, figure_args, figure_no, table_lines)
              figure_no+=1
              fout.write("\\includegraphics[width=\\linewidth]{#{image_file}}\n")
              fout.write(caption_lines.join(""))
              fout.write("\\end{figure}\n")
            else
              fout.write(table_lines.join(""))
              fout.write(caption_lines.join(""))
            end
          end
          
        end 
      end # lines
    end # fin
  end # fout
end

convert_file(infile, outpath)
  
