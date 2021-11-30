require "telegram/bot"
require_relative "./database"

module Advent
  class Telegram
    def current_mapping
      @current_mapping ||= {}
    end

    def run
      ::Telegram::Bot::Client.run(ENV.fetch("TELEGRAM_API_TOKEN")) do |bot|
        bot.listen do |message|
          next if message.kind_of?(::Telegram::Bot::Types::ChatMemberUpdated)

          if Array(message.photo).count > 0
            if current_mapping[message.from.id].nil?
              bot.api.send_message(chat_id: message.chat.id, text: "Please write /group [name] to choose the group")
            else
              Database.database[:photos].insert(
                group_id: current_mapping[message.from.id],
                telegramUserId: message.from.id,
                telegramUser: message.from.username,
                file_id: message.photo.last.file_id,
                type: "photo"
              )
              bot.api.send_message(chat_id: message.chat.id, text: "Successfully stored image")
            end
          elsif message.video
            # TODO: implement video support
          elsif message.text.to_s.length > 0
            case message.text
            when '/start'
              bot.api.send_message(chat_id: message.chat.id, text: "Hello, #{message.from.first_name}")
            when '/stop'
              bot.api.send_message(chat_id: message.chat.id, text: "Bye, #{message.from.first_name}")
            when /^\/connect\s+(.+)$/
              group_name = $1.downcase
              
              existing = Database.database[:groups].where(groupName: group_name)
              if existing.count == 0
                bot.api.send_message(chat_id: message.chat.id, text: "Sorry, name doesn't exist")
                next
              end
              if existing.first[:ownerUserId] != message.from.id.to_s
                bot.api.send_message(chat_id: message.chat.id, text: "That is not your group")
                next
              end
              bot.api.send_message(chat_id: message.chat.id, text: "Succesfully connected to this chat")
              existing.update(targetToPostId: message.chat.id)
            when /^\/group\s+(.+)$/
              group_name = $1.downcase
              
              existing = Database.database[:groups].where(groupName: group_name)
              if existing.count > 0
                if existing.first[:ownerUserId] == message.from.id.to_s
                  bot.api.send_message(chat_id: message.chat.id, text: "Group already exists, switched to it. You can upload your 24 photos now")
                  current_mapping[message.from.id] = existing.first[:id]
                else
                  bot.api.send_message(chat_id: message.chat.id, text: "Sorry, name is already taken")
                end
                next
              end

              new_id = Database.database[:groups].insert(
                ownerUser: message.from.username,
                ownerUserId: message.from.id,
                groupName: group_name
              )
              current_mapping[message.from.id] = new_id
              bot.api.send_message(chat_id: message.chat.id, text: "Success, all photos you drag & drop now, will be stored for this group '#{group_name}'")
              bot.api.send_message(chat_id: message.chat.id, text: "To then start sending messages to the group, run /connect '#{group_name}'")
            else
              bot.api.send_message(chat_id: message.chat.id, text: "Sorry #{message.from.first_name}, I did not understand you")
            end
          end
        end
      end
    end
  end
end

if __FILE__ == $0
  Advent::Telegram.new.run
end
