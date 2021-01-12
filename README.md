# Telebot

... is a basic _Chicken Scheme_ module to ease the development of bots interfacing with the [Telegram Bot API](https://core.telegram.org/bots/api).

In this context _basic_ means that the module currently consists primarily of raw HTTP API calls hidden behind analogously named functions and JSON deserialization provided by the _http-client_ respectively _medea_ eggs.

The maintanance of these API wrappers is simplified by an appropriate _Scheme_ macro that reduces the implementation of new API methods to basically slightly rewriting the documentation.

To simplify the implementation of bots a set of framework functions implementing common usage patterns is provided.

## Example

`example/echo.scm` implements a bot that echoes all messages back to their sender.

`example/guess.scm` implements a simple number guessing game.

## Documentation

All _basic_ API wrappers are named the same as their method name and require the bot's token as their first argument. Further parameters are expected as named key value pairs. Note that the library currently only verifies that all required parameters are supplied at all while type verification is left to _Telegram's_ server side logic.

	(sendMessage token
	             chat_id: chat_id
	             text:    text)

All API wrappers return the raw deserialized JSON results as to not limit the options for further parsing unnecessarily.

One framework function provided by this library is `poll-updates` which enables passing updates acquired via long polling of `getUpdates` to an arbitrary function as follows:

	(poll-updates token
	              (lambda (u)
	                (begin (print-message u)
	                       (echo-message  u))))

The common pattern of managing user specific conversations is supported via `make-conversation-manager`. This procedure instantiates a closure to be passed to e.g. `poll-updates` using a given token and _conversation handler_. All updates are then automatically distributed to an appropriate _conversation handler_ that may in turn be a closure maintaining conversation-specific state. `example/guess.scm` implements a practical bot based on this pattern.

### Implemented API methods

Based on the official [documentation](https://core.telegram.org/bots/api#available-methods).

* getMe
* getUpdates
* sendMessage
* forwardMessage
* sendPhoto
* sendAudio
* sendDocument
* sendSticker
* sendVideo
* sendVoice
* sendLocation
* sendVenue
* sendContact
* sendChatAction
* getUserProfilePhotos
* getFile
* kickChatMember
* unbanChatMember
* answerCallbackQuery
* editMessageText
* editMessageCaption
* editMessageReplyMarkup
* answerInlineQuery

The only missing method is `setWebhook` as this kind of interfacing with _Telegram_ is currently out of scope of this library. Should this be required an appropriate wrapper may be easily generated using the `wrap-api-method` macro described by the module.

## Build

	git clone https://github.com/KnairdA/Telebot.git
	cd Telebot
	chicken-install -s

## Dependencies

* [openssl](http://wiki.call-cc.org/eggref/4/openssl)
* [http-client](http://wiki.call-cc.org/eggref/4/http-client)
* [medea](http://wiki.call-cc.org/eggref/4/medea)
* [loops](http://wiki.call-cc.org/eggref/4/loops)
