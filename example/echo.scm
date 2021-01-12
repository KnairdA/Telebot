(import (prefix telebot telebot:)
	(chicken process-context))

(define token (cadr (command-line-arguments)))

(define (print-message msg)
  (print (telebot:resolve-query '(message from first_name) msg)
         ": "
         (telebot:resolve-query '(message text) msg)
         " ("
         (telebot:resolve-query '(update_id) msg)
         ")"))

(define (echo-message msg)
  (let ((chat_id    (telebot:resolve-query '(message from id) msg))
        (text       (telebot:resolve-query '(message text)    msg)))
    (telebot:send-message token
                         chat_id: chat_id
                         text:    text)))

(telebot:poll-updates token
                      (lambda (u)
                        (if (telebot:message? u)
                          (begin (print-message u)
                                 (echo-message  u)))))
