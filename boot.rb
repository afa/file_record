def autold(path)
  $LOAD_PATH << path if File.directory?(path)
  files = Dir[File.join(path, '**/*.rb')].map do |f|
    f.delete_suffix('.rb').delete_prefix(path + '/').delete_prefix(path).split('/')
  end.sort_by(&:size)
  flist = files.inject([]) { |ar, i| ar << i.dup }
  classes = flist.map { |lst| lst.pop.split('_').map(&:capitalize).join }
  mods = flist.map do |ar|
    ar.map { |i| i.split('_').map(&:capitalize).join }
  end
  classes.each_with_index do |cl, idx|
    if mods[idx].empty?
      autoload(cl.to_sym, files[idx].join('/'))
      next
    end
    m = mods[idx].inject(Object) do |rez, md|
      unless rez.const_defined?(md)
        rez.const_set(md, Module.new)
      end
      rez.const_get(md)
    end
    m.autoload(cl.to_sym, files[idx].join('/'))
  end
end
autold('./lib')
Dir['./app/*'].each { |p| autold(p) }
