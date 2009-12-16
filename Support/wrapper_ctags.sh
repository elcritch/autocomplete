#!/bin/zsh


# System ctags generation. Force the language and exclude local vars
# args:
if [[ ${#argv} < 2 ]]; then
  print "Usage: wrapper_ctags.sh lang <loc1> <loc2> ..."
fi

#add the ctags to the path, for ease
PATH=$TM_BUNDLE_SUPPORT"/bin/":$PATH

lang=$argv[1]
argv[1]=''

rm -v "$TM_BUNDLE_SUPPORT/SystemTags/${lang:u}/*"

for dir in $argv; do
  #loop through given list of system directories with a given language
  if [[ -d $dir ]]; then
    #setup
    print "Working on $dir"
    name=$dir:t
    out=$TM_BUNDLE_SUPPORT/SystemTags/${lang:u}/${name}_ctags
    
    #make the ctags output file for the given system path
    ctags_local --totals -R --c++-kinds=+pxd --fields=+iaSzKnl --extra=+q -n \
      --language-force=$lang -f $out $dir
    
    if [[ $? != 0 ]]; then
      rm $out
      exit 1;
    fi;
    
    cat $out | grep -v 'access:protected' | grep -v 'access:private' > ${out}.1
    mv ${out}.1 $out
    #gzip it and delete the 
    gzip -fn $out
    
    #anything else???
    #future: split resulting tag in a,b,c,d... based on package name 
    #to reduce search time
    
  else
    print "Not a directory: $dir"
  fi

done  
