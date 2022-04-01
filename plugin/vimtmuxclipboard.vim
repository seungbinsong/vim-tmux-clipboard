func! s:TmuxBufferName()
    let l:list = systemlist('tmux list-buffers -F"#{buffer_name}"')
    if len(l:list)==0
        return ""
    else
        return l:list[0]
    endif
endfunc

func! s:TmuxBuffer()
    return system('tmux show-buffer')
endfunc

func! s:YankToTmuxBuffer()
    call system('tmux loadb -b buffer0 - ',getregtype('"'))
    call system('tmux loadb - ',join(v:event["regcontents"],"\n"))
endfunc

func! s:YankToTmuxBufferOld()
    call system('tmux loadb -b buffer0 - ',getregtype('"'))
    call system('tmux loadb - ',@")
endfunc

func! s:StartsWith(longer, shorter) abort
  return a:longer[0:len(a:shorter)-1] ==# a:shorter
endfunction

func! s:GetRegType()
    let type = system('tmux show-buffer -b buffer0')
    if ((type == "v") || (type == "V") || s:StartsWith(type,0x16))
      return type
    elseif
      return ""
    endif
endfunc


func! s:Enable()

    if $TMUX=='' 
        " not in tmux session
        return
    endif

    let s:lastbname=""

    " if support TextYankPost
    if exists('##TextYankPost')==1
        " @"
        augroup vimtmuxclipboard
            autocmd!
            autocmd FocusLost * call s:update_from_tmux()
            autocmd	FocusGained   * call s:update_from_tmux()
            autocmd TextYankPost * silent! call s:YankToTmuxBuffer()
        augroup END
        call setreg('"',s:TmuxBuffer(),s:GetRegType())
    else
        " vim doesn't support TextYankPost event
        " This is a workaround for vim
        augroup vimtmuxclipboard
            autocmd!
            autocmd FocusLost     *  silent! call s:YankToTmuxBufferOld()
            autocmd	FocusGained   *  call setreg('"',s:TmuxBuffer(),s:GetRegType())
        augroup END
        call setreg('"',s:TmuxBuffer(),s:GetRegType())
    endif

endfunc

func! s:update_from_tmux()
    let buffer_name = s:TmuxBufferName()
    if s:lastbname != buffer_name
        call setreg('"',s:TmuxBuffer(),s:GetRegType())
    endif
    let s:lastbname=s:TmuxBufferName()
endfunc

call s:Enable()

" " workaround for this bug
" if shellescape("\n")=="'\\\n'"
" 	let l:s=substitute(l:s,'\\\n',"\n","g")
" 	let g:tmp_s=substitute(l:s,'\\\n',"\n","g")
" 	");
" 	let g:tmp_cmd='tmux set-buffer ' . l:s
" endif
" silent! call system('tmux loadb -',l:s)
