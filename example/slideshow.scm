(import (prefix telebot telebot:)
	(chicken process-context)
	(srfi-1)
	(shell))

(define admin "$user_id")
(define sorry "I'm sorry Dave, I'm afraid I can't do that.")
(define greeting "Greetings human. I am a software demon enabling you to control the slideshow displayed on my creator's laptop.")

(define (resolve-query query tree)
  (fold (lambda (x y) (alist-ref x y))
        tree
        query))

(define (make-sender token chat_id)
  (lambda (text)
    (print chat_id " <- \"" text "\"")
    (telebot:sendMessage token
                         chat_id: chat_id
                         text:    text)))

(define (make-slideshow-closure send)
  (let* ((state #f))
    (lambda ()
      (if state
        (begin (set! state #f)
               (run "geeqie --remote --slideshow-stop")
               (send "Slideshow stopped."))
        (begin (set! state #t)
               (run "geeqie --remote --delay=6")
               (run "geeqie --remote --slideshow-start")
               (send "Slideshow started."))))))

(define (make-conversation token chat_id)
  (let* ((chat_id (number->string chat_id))
         (send    (make-sender token chat_id))
         (slideshow (make-slideshow-closure send)))
    (send greeting)
    (lambda (update)
      (let* ((text  (resolve-query '(message text) update)))
        (print chat_id " -> \"" text "\"")
        (if (and (string? text)
                 (string=? chat_id admin))
          (cond ((string=? text "n")     (run "geeqie --remote --next"))
                ((string=? text "p")     (run "geeqie --remote --back"))
                ((string=? text "s")     (slideshow))
                (else                    (send sorry)))
          (send sorry))))))

(let* ((token    (car (command-line-arguments)))
       (converse (telebot:make-conversation-manager token
                                                    make-conversation)))
  (telebot:poll-updates token converse))
