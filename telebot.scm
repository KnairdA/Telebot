(module telebot (;;; basic API wrappers
		 get-me
		 get-updates
		 send-message
		 forward-message
		 send-photo
		 send-audio
		 send-document
		 send-sticker
		 send-video
		 send-voice
		 send-location
		 send-venue
		 send-contact
		 send-chat-action
		 get-user-profile-photos
		 get-file
		 kick-chat-member
		 unban-chat-member
		 answer-callback-query
		 edit-message-text
		 edit-message-caption
		 edit-message-reply-markup
		 answer-inline-query
                 ;;; framework
                 message?
		 edited-message?
                 inline-query?
		 callback-query?
                 chosen-inline-result?
		 text?
		 location?
		 resolve-query
                 poll-updates
                 make-conversation-manager)
  
  (import scheme (chicken base)
	         (chicken condition))
  (import srfi-1
          srfi-69)
  (import openssl
          http-client)
  (import medea
          (only srfi-133 vector-for-each))

  (define-constant api-base "https://api.telegram.org/bot")

  ;;; helper functions

  (define (get-query-url token method)
    (string-append api-base token "/" method))

  (define (clean-query-parameters parameters)
    (let ((cleaned-parameters (remove (lambda (p) (equal? #f (cdr p)))
                                      parameters)))
      (if (null-list? cleaned-parameters)
        #f
        cleaned-parameters)))

  (define (resolve-query query tree)
    (fold (lambda (x y) (alist-ref x y eqv? '()))
          tree
          query))

  ;;; plain API wrappers, returning deserialized JSON

  (define-syntax wrap-api-method
    (syntax-rules (required optional)
    ((wrap-api-method method scm-name
                      (required required_params ...)
                      (optional optional_params ...))
     (define (scm-name token
                     #!key required_params ...
                           optional_params ...)
       (if (any (lambda (x) (equal? #f x))
                (list required_params ...))
         (abort 'required-parameter-missing)
         (with-input-from-request
           (get-query-url token method)
           (clean-query-parameters
             (map (lambda (l) (cons (first l) (second l)))
                  (zip '(required_params ... optional_params ...)
                       (list required_params ... optional_params ...))))
           read-json))))))

  (wrap-api-method "getMe" get-me (required) (optional))

  (wrap-api-method "getUpdates"
		   get-updates
                   (required)
                   (optional offset
                             limit
                             timeout))

  (wrap-api-method "sendMessage"
		   send-message
                   (required chat_id
                             text)
                   (optional parse_mode
                             disable_web_page_preview
                             disable_notification
                             reply_to_message_id
                             reply_markup))

  (wrap-api-method "forwardMessage"
		   forward-message
                   (required chat_id
                             from_chat_id
                             message_id)
                   (optional disable_notification))

  (wrap-api-method "sendPhoto"
		   send-photo
                   (required chat_id
                             photo)
                   (optional caption
                             disable_notification
                             reply_to_message_id
                             reply_markup))

  (wrap-api-method "sendAudio"
		   send-audio
                   (required chat_id
                             audio)
                   (optional duration
                             performer
                             title
                             disable_notification
                             reply_to_message_id
                             reply_markup))

  (wrap-api-method "sendDocument"
		   send-document
                   (required chat_id
                             document)
                   (optional caption
                             disable_notification
                             reply_to_message_id
                             reply_markup))

  (wrap-api-method "sendSticker"
		   send-sticker
                   (required chat_id
                             sticker)
                   (optional disable_notification
                             reply_to_message_id
                             reply_markup))

  (wrap-api-method "sendVideo"
		   send-video
                   (required chat_id
                             video)
                   (optional duration
                             width
                             height
                             caption
                             disable_notification
                             reply_to_message_id
                             reply_markup))

  (wrap-api-method "sendVoice"
		   send-voice
                   (required chat_id
                             voice)
                   (optional duration
                             disable_notification
                             reply_to_message_id
                             reply_markup))

  (wrap-api-method "sendLocation"
		   send-location
                   (required chat_id
                             latitude
                             longitude)
                   (optional disable_notification
                             reply_to_message_id
                             reply_markup))

  (wrap-api-method "sendVenue"
		   send-venue
                   (required chat_id
                             latitude
                             longitude
                             title
                             address)
                   (optional foursquare_id
                             disable_notification
                             reply_to_message_id
                             reply_markup))

  (wrap-api-method "sendContact"
		   send-contact
                   (required chat_id
                             phone_number
                             first_name)
                   (optional last_name
                             disable_notification
                             reply_to_message_id
                             reply_markup))

  (wrap-api-method "sendChatAction"
		   send-chat-action
                   (required chat_id
                             action)
                   (optional))

  (wrap-api-method "getUserProfilePhotos"
		   get-user-profile-photos
                   (required user_id)
                   (optional offset
                             limit))

  (wrap-api-method "getFile"
		   get-file
                   (required file_id)
                   (optional))

  (wrap-api-method "kickChatMember"
		   kick-chat-member
                   (required chat_id
                             user_id)
                   (optional))

  (wrap-api-method "unbanChatMember"
		   unban-chat-member
                   (required chat_id
                             user_id)
                   (optional))

  (wrap-api-method "answerCallbackQuery"
		   answer-callback-query
                   (required callback_query_id)
                   (optional text
                             show_alert))

  (wrap-api-method "editMessageText"
		   edit-message-text
                   (required text)
                   (optional chat_id
                             message_id
                             inline_message_id
                             parse_mode
                             disable_web_page_preview
                             reply_markup))

  (wrap-api-method "editMessageCaption"
		   edit-message-caption
                   (required)
                   (optional chat_id
                             message_id
                             inline_message_id
                             caption
                             reply_markup))

  (wrap-api-method "editMessageReplyMarkup"
		   edit-message-reply-markup
                   (required)
                   (optional chat_id
                             message_id
                             inline_message_id
                             reply_markup))

  (wrap-api-method "answerInlineQuery"
		   answer-inline-query
                   (required inline_query_id
                             results)
                   (optional cache_time
                             is_personal
                             next_offset))

  ;;; framework
  (define (is-update-type? type update)
    (not (equal? '() (resolve-query type update))))

  (define (update-predicate types)
    (lambda (update)
      (any (lambda (type) (is-update-type? type update)) types)))

  (define message?              (update-predicate '((message) (edited_message)) ))
  (define edited-message?       (update-predicate '((edited_message)) ))
  (define inline-query?         (update-predicate '((inline_query)) ))
  (define callback-query?       (update-predicate '((callback_query)) ))
  (define chosen-inline-result? (update-predicate '((chosen_inline_result)) ))

  (define text?                 (update-predicate '((message text) (edited_message text)) ))
  (define location?             (update-predicate '((message location) (edited_message location)) ))

  (define (poll-updates token handler)
    (let ((offset 0))
      (let loop ()
        (vector-for-each (lambda (u)
                           (handler u)
                           (set! offset (+ 1 (alist-ref 'update_id u))))
                         (alist-ref 'result
                                    (get-updates token
                                                offset:  offset
                                                timeout: 60)))
	
	(loop))))

  (define (make-conversation-manager token make-handler)
    (let ((token         token)
          (conversations (make-hash-table)))
      (lambda (update)
        (if (message? update)
          (let ((chat_id (resolve-query '(message from id) update)))
            (if (hash-table-exists? conversations chat_id)
              ((hash-table-ref conversations chat_id) update)
              (hash-table-set! conversations
                               chat_id
                               (make-handler token chat_id))))))))
)
