require 'sinatra/base'
require 'haml'
require 'json'
require 'base64'
require 'fileutils'

class Uki < Sinatra::Base
  def process_path(path, included = {})
    code = File.read(path)
    base = File.dirname(path)
    code.gsub(%r{include\s*\(\s*['"]([^"']+)["']\s*\)\s*;?}) {
      include_path = File.expand_path(File.join(base, $1))
      unless included[include_path]
        included[include_path] = true
        process_path(include_path, included)
      else
        ''
      end
    }
  end
  
  get %r{^/app/.*\.cjs$} do
    path = request.path.sub(/\.cjs$/, '.js')
    response.header['Content-type'] = 'application/x-javascript; charset=UTF-8'
    process_path(File.join(File.dirname(__FILE__), path))
  end
  
  get %r{^/app/.*} do
    path = request.path
    response.header['Content-type'] = 'image/png' if path.match(/\.png$/)
    File.read File.join(File.dirname(__FILE__), path)
  end
  
  post '/imageCutter' do
    data = JSON.load(params['json'])
    FileUtils.rm_r Dir.glob('tmp/*')
    data.each do |k, v|
      File.open(File.join('tmp', v[0]), 'w') { |f| 
        parts = v[1].split(',', 2)
        f.write(Base64.decode64(parts[1]))
      };
    end
    FileUtils.rm( %w(tmp.zip) ) rescue nil
    `zip tmp.zip tmp/*`
    response.header['Content-Type'] = 'application/x-zip-compressed'
    response.header['Content-Disposition'] = 'attachment; filename=tmp.zip'
    File.read('tmp.zip')
  end
  
  get %r{^/.*$} do
    response.header['Content-type'] = 'text/html; charset=UTF-8'
    haml request.path.sub(%r{^/}, '').to_sym
  end
  
  get '/' do
    haml :index
  end
end