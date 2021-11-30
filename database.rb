require "sequel"

module Advent
  class Database
    def self.database
      @_db ||= Sequel.connect(ENV["DATABASE_URL"])

      unless @_db.table_exists?("groups")
        @_db.create_table(:groups) do
          primary_key :id
          String :ownerUser # KrauseFx
          String :ownerUserId # KrauseFx
          String :groupName # provided by the user MargitAdvent
          String :targetToPostId # MargitAdventGruppe_ID
        end
      end

      unless @_db.table_exists?("photos")
        @_db.create_table(:photos) do
          primary_key :id
          foreign_key :group_id, :groups # foreign key to groups table
          String :telegramUserId # Owner
          String :telegramUser # Owner, e.g. KrauseFx
          String :file_id # file_id of the photo
          String :type # photo or video
        end
      end

      return @_db
    end
  end
end
