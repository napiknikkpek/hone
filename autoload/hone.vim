let s:compile_commands_dict = {}

fu! s:compile_flags_set_options(file, config) abort
  let &l:makeprg = join(["clang++"] + readfile(a:config) + [a:file])
endfu

fu! s:generate_compile_commands_map(file) abort
  let dict = {}
  for elem in json_decode(readfile(a:file))
    let dict[elem.file] = {
          \ 'command': elem.command,
          \ 'directory': elem.directory} 
  endfor
  return dict
endfu

fu! s:compile_commands_set_options(file, config) abort
  if !has_key(a:config, a:file)
    return
  endif
  let entry = a:config[a:file]
  let &l:makeprg = printf("cd %s && %s", entry.directory, entry.command)
endfu

fu! hone#update_win_options() abort
  let file = findfile('compile_commands.json', expand('%:p:h').';')
  if empty(file)
    let file = findfile('compile_flags.txt', expand('%:p:h').';')
    if empty(file)
      return
    endif
    let file = fnamemodify(file, ':p')
    call s:compile_flags_set_options(expand('%:p'), file)
  else
    let file = fnamemodify(file, ':p')
    if !has_key(s:compile_commands_dict, file)
      let s:compile_commands_dict[file] = s:generate_compile_commands_map(file)
    endif
    call s:compile_commands_set_options(expand('%:p'), 
          \ s:compile_commands_dict[file])
  endif
endfu

