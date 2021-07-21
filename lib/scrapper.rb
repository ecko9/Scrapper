require 'bundler'
Bundler.require

Dotenv.load('.env')

########################################
########################################
####### CLASSE
class ScrapperValOise

  #attr_accessor :var, :var2

  ########################################
  def initialize()
    perform
  end


  ########################################
  ####### MAILS VAL OISE
  def val_oise
    doc = Nokogiri::HTML(URI.open("http://annuaire-des-mairies.com/val-d-oise.html"))
    tableau_mairies = []
    tableau_liens = []
    tableau_mails = []
    doc.css('td > p > a.lientxt').each do |lien|
      tableau_mairies.push(lien.text)
      link_name = "http://annuaire-des-mairies.com" + lien[@class="href"][1, 10000]
      doc2 = Nokogiri::HTML(URI.open(link_name))
      doc2.css('body > div > main > section:nth-child(2) > div > table > tbody > tr:nth-child(4) > td:nth-child(2)').each do |mail|
        tableau_mails.push(mail.text)
      end    
    end
    hash = Hash[]
    hash = tableau_mairies.zip(tableau_mails).map {|k, v| {k => v}}
    return hash
  end


  ########################################
  ####### SAUVEGARDER DANS UN FICHIER JSON 
  def save_as_json(hash)
    my_json = JSON.generate(hash)
    file = File.open("./db/emails.JSON", "w")
    file.puts(my_json)
    file.close
  end


  ########################################
  ####### SAUVEGARDER SUR GOOGLE_DRIVE 
  def save_as_spreadsheets(hash)
    create_json
    session = GoogleDrive::Session.from_config("config.json")
    ws = session.spreadsheet_by_url("https://docs.google.com/spreadsheets/d/1DY5pUAGLHsn52cS5LbAUZmlPRXW6OZ_90mCkInXd9eA/edit?usp=sharing").worksheets[0]
    ws[1, 1] = "MAIRIE"
    ws[1, 2] = "MAIL"
    ligne = 2
    hash.each do |hash2|
      hash2.each do |k, v|
        ws[ligne, 1] = k.to_s
        ws[ligne, 2] = v.to_s
      end
      ligne += 1
    end
    ws.save
  end

  ########################################
  ####### CREER CONFIG.JSON
  def create_json
    hash = Hash[client_id: ENV["CLIENT_ID"], client_secret: ENV["CLIENT_SECRET"]]
    my_json = JSON.generate(hash)
    file = File.open("./config.JSON", "w")
    file.puts(my_json)
    file.close
  end


  ########################################
  ####### SAUVEGARDER DANS UN FICHIER JSON 
  def save_as_csv(hash)
    file = CSV.open("./db/emails.csv", "wb") do |csv|
      hash.each do |hash2|
        hash2.each do |k, v|
          csv << [k.to_s, v.to_s]
        end
      end
    end
  end


  ########################################
  ####### PERFORM
  def perform
    mairies_mails = val_oise
    save_as_json(mairies_mails)
    save_as_spreadsheets(mairies_mails)
    save_as_csv(mairies_mails)
  end


end


