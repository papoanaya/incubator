# write gnuplot-commands within the input line, 
# use as many commands as necessary, 
# divide them by the ~ chararacter, because the ENTER key terminates the input and sends it to gnuplot.
# output is the graph made by gnuplot.

;; (if (!= (nth 1 (main-args) ) "--texmacs" )
;;     (begin
;;       (println "tm_gnuplot. Script should be started only from TeXmacs")
;;       (exit 1)))

# control characters
#tmp=`$ECHO DATA_BEGIN=X DATA_END=Y DATA_ESCAPE=Z | tr "XYZ" "\002\005\027" `
#eval $tmp

# defining pipe-gnuplot binary path and name 
# for unix/linux environments
#GNUPLOT_PATH=
#PIPE_GNUPLOT=gnuplot
# for windows/cygwin environment

(setq EUKLEIDES_PATH "")
(setq PIPE_EUKLEIDES "eukleides")

# EUKLEIDES_PATH=/cygdrive/w/tex_cd/programme/gnuplot/
#  PIPE_EUKLEIDES=pgnuplot.exe

# defining temporary postscript file directory
(setq TMPDIR ".")

(if (not (directory TMPDIR))
    (make-dir TMPDIR))

(setq TEMP_FILE "euktmp")
	
# startup banner
#tmp=`$ECHO DATA_BEGIN=X DATA_END=Y DATA_ESCAPE=Z | tr "XYZ" "\002\005\027" `

(setq DATA_BEGIN "\002")
(setq DATA_END "\005")
(setq DATA_ESCAPE "\027")

(print DATA_BEGIN)
(print "latex:'$E \Upsilon K \Lambda \tmop{EI} \Delta H \Sigma$'")
(println DATA_END)
(print DATA_BEGIN)
(println "verbatim:A Euclidean Geometry Drawing Language")
(println "1. Angles are followed by \"\:\" \for degrees and \"\<\" \for radians.")
(println "2. Use \"\%\" to comment a line.")

# prompt-input-gnuplot-output loop
(while true
       (begin 
         (print DATA_BEGIN)
         (print "channel:prompt")
         (print DATA_END)
         (print "EUKLEIDES]")
         (print DATA_END)        
         (setq input (read-line))
         (setq input (replace "~" input "\n"))
         (write-file (string TMPDIR "/" TEMP_FILE ".euk") input)
         
         ;; (! (format "%s %s/%s.euk >> %s/%s.eps 2>%s %s.err" 
         ;;            PIPE_EUKLEIDES 
         ;;            TMPDIR TEMP_FILE TMPDIR TEMP_FILE TMPDIR TEMP_FILE))

          (! (format "%s --output=%s/%s.eps %s/%s.euk" 
                     PIPE_EUKLEIDES 
                     TMPDIR TEMP_FILE 
                     TMPDIR TEMP_FILE ))
          
          (if (file? (string TMPDIR "/" TEMP_FILE ".err"))
             (begin
               (print DATA_BEGIN)
               (print "verbatim:")
               (print (read-file (format "%s/%s.err" TMPDIR TEMP_FILE)))
               (print "ps:")
               (print DATA_END)
               (println))
             (begin
               (print DATA_BEGIN)
               (print "verbatim:")
               (print DATA_BEGIN)
               (print "ps:")
               (print (read-file (format "%s/%s.eps" TMPDIR TEMP_FILE)))
               (print DATA_END)))

;;         (delete-file (format "%s/%s.euk" TMPDIR TEMP_FILE))
;;         (delete-file (format "%s/%s.eps" TMPDIR TEMP_FILE))  
;;         (delete-file (format "%s/%s.err" TMPDIR TEMP_FILE))
         ))

(exit)