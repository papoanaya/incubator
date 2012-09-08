;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; MODULE      : init-plantuml.scm
;; DESCRIPTION : Initialize GNUplot plugin
;; COPYRIGHT   : (C) 1999  Joris van der Hoeven
;;
;; This software falls under the GNU general public license version 3 or later.
;; It comes WITHOUT ANY WARRANTY WHATSOEVER. For details, see the file LICENSE
;; in the root directory or <http://www.gnu.org/licenses/gpl-3.0.html>.
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(define (plantuml-initialize)
  (import-from (utils plugins plugin-convert))
  (lazy-input-converter (plantuml-input) plantuml))

(define (plantuml-serialize lan t)
  (import-from (utils plugins plugin-cmd))
  (with u (pre-serialize lan t)
    (with s (texmacs->code u)
      (string-append (escape-verbatim (string-replace s "\n" "~")) "\n"))))
;;  (:scripts "Plantuml)
;;  (:initialize (plantuml-initialize))
(plugin-configure plantuml
  (:require #t )
  (:launch "newlisp c:/users/luis/plantuml/bin/goplantuml.nlsp")
  (:serializer ,plantuml-serialize)
  (:session "Plantuml")
)

