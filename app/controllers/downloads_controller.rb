class DownloadsController < ApplicationController
  include Sufia::DownloadsControllerBehavior
  
  def authorize_download!
    #authorize! :download, file
  end
  def send_file_contents
        self.status = 200
        byebug
        prepare_file_headers
        if file.instance_of? Tempfile
          fd = IO.sysopen(file.path, 'r')
          datastream = IO.read(fd)
        elsif
          datastream = file.stream
        end
        stream_body datastream
  end    
  def show
    print "inside show++++++++++++++"
    if file.instance_of? ZipFile
      return send_content
    end
    if file.new_record?
      render_404
    else
      send_content
    end
  end
  def stream_body(iostream)
    print "inside stream_body++++++++"
    iostream.each do |in_buff|
      response.stream.write in_buff
    end
    print response.stream
  ensure
    response.stream.close
  end
  def send_content
    print "inside send_content +++++++++++++++"
      response.headers['Accept-Ranges'] = 'bytes'

      if request.head?
        content_head
      elsif request.headers['HTTP_RANGE']
        send_range
      else
        print "headerssssssssssssssssss"
        print request.headers
        send_file_contents
        
      end
   end  
  def load_file
    file_path = params[:file] #why??
    
    print "testeing +++++++++++++++++++++++++"
    print params
    file = GenericFile.find(params[:id]);
    f = nil
    #if file.instance_of? GenericFile and not file.resource_type.include? 'DataFile'
    #  file = file.data_files.first
    #end
    
    if !file_path && params[:datastream_id]
      Deprecation.warn(DownloadBehavior, "Parameter `datastream_id` is deprecated and will be removed in hydra-head 10.0. Use `file` instead.")
      file_path = params[:datastream_id]
    end
    if file.instance_of? DataFile
      return super
      #f = asset.attached_files[file_path] if file_path
      #f ||= default_file 
    end
    
    if file.instance_of? GenericFile
        f = ZipFile.new(file.id + ".zip")
        zip = Zip::OutputStream.open(f) 
        zip.write_buffer do | z |
          file.data_files.each do | data_file_obj |
            print "******* Data File"
            data_file = fetch_file data_file_obj.id
            #f.get_output_stream(data_file_obj.filename.first) { |d| d.puts data_file }
            z.put_next_entry(data_file_obj.filename.first)
            #print data_file
            z << data_file
            #print data_file
          end
        end
        zip.close
     end 
    
    raise "Unable to find a file for #{params[:id]}" if f.nil?
    print "return ============"
    print f
    f
  end
  def fetch_file(id) 
    dfile = ActiveFedora::Base.find(id)  
    if asset.class.respond_to?(:default_file_path)
      asset.attached_files[asset.class.default_file_path]
    elsif asset.class.respond_to?(:default_content_ds)
      Deprecation.warn(DownloadBehavior, "default_content_ds is deprecated and will be removed in hydra-head 10.0, use default_file_path instead")
      asset.attached_files[asset.class.default_content_ds]
    elsif asset.attached_files.key?(DownloadsController.default_file_path)
      asset.attached_files[DownloadsController.default_file_path]
    elsif asset.attached_files.key?(DownloadsController.default_content_dsid)
      Deprecation.warn(DownloadBehavior, "DownloadsController.default_content_dsid is deprecated and will be removed in hydra-head 10.0, use default_file_path instead")
      asset.attached_files[DownloadsController.default_content_dsid]
    end
  end
end

