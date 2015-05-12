# Slightly modified Sufia's BatchUpdateJob
class KarkinosBatchUpdateJob
  include Hydra::PermissionsQuery
  include Sufia::Messages

  def queue_name
    :batch_update
  end

  attr_accessor :login, :title, :file_attributes, :batch_id, :visibility, :saved, :denied, :creation
  
  def initialize(login, batch_id, title, file_attributes, visibility)
    self.login = login
    self.title = title || {}
    self.file_attributes = file_attributes
    self.visibility = visibility
    self.batch_id = batch_id
    self.saved = []
    self.denied = []
  end

  def run
    batch = Batch.find_or_create(self.batch_id)
    user = User.find_by_user_key(self.login)

    batch.generic_files.each do |gf|
      update_file(gf, user)
    end
    batch.update(status: ["Complete"])

    if denied.empty?
      send_user_success_message(user, batch) unless saved.empty?
    else
      send_user_failure_message(user, batch)
    end
  end

  def update_file(gf, user)
    unless user.can? :edit, gf
      ActiveFedora::Base.logger.error "User #{user.user_key} DENIED access to #{gf.id}!"
      denied << gf
      return
    end
    title_ids = gf.title_principal_ids
    
    gf.title = title[gf.id] if title[gf.id]
    #gf.title_principals.first.label = title[gf.title]
    labels ={}
    puts "============= labels ========"
    gf.title_principals.each_with_index do |ti, index|
      puts title[gf.id]
      labels["#{index}"] = {"label" => title[gf.id].first, "id" => ti.id}
      puts labels
    end
    puts "+++++++++++++++++++"
    puts labels
    #file_attributes["title_principals_attributes"] = labels
    puts file_attributes
    gf.attributes = file_attributes
    puts "durch"
    gf.visibility= visibility
    
    #temporary addition for development
    gf.title_principal_ids = title_ids
    
    if @creation
      gf.data_files.each do |df|
        df.resource_type = gf.resource_type
        df.rights = gf.rights
      end
    end

    save_tries = 0
    begin
      gf.save!
      if @creation
        gf.data_files.each do |df|
          df.save!
        end
      end
    rescue RSolr::Error::Http => error
      save_tries += 1
      ActiveFedora::Base.logger.warn "BatchUpdateJob caught RSOLR error on #{gf.id}: #{error.inspect}"
      # fail for good if the tries is greater than 3
      raise error if save_tries >=3
      sleep 0.01
      retry
    end #
    Sufia.queue.push(ContentUpdateEventJob.new(gf.id, login))
    saved << gf
  end

  def send_user_success_message user, batch
    message = saved.count > 1 ? multiple_success(batch.id, saved) : single_success(batch.id, saved.first)
    User.batchuser.send_message(user, message, success_subject, sanitize_text = false)
  end

  def send_user_failure_message user, batch
    message = denied.count > 1 ? multiple_failure(batch.id, denied) : single_failure(batch.id, denied.first)
    User.batchuser.send_message(user, message, failure_subject, sanitize_text = false)
  end
end