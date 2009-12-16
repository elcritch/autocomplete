#!/usr/bin/env ruby
require 'find'
require ENV['TM_SUPPORT_PATH'] + '/lib/escape'
require ENV['TM_SUPPORT_PATH'] + '/lib/exit_codes'
require ENV['TM_SUPPORT_PATH'] + '/lib/ui'

module CTAGS

  # ctags -R --totals --c++-kinds=+pxdl --fields=+iaSzKnl --extra=+q *

  def hidden_ctags(source)
    file = File.basename(source)
    hfile = File.dirname(source)+"/."+file+"_ctag"
    # puts "hidden_ctags: #{source} => #{hfile}"
    return hfile
  end
  
  def list_proj_files(base=".")
    return [] if not FileTest.directory?(base)
    excludes = ["CVS","classes",".svn",".git"]
    source = [".cc",".cpp",".h",".hpp",".c++",".java"]
    
    paths = []
    Find.find(base) do |path|
      if FileTest.directory?(path)
        if excludes.include?( File.basename(path) )
          Find.prune       # Don't look any further into this directory.
        end
      elsif source.include?( File.extname(path) )
        full = File.expand_path(path)
        paths << full
      end
    end
    paths
  end

  def system_ctags(sysdirs,outputdir,force=false)
    #DEPRICATED! Use the shell command instead. This allows user customization more readily
    
    # cmd = "ctags -R --c++-kinds=+pxdl --fields=+iaSzKnl --extra=+q -n -f #{hfile} #{path}"
    # we need to force c++ type on some files
    ctag = e_sh(ENV['TM_BUNDLE_SUPPORT'] + "/bin/ctags") 
    ctag_opts = "--totals -R --c++-kinds=+pxd --fields=+iaSzKnl --extra=+q -n %s -f \"%s\" \"%s\""
    compress = "gzip"
    
    for path,lang in sysdirs do
      lang = "--language-force=#{lang}"
      full = File.expand_path(path)
      # make output filename in system output path
      outfile = File.join(outputdir,File.basename(full)+'_ctags')
      
      # generate ctags file in system path
      if FileTest.directory? path
        if not File.exist? outfile or force
          system(ctag, ctag_opts % [lang, outfile, full] )
          system("gzip",outfile)
        else
          # puts "Warning: not updating system files"
        end
      else
        puts "Warning: System ctags: given path is not directory: #{path}"
      end
    end
  end

  def update_ctags( path, verbose = false )
    files = list_proj_files(path)
    count = 0
    # puts "files #{files.join(' ')}"
    for path in files do
      hfile = hidden_ctags(path)
      if File.exist?(hfile) and File.mtime(hfile)>File.mtime(path)
        # ctags are up to date
        if verbose 
          # puts "hidden_ctags #{File.basename(hfile)} is newer than #{File.basename(path)}"
        end
      else
        # run ctags to update
        ctags = e_sh(ENV['TM_BUNDLE_SUPPORT'] + "/bin/ctags_local")
        ctag_opts = "--c++-kinds=+pxdl --fields=+iaSzKnl --extra=+q -n -f #{e_sh(hfile)} #{e_sh(path)}"
        system(ctags +" "+ ctag_opts)
        count += 1
        if verbose 
          # puts "hidden_ctags #{hfile} has been created"
        end
      end
    end
    
    # puts "Updated #{count}"
  end

  module_function :list_proj_files
  module_function :hidden_ctags
  module_function :system_ctags
  module_function :update_ctags
end 

if __FILE__ == $0
  files = CTAGS::list_proj_files('.')
  CTAGS::update_ctags(files,true)
end

# should update this later to check modtimes and only update if out of date
# result = `ctags -R --totals --c++-kinds=+pxdl --fields=+iaSzKnl --extra=+q *`
# 
# TextMate::exit_show_tool_tip `pwd`
# TextMate::exit_show_tool_tip result


