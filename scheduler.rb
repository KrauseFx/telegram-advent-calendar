require_relative "./database.rb"
require "telegram/bot"
require 'date'

if Date.today.month == 12 && Date.today.day < 25
  day_to_use = Date.today.day
else
  exit
end

::Telegram::Bot::Client.run(ENV.fetch("TELEGRAM_API_TOKEN")) do |bot|
  Advent::Database.database[:groups].exclude(targetToPostId: nil).each do |group|
    todays_photo = Advent::Database.database[:photos].where(group_id: group[:id]).order(:id).to_a[day_to_use - 1]

    bot.api.send_message(chat_id: group[:targetToPostId], text: "🕯 #{day_to_use}. Dezember #{Date.today.year}")
    bot.api.send_photo(
      chat_id: group[:targetToPostId], 
      photo: todays_photo[:file_id]
    )
  end
end
