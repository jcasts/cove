class Cove::Result

  def self.load_file cove_filepath
    Marshal.load(Zlib::Inflate.inflate(File.read(cove_filepath)))
  end


  attr_reader :coverage, :files


  ##
  # Create a new Cove::Result instance from a Coverage result hash.
  # The `file_blobs' argument may be specified to restrict the coverage results
  # to matching file paths.
  #
  #   Coverage.start
  #   # ... do stuff ... #
  #
  #   res = Cove::Results.new Coverage.result, ["app/**/*.rb", "lib/**/*.rb"]
  #   res.merge! Cove::Results.load("path/to/my_res_file")

  def initialize cov_hash={}, file_blobs=nil
    @coverage = {}
    @files    = {}
    @md5      = {}

    filepaths = file_blobs ?
                  file_blobs.map{|f| Dir[f] }.flatten :
                  cov_hash.keys

    filepaths.each do |filepath|
      filepath = File.expand_path(filepath)
      next unless File.file?(filepath) && cov_hash[filepath]

      add_file_coverage filepath, cov_hash[filepath], File.read(filepath)
    end
  end


  ##
  # Add or merge a coverage array for the specified filepath.

  def add_file_coverage filepath, cov_ary, file_contents
    new_md5 = Digest::MD5.hexdigest file_contents

    if !@md5[filepath]
      @coverage[filepath] = cov_ary
      @files[filepath]    = file_contents
      @md5[filepath]      = new_md5

    elsif @md5[filepath] == new_md5
      cov_add(filepath, cov_ary, file_contents)

    else
      cov_merge(filepath, cov_ary, file_contents)
      @files[filepath] = file_contents
      @md5[filepath]   = new_md5
    end
  end


  ##
  # Add a coverage array to the current on defined for `filepath'.

  def cov_add filepath, cov_ary
    @coverage[filepath] = add_cov_arrays(@coverage[filepath], cov_ary)
  end


  ##
  # Merge coverage contents.

  def cov_merge filepath, cov_ary, file_contents
    i = 0
    merged_cov_ary = []
    old_cov_ary    = @coverage[filepath]

    Cove::Diff.new(@files[filepath], file_contents).create_diff do |left, right|
      next_index = i + right.length

      if left == right
        partial = add_cov_arrays \
                    old_cov_ary[i...next_index],
                    cov_ary[i...next_index]

        merged_cov_ary.concat partial

      else
        merged_cov_ary.concat cov_ary[i...next_index]
      end

      i = next_index
    end

    @coverage[filepath] = merged_cov_ary
  end


  ##
  # Add two coverage arrays together.

  def add_cov_arrays ary1, ary2
    new_ary = []

    num = (ary1.length >= ary2.length) ? ary1.length : ary2.length

    num.times do |i|
      if ary1[i].nil? && ary2[i].nil?
        new_ary[i] = nil
      else
        new_ary[i] = ary1[i].to_i + ary2[i].to_i
      end
    end

    new_ary
  end


  ##
  # Merge results from another Cove::Result instance.
  # If files have changed between coverages, the different sections will
  # only have the coverage of the given cove_result argument.

  def merge cove_result
    raise ArgumentError, "Can't merge #{cove_result.class}" unless
      self.class === cove_result

    cove_result.each do |filepath, cov_ary|
      new_filepath = block_given? ? yield(filepath) : filepath
      add_file_coverage new_filepath, cov_ary, cove_result.files[filepath]
    end
  end


  ##
  # Write this Cove::Result instance to a file.

  def write filepath
    File.open(filepath, "w") do |file|
      file.write(Zlib::Deflate.deflate(Marshal.dump(self)))
    end
  end
end
