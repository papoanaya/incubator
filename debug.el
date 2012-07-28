(if (null mantis-wsdl)
    (let ()
      (mantis-load-wsdl) )
  (message "%s "   (mantis-get-projects "papo" "petra1!") )
  (message "%s" (mantis-get-issue "papo" "petra1!" 1))  

  (message "%s" (mantis-get-resolutions "papo" "petra1!")) )

(message "%s" (mantis-get-version))
(message "%s "   (mantis-get-projects "papo" "petra1!") )
(message "%s" (mantis-get-enum-status "papo" "petra1!"))
(message "%s" (mantis-get-issue "papo" "petra1!" 6))  
(message "%s" (mantis-get-comments "papo" "petra1!" 6)) 
(message "%s" (mantis-create-issue "papo" "petra1!" 
                                   "test ticket" "test description" 
                                   "Development"
                                   (list 'project 
                                         (cons 'id  1 ) 
                                         (cons 'name  "Automated Document Creation"))
                                        ; returns issue number
                                   ))

(message "%s" (mantis-add-comment "papo" "petra1!" 6 "Another note from emacs lisp v3")) ; returns comment number

(message "%s" (mantis-get-project-id  "papo" "petra1!" "Automated Document Creation") ) 

(message "%s" (mantis-create-issue "papo" "petra1!" 
                                   "test ticket2 " "test description2 " 
                                   "Development"
                                   "House Projects"))


(dotimes (n 3)
  (message "%s" (mantis-get-project-issues "papo" "petra1!" 1 (+ 1 n ))) )