#!/usr/bin/env newlisp
# write gnuplot-commands within the input line, 
# use as many commands as necessary, 
# divide them by the ~ chararacter, because the ENTER key terminates the input and sends it to gnuplot.
# output is the graph made by gnuplot.
# this version is to be used with newlisp and windows

;; (if (!= (nth 1 (main-args) ) "--texmacs" )
;;     (begin
;;       (println "tm_gnuplot. Script should be started only from TeXmacs")
;;       (exit 1)))

# control characters

# defining pipe-gnuplot binary path and name 
# for unix/linux environments
#GNUPLOT_PATH=
#PIPE_GNUPLOT=gnuplot
# for windows/cygwin environment

(setq GNUPLOT_PATH "c:/Program Files (x86)/Maxima-5.26.0/gnuplot/")
(setq PIPE_GNUPLOT "pgnuplot.exe")

# GNUPLOT_PATH=/cygdrive/w/tex_cd/programme/gnuplot/
#  PIPE_GNUPLOT=pgnuplot.exe

# defining temporary postscript file directory
(setq TMPDIR (or (env "TMPDIR") "."))

(if (not (directory TMPDIR))
    (make-dir TMPDIR))

(setq TEMP_PS_NAME "temp.eps")

# standard initialization of GNUplot
(setq init (format "reset\nset terminal postscript eps enhanced \nset output \"%s/%s\"\nset size 1,1\nset autoscale\n" TMPDIR TEMP_PS_NAME))
;;init='reset~set terminal postscript eps enhanced ~set output "'$TEMP_DIR$TEMP_PS_NAME'"~set size 1,1~set autoscale~'
	
# startup banner

(setq DATA_BEGIN "\002")
(setq DATA_END "\005")
(setq DATA_ESCAPE "\027")

(print DATA_BEGIN)
(print "verbatim:This is a TeXmacs interface for GNUplot.")

# prompt-input-gnuplot-output loop
(while true
       (begin 
         (print DATA_BEGIN)
         (print "channel:prompt")
         (print DATA_END)
         (print "GNUPLOT]")
         (print DATA_END)        
         (setq input (read-line))
         (setq input (string init input))
         (write-file (string TMPDIR "/" "temp.gp") input)
         (! (format "%s %s" PIPE_GNUPLOT (string TMPDIR "/temp.gp")))
         (print DATA_BEGIN)
         (print "verbatim:")
         (print DATA_BEGIN)
         (print "ps:")
         (print (read-file (format "%s/%s" TMPDIR TEMP_PS_NAME)))
         (print DATA_END)
         (delete-file (format "%s/%s" TMPDIR TEMP_PS_NAME))
         (delete-file (format "%s/%s" TMPDIR TEMP_PS_NAME))))

(exit)
