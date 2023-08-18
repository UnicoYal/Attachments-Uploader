require 'net/imap'
require 'mail'
require 'tempfile'

class AttachmentsUploader
  def self.perform(subject, date)
    files = []
    imap = Net::IMAP.new("imap.gmail.com", 993, true)
    imap.login(ENV["GMAIL"], ENV["PASSWORD_FOR_APP"])

    imap.select("INBOX")

    imap.search(["SUBJECT", subject, "ON", date.strftime("%d-%b-%Y")]).each do |message_id|
      body = imap.fetch(message_id, 'RFC822')[0].attr['RFC822']
      mail = Mail.new(body)

      unless File.exists?("attachments/#{mail.message_id}")
        Dir.mkdir(File.join("attachments", "#{mail.message_id}"), 0700)
      end
      mail.attachments.each do |attachment|
        File.open("attachments/#{mail.message_id}/#{attachment.filename}", 'wb') do |file|
          file.write(attachment.body.decoded)
        end
      end
    end
    rescue StandardError => e
      puts("Error msg: #{e}")
    ensure
      imap.logout
      imap.disconnect
  end
end
